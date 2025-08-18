import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class FudanSession {
  static Dio? _dio;
  static final IndependentCookieJar _cookieJar = IndependentCookieJar();

  static Dio get dio {
    if (_dio == null) {
      _dio = DioUtils.newDioWithProxy(BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        // Disable Dio's built-in redirect handling by [http] package
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ));
      _dio!.interceptors.add(LimitedQueuedInterceptor.getInstance());
      // Use custom user agent to bypass restrictions
      _dio!.interceptors.add(UserAgentInterceptor());
      _dio!.interceptors.add(CookieManager(_cookieJar));
      _dio!.interceptors.add(RedirectInterceptor(() => _dio!));
    }
    return _dio!;
  }
}

class FudanAuthenticationAPIV2 {
  static final String idHost = 'id.fudan.edu.cn';

  static Future<Response<dynamic>> authenticate(
      PersonInfo info, Uri serviceUrl) async {
    final Response<dynamic> firstResponse =
        await FudanSession.dio.getUri(serviceUrl);
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
    return await FudanSession.dio.getUri(targetUrl);
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
