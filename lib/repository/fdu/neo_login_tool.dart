import 'dart:async';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/util/condition_variable.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/dio_log.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:encrypt/encrypt.dart';
import 'package:mutex/mutex.dart';
import 'package:pointycastle/asymmetric/api.dart';

/// Supported Fudan authentication systems.
enum FudanLoginType {
  /// The new Fudan authentication system using id.fudan.edu.cn
  Neo,

  /// The legacy Fudan authentication system using uis.fudan.edu.cn
  UISLegacy,
}

/// A session manager that provides authenticated HTTP requests to Fudan services.
///
/// This class handles:
/// 1. Automatic authentication when services require login
/// 2. Cookie management across requests to maintain session state
/// 3. Request queuing to prevent concurrent login attempts
///
/// ## Usage
/// ```dart
/// final response = await FudanSession.request(
///   RequestOptions(path: "https://service.fudan.edu.cn/api/data"),
///   (response) => MyModel.fromJson(response.data),
/// );
/// ```
class FudanSession {
  /// Lazily-initialized HTTP client with custom configuration.
  static Dio? _dio;

  /// Shared cookie jar to maintain authentication sessions across all requests.
  static final IndependentCookieJar _sessionCookieJar = IndependentCookieJar();

  /// Login queues for each authentication type to coordinate concurrent requests.
  /// Ensures only one login operation runs at a time per authentication method.
  static final Map<FudanLoginType, LoginQueue> _authenticationQueues =
      FudanLoginType.values
          .asMap()
          .map((_, type) => MapEntry(type, LoginQueue()));

  static Dio get dio {
    if (_dio == null) {
      _dio = DioUtils.newDioWithProxy(BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        // Disable Dio's built-in redirect handling as it has issues
        // RedirectInterceptor provides proper redirect tracking
        followRedirects: false,
        // Allow 3xx status codes to avoid exceptions, since we handle redirects manually
        validateStatus: (status) => status != null && status < 400,
      ));

      // 1. Request throttling (must be first)
      _dio!.interceptors.add(LimitedQueuedInterceptor.getInstance());
      // 2. User agent spoofing to bypass restrictions
      _dio!.interceptors.add(UserAgentInterceptor(important: false));
      // 3. Cookie management for session persistence
      _dio!.interceptors.add(CookieManager(_sessionCookieJar));
      // 4. Dio Logger for debugging
      _dio!.interceptors.add(DioLogInterceptor());
      // 5. Custom redirect handling (must be last)
      _dio!.interceptors.add(RedirectInterceptor(() => _dio!));
    }
    return _dio!;
  }

  /// Executes an authenticated request to a Fudan service with automatic login retry.
  ///
  /// This method:
  /// 1. Executes the request using the configured HTTP client
  /// 2. Detects if authentication is required based on response characteristics
  /// 3. Automatically performs login and retries the request if needed
  ///
  /// [req] - The HTTP request to execute. TODO: should be Options instead of RequestOptions
  /// [validateAndParse] - Function to validate and parse the successful response
  /// [manualLoginUrl] - Override login URL for services that don't auto-redirect to auth
  /// [manualLoginMethod] - HTTP method to use for requesting [manualLoginUrl] (defaults to req.method)
  /// [type] - Authentication system to use
  /// [isFatalError] - Optional function to identify errors that shouldn't trigger login
  /// [info] - User credentials (defaults to global StateProvider.personInfo)
  ///
  /// Returns the parsed result from [validateAndParse]
  /// Throws [ArgumentError] if no valid PersonInfo is available
  static Future<T> request<T>(RequestOptions req,
      FutureOr<T> Function(Response<dynamic>) validateAndParse,
      {Uri? manualLoginUrl,
      String? manualLoginMethod,
      FudanLoginType type = FudanLoginType.Neo,
      bool Function(dynamic error)? isFatalError,
      PersonInfo? info}) async {
    final personInfo = info ?? StateProvider.personInfo.value;
    if (personInfo == null) {
      throw ArgumentError("PersonInfo is required for authentication");
    }

    // Ensure the request options are set to not follow redirects automatically too.
    final originalValidateStatus = req.validateStatus;
    req
      ..followRedirects = false
      ..validateStatus = (status) => originalValidateStatus(status) || (status != null && status < 400);

    final effectiveServiceUrl = manualLoginUrl ?? req.uri;
    final effectiveLoginMethod = manualLoginMethod ?? req.method;

    switch (type) {
      case FudanLoginType.Neo:

        /// Determines if a response indicates that authentication is required.
        ///
        /// This is an ad-hoc heuristic: if the response was redirected to the authentication
        /// server (id.fudan.edu.cn), we can be confident that login is needed.
        /// However, the absence of a redirect doesn't guarantee that authentication is not needed.
        bool isNeoAuthenticationRequired(Response<dynamic> response) =>
            response.realUri.host == FudanAuthenticationAPIV2.idHost &&
            response.redirectCount > 0;

        return _authenticationQueues[type]!.runNormalRequest(
          () async {
            // Work around Dio bug: FormData objects can only be used once
            final requestData = req.data;
            if (requestData is FormData) {
              req.data = requestData.clone();
            }

            final response = await dio.fetch(req);
            if (isNeoAuthenticationRequired(response)) {
              throw Exception(
                  "Authentication required for request: ${response.realUri}");
            }
            return Future.sync(() => validateAndParse(response));
          },
          () async {
            await FudanAuthenticationAPIV2.authenticate(
                personInfo, effectiveServiceUrl, effectiveLoginMethod);
          },
          isFatalError: isFatalError,
        );
      case FudanLoginType.UISLegacy:
        bool isLegacyAuthenticationRequired(Response<dynamic> response) =>
            response.realUri.host == FudanAuthenticationAPIV1.uisHost &&
            response.redirectCount > 0;

        bool isLegacyFatalError(dynamic e) =>
            e is AuthenticationV1FailedException;
        final effectiveIsFatalError = (isFatalError == null)
            ? isLegacyFatalError
            : (dynamic e) => isFatalError(e) || isLegacyFatalError(e);

        return _authenticationQueues[type]!.runNormalRequest(
          () async {
            // Work around Dio bug: FormData objects can only be used once
            final requestData = req.data;
            if (requestData is FormData) {
              req.data = requestData.clone();
            }

            final response = await dio.fetch(req);
            if (isLegacyAuthenticationRequired(response)) {
              throw Exception(
                  "Authentication required for request: ${response.realUri}");
            }
            return Future.sync(() => validateAndParse(response));
          },
          () async {
            await FudanAuthenticationAPIV1.authenticate(
                personInfo, effectiveServiceUrl, effectiveLoginMethod);
          },
          isFatalError: effectiveIsFatalError,
        );
    }
  }

  static Future<void> clearSession() async {
    // Clear cookies to reset the session
    await _sessionCookieJar.deleteAll();
    // Clear the Dio instance to reset interceptors and state
    _dio = null;
  }
}

class FudanAuthenticationAPIV2 {
  static final String idHost = 'id.fudan.edu.cn';

  static Future<Response<dynamic>> authenticate(
      PersonInfo info, Uri serviceUrl, String? serviceRequestMethod) async {
    final Response<dynamic> firstResponse = await FudanSession.dio
        .requestUri(serviceUrl, options: Options(method: serviceRequestMethod));
    // already redirected to the target service, return the response
    if (firstResponse.realUri.host == serviceUrl.host) {
      return firstResponse;
    }

    final Uri redirectedUrl = firstResponse.realUri;
    if (redirectedUrl.host != idHost) {
      // The response must be a redirect to the id.fudan.edu.cn
      throw Exception('Unexpected redirect to $redirectedUrl');
    }

    try {
      // check if already authenticated by try to call [_retrieveUrlWithTicket]
      final document = BeautifulSoup(firstResponse.data.toString());
      final targetUrl = _retrieveUrlWithTicket(document);
      return await FudanSession.dio.getUri(targetUrl);
    } catch (_) {}

    // If not authenticated, we need to login
    final params = await _getAuthParams(redirectedUrl);
    final publicKey = await _getPublicKey();
    final loginToken =
        await _login(params, publicKey, info.id!, info.password!);
    final document = await _postToken(loginToken);
    final targetUrl = _retrieveUrlWithTicket(document);

    // Now we have the target URL with the ticket, we can redirect to it
    try {
      return await FudanSession.dio.getUri(targetUrl);
    } on DioException catch (e) {
      if (e.response?.realUri.host != serviceUrl.host) {
        // If the final redirect is not to the target service, rethrow
        rethrow;
      }
      if (e.type != DioExceptionType.badResponse) {
        // If the error is not due to a bad response (e.g. 404), rethrow
        rethrow;
      }
      if ((serviceRequestMethod ?? "GET") == "GET") {
        // If the original request is a GET request, we should not get a bad response
        // from the target service, rethrow
        rethrow;
      }
      // else, we are getting a bad response from the target service,
      // which may indicate wrong method (GET/POST), which is not a problem of authentication.
      // Ignore and suppose the login is successful.
      return e.response!;
    }

  }

  static Uri _retrieveUrlWithTicket(BeautifulSoup idPageDocument) {
    final submitUrl = Uri.parse(
        idPageDocument.find("*", id: "logon")!.getAttrValue("action")!);
    final ticket =
        idPageDocument.find("*", id: "ticket")!.getAttrValue("value")!;

    final mutableQueryMap = Map.of(submitUrl.queryParameters)
      ..["ticket"] = ticket;

    return submitUrl.replace(queryParameters: mutableQueryMap);
  }

  static Future<RSAPublicKey> _getPublicKey() async {
    final Response<Map<String, dynamic>> response =
        await FudanSession.dio.post("https://$idHost/idp/authn/getJsPublicKey");
    final encodedKey = response.data!["data"] as String;
    final pcks8Key =
        "-----BEGIN PUBLIC KEY-----\n$encodedKey\n-----END PUBLIC KEY-----";
    return RSAKeyParser().parse(pcks8Key) as RSAPublicKey;
  }

  static Future<AuthenticationParameters> _getAuthParams(Uri idUrl) async {
    // 1. parse lck and entityId from the idUrl
    // concat fragment (#...) with a new URL to parse it as query parameters
    final Uri tmpUrlForParsing = Uri.parse("https://$idHost/${idUrl.fragment}");
    final lck = tmpUrlForParsing.queryParameters["lck"]!;
    final entityId = tmpUrlForParsing.queryParameters["entityId"]!;

    // 2. get chainCode from the server
    final Response<Map<String, dynamic>> chainCodeResponse =
        await FudanSession.dio.post(
      "https://$idHost/idp/authn/queryAuthMethods",
      data: {
        "lck": lck,
        "entityId": entityId,
      },
    );
    final methods = chainCodeResponse.data!["data"] as List<dynamic>;
    final userAndPwdMethod =
        methods.firstWhere((method) => method["moduleCode"] == "userAndPwd")
            as Map<String, dynamic>;
    final authChainCode = userAndPwdMethod["authChainCode"] as String;

    return AuthenticationParameters(lck, entityId, authChainCode);
  }

  static Future<String> _login(AuthenticationParameters params,
      RSAPublicKey publicKey, String username, String password) async {
    final encrypter =
        Encrypter(RSA(publicKey: publicKey, encoding: RSAEncoding.PKCS1));
    final encryptedPassword = encrypter.encrypt(password).base64;
    final Response<Map<String, dynamic>> response = await FudanSession.dio.post(
      "https://$idHost/idp/authn/authExecute",
      data: {
        "authModuleCode": "userAndPwd",
        "authChainCode": params.chainCode,
        "entityId": params.entityId,
        "requestType": "chain_type",
        "lck": params.lck,
        "authPara": {
          "loginName": username,
          "password": encryptedPassword,
          "verifyCode": "",
        }
      },
    );

    return response.data!["loginToken"] as String;
  }

  static Future<BeautifulSoup> _postToken(String loginToken) async {
    final Response<dynamic> response = await FudanSession.dio.post(
      "https://$idHost/idp/authCenter/authnEngine",
      data: {"loginToken": loginToken},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    return BeautifulSoup(response.data.toString());
  }
}

class AuthenticationParameters {
  final String lck;
  final String entityId;
  final String chainCode;

  AuthenticationParameters(this.lck, this.entityId, this.chainCode);
}

class FudanAuthenticationAPIV1 {
  static const String uisHost = 'uis.fudan.edu.cn';

  /// Error patterns from UIS.
  static const String CAPTCHA_CODE_NEEDED = "请输入验证码";
  static const String CREDENTIALS_INVALID = "密码有误";
  static const String WEAK_PASSWORD = "弱密码提示";
  static const String UNDER_MAINTENANCE = "网络维护中 | Under Maintenance";

  static Future<Response<dynamic>> authenticate(
      PersonInfo info, Uri serviceUrl, String? serviceRequestMethod) async {
    final Response<String> firstResponse = await FudanSession.dio
        .requestUri<String>(serviceUrl,
            options: Options(method: serviceRequestMethod));
    // already redirected to the target service, return the response
    if (firstResponse.realUri.host == serviceUrl.host &&
        serviceUrl.host != uisHost) {
      return firstResponse;
    }

    // else start authentication
    final Uri redirectedUrl = firstResponse.realUri;
    if (redirectedUrl.host != uisHost) {
      // The response must be arrive at uis.fudan.edu.cn
      throw Exception('Unexpected redirect to $redirectedUrl');
    }

    final postData = _getAuthData(info, firstResponse.data!);
    final rep = await FudanSession.dio.postUri<String>(redirectedUrl,
        data: postData.encodeMap(),
        options: Options(contentType: Headers.formUrlEncodedContentType));
    final responseHtml = rep.data!;
    if (responseHtml.contains(CREDENTIALS_INVALID)) {
      throw CredentialsInvalidException();
    } else if (responseHtml.contains(CAPTCHA_CODE_NEEDED)) {
      // Notify [main.dart] to show up a dialog to guide users to log in manually.
      CaptchaNeededException().fire();
      throw CaptchaNeededException();
    } else if (responseHtml.contains(UNDER_MAINTENANCE)) {
      throw NetworkMaintenanceException();
    } else if (responseHtml.contains(WEAK_PASSWORD)) {
      throw WeakPasswordException();
    }

    return rep;
  }

  static Map<String?, String?> _getAuthData(PersonInfo info, String uisHtml) {
    Map<String?, String?> data = {};
    for (final element in BeautifulSoup(uisHtml).findAll("input")) {
      if (element.attributes['type'] != "button") {
        data[element.attributes['name']] = element.attributes['value'];
      }
    }
    data
      ..['username'] = info.id
      ..["password"] = info.password;
    return data;
  }
}

/// Several exceptions that can be thrown during authentication V1.
class AuthenticationV1FailedException implements Exception {}

class CaptchaNeededException implements AuthenticationV1FailedException {}

class CredentialsInvalidException implements AuthenticationV1FailedException {}

class NetworkMaintenanceException implements AuthenticationV1FailedException {}

class WeakPasswordException implements AuthenticationV1FailedException {}

/// A specialized queue that manages login requests to prevent concurrent authentication attempts.
///
/// This class ensures that:
/// 1. Only one login operation runs at a time across all threads
/// 2. Failed requests are automatically retried with login, but with batch-based retry limits
/// 3. Multiple requests needing login are efficiently batched together
///
/// ## Batch Concept
/// A "batch" consists of normal requests that started within a time window and all need login.
/// Specifically, for a login request B triggered by normal request A, other normal requests
/// that satisfy: startTime(other) < startTime(B) AND startTime(other) > startTime(lastLogin)
/// are considered in the same batch as A.
class LoginQueue {
  /// Protects all instance variables to ensure thread safety.
  final Mutex _mutex = Mutex();

  /// Whether a login operation is currently in progress.
  bool _isCurrentlyLoggingIn = false;

  /// Number of login attempts made within the current batch.
  /// Reset to 0 when a new batch starts or when login succeeds.
  int _loginAttemptsInCurrentBatch = 0;

  /// State and timestamp of the most recent login attempt.
  _LastLoginState _mostRecentLoginState = _LastLoginNever();

  /// Notifies waiting threads when a login operation completes (success or failure).
  late final ConditionVariable _loginCompletedNotifier =
      ConditionVariable(_mutex);

  /// Monotonically increasing timer to generate timestamps immune to system time changes.
  /// Used to determine request ordering and batch boundaries.
  static final Stopwatch _globalTimer = Stopwatch()..start();

  /// Executes a normal request with automatic login retry on authentication failure.
  ///
  /// This method:
  /// 1. Waits for any ongoing login to complete
  /// 2. Attempts the requested action
  /// 3. If the action fails due to authentication, triggers a login and retries once
  ///
  /// [action] - The main request logic to execute
  /// [loginLogic] - The login procedure to run if authentication is needed
  /// [hasBeenRetried] - Flag to prevent infinite retry loops (for internal use)
  /// [actionStartTime] - Override for the request start timestamp (for internal use)
  /// [isFatalError] - Optional function to identify errors that should not trigger login
  Future<T> runNormalRequest<T>(
      Future<T> Function() action, Future<void> Function() loginLogic,
      {bool hasBeenRetried = false,
      int? actionStartTime,
      bool Function(dynamic error)? isFatalError}) async {
    // Wait for any currently running login to complete before proceeding
    await _mutex.protect(() async {
      while (_isCurrentlyLoggingIn) {
        await _loginCompletedNotifier.wait();
      }
    });

    final requestStartTime =
        actionStartTime ?? _globalTimer.elapsedMicroseconds;

    try {
      // Attempt to execute the main action
      return await action();
    } catch (e) {
      // Check if this is a fatal error that should not trigger login retry
      if (isFatalError != null && isFatalError(e)) {
        rethrow;
      }

      // If we've already retried once, don't retry again to avoid infinite loops
      if (hasBeenRetried) {
        rethrow;
      }

      // The action failed, likely due to authentication. Try to login and retry.
      final loginSucceeded =
          await _triggerAndAwaitLogin(loginLogic, requestStartTime);

      if (loginSucceeded) {
        // Login succeeded, retry the original action once
        return await runNormalRequest(action, loginLogic,
            hasBeenRetried: true, actionStartTime: requestStartTime);
      } else {
        // Login failed, propagate the login error if available
        if (_mostRecentLoginState
            case _LastLoginFailure(
              error: final loginError,
              stackTrace: final st
            )) {
          Error.throwWithStackTrace(loginError, st);
        } else {
          // Login state is unexpected (Never or Success), rethrow the original error
          rethrow;
        }
      }
    }
  }

  /// Manages the login process with proper synchronization and batch-based retry limits.
  ///
  /// This method handles:
  /// 1. Waiting for ongoing logins to complete
  /// 2. Determining if a new batch has started (resetting retry counter)
  /// 3. Enforcing the 3-attempt limit per batch
  /// 4. Coordinating the actual login execution
  /// 5. Notifying all waiting threads when login completes
  ///
  /// [loginLogic] - The actual login implementation to execute
  /// [requestStartTime] - Timestamp of the request that triggered this login
  ///
  /// Returns true if login succeeded, false if retry limit exceeded or login failed
  Future<bool> _triggerAndAwaitLogin(
      Future<void> Function() loginLogic, int requestStartTime) async {
    await _mutex.acquire();

    // Wait for any ongoing login to finish, but keep checking if we need to adjust batch counts
    while (_isCurrentlyLoggingIn) {
      await _loginCompletedNotifier.wait();

      // If another thread's login succeeded, we can piggyback on it
      if (_mostRecentLoginState case _LastLoginSuccess()) {
        _mutex.release();
        return true;
      }

      // Check if this request started after the most recent login, indicating a new batch
      if (requestStartTime > _mostRecentLoginState.startTime) {
        _loginAttemptsInCurrentBatch =
            0; // Reset attempts counter for the new batch
      }
    }

    // Check if we've exceeded the retry limit for this batch
    if (_loginAttemptsInCurrentBatch >= 3) {
      _mutex.release();
      return false; // Too many failed attempts, give up
    }

    // Initiate login: mark as in-progress and increment attempt counter
    _isCurrentlyLoggingIn = true;
    _loginAttemptsInCurrentBatch++;
    final loginStartTime = _globalTimer.elapsedMicroseconds;
    _mutex.release();

    // Execute the actual login logic outside the mutex
    _LastLoginState loginResult;
    try {
      await loginLogic();
      loginResult = _LastLoginSuccess(loginStartTime);
    } catch (error, stackTrace) {
      loginResult = _LastLoginFailure(error, stackTrace, loginStartTime);
    }

    // Update state and notify all waiting threads
    await _mutex.protect(() async {
      _isCurrentlyLoggingIn = false;
      _mostRecentLoginState = loginResult;

      // If login succeeded, reset the batch attempt counter
      if (loginResult case _LastLoginSuccess()) {
        _loginAttemptsInCurrentBatch = 0;
      }

      // Wake up all threads waiting for this login to complete
      await _loginCompletedNotifier.broadcast();
    });

    return loginResult is _LastLoginSuccess;
  }
}

/// Represents the state and result of the most recent login attempt.
/// Used to coordinate between multiple threads and implement batch-based retry logic.
sealed class _LastLoginState {
  /// Timestamp when this login state was recorded (from the global monotonic timer).
  /// Used to determine batch boundaries and request ordering.
  final int startTime;

  _LastLoginState(this.startTime);
}

/// Initial state indicating no login has ever been attempted.
/// This state is never returned to once the first login attempt is made.
class _LastLoginNever extends _LastLoginState {
  _LastLoginNever() : super(0); // Use timestamp 0 as the initial placeholder
}

/// Indicates that the most recent login attempt completed successfully.
/// When other threads see this state, they can proceed without initiating their own login.
class _LastLoginSuccess extends _LastLoginState {
  _LastLoginSuccess(super.startTime);
}

/// Indicates that the most recent login attempt failed with an error.
/// Contains the error details for propagation to threads that triggered this login.
class _LastLoginFailure extends _LastLoginState {
  /// The exception that caused the login to fail.
  final dynamic error;

  /// Stack trace associated with the login failure.
  final StackTrace stackTrace;

  _LastLoginFailure(this.error, this.stackTrace, super.startTime);
}
