import 'dart:convert';

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class WebvpnRequestException implements Exception {
  final String? message;

  WebvpnRequestException([this.message]);

  @override
  String toString() {
    if (message == null) return "Login to WebVPN has failed";
    return "Login to WebVPN has failed: $message";
  }
}

/// An interceptor that intercepts requests and routes them through WebVPN if needed.
///
/// # Order of interceptors
/// This interceptor should be added BEFORE [RedirectInterceptor] but AFTER any other interceptors.
class WebVPNInterceptor extends Interceptor {
  static final _hostCache = <String, String>{};
  static const String DIRECT_CONNECT_TEST_URL = "https://forum.fduhole.com";
  static const String EXTRA_ROUTE_TYPE = "webvpn_route_type";
  static const String EXTRA_ORIGINAL_URL = "webvpn_original_url";
  static const String WEBVPN_HOST = "webvpn.fudan.edu.cn";
  static final Uri WEBVPN_LOGIN_URL =
      Uri.parse("https://$WEBVPN_HOST/login?cas_login=true");
  static const String WEBVPN_REDIRECTED_TO_LOGIN_PREFIX = "https://$WEBVPN_HOST/login";
  static const String _WRDVPN_VPN_IS_THE_BEST = "wrdvpnisthebest!";

  static Future<bool>? tryDirectSession;
  static bool? _canConnectDirectly;

  /// Try to translate a URL to its WebVPN equivalent. Return `null` if the URL is not supported by WebVPN.
  static String? tryTranslateUrlToWebVPN(String url) {
    Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final uriScheme = uri.scheme.isEmpty ? "http" : uri.scheme;
    if (uriScheme != "http" && uriScheme != "https") {
      return null;
    }

    final scheme = uri.scheme;
    final host = uri.host;
    final formattedHost = host.contains(":") ? "[$host]" : host;
    final key = _WRDVPN_VPN_IS_THE_BEST;
    final iv = _WRDVPN_VPN_IS_THE_BEST;
    final encodedHost = scheme == "connection"
        ? formattedHost
        : _hostCache.putIfAbsent(host, () => _encrypt(formattedHost, key, iv));

    final port = uri.port;
    final componentsSb = StringBuffer(uri.path);
    if (uri.hasQuery) componentsSb..write("?")..write(uri.query);
    if (uri.hasFragment) componentsSb..write("#")..write(uri.fragment);
    final components = componentsSb.toString();
    final segment = uri.hasPort ? "$scheme-$port" : scheme;

    final encodedPath =
        "https://$WEBVPN_HOST/$segment/$encodedHost$components";
    return encodedPath;
  }

  static final aesEngine = AESEngine();
  static String _encrypt(String text, String keyText, String ivText) {
    final originalLength = text.length;
    final paddedText = _padText(text);

    final textBytes = utf8.encode(paddedText);
    final keyBytes = utf8.encode(keyText);
    final ivBytes = utf8.encode(ivText);

    final cipher = CFBBlockCipher(aesEngine, 16);
    cipher.init(true, ParametersWithIV(KeyParameter(keyBytes), ivBytes));

    final encryptedBytes = Uint8List(textBytes.lengthInBytes);
    var offset = 0;
    while (offset < encryptedBytes.lengthInBytes) {
      offset += cipher.processBlock(textBytes, offset, encryptedBytes, offset);
    }

    final ivHex = utf8.encode(ivText).toHexString();
    final encryptedHex = encryptedBytes.toHexString();
    return ivHex + encryptedHex.substring(0, 2 * originalLength);
  }

  static String _padText(String text, {String encodingName = "utf8"}) {
    final blockSize = encodingName == "utf8" ? 16 : 32;
    // Caveats: the length of String might not be the length of UTF-8 bytes. But
    // the JS method in WebVPN is indeed written this way.
    final remainder = text.length % blockSize;
    return remainder == 0 ? text : text + "0" * (blockSize - remainder);
  }

  /// Check if we are able to connect to the service directly (without WebVPN).
  /// This method uses a low-timeout dio to reduce wait time.
  static Future<bool> tryDirect() async {
    final dioOptions = BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
        sendTimeout: const Duration(seconds: 1));
    // A low-timeout dio
    Dio fastDio = DioUtils.newDioWithProxy(dioOptions);

    try {
      await fastDio.get(DIRECT_CONNECT_TEST_URL);
      // Request succeeds
      return true;
    } on DioException catch (e) {
      // Under these circumstances, at least we can find the server successfully, so we can assume that direct request does work.
      if (e.type == DioExceptionType.badResponse ||
          e.type == DioExceptionType.badCertificate) {
        return true;
      }

      // We cannot even connect to the server
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint(
            "Direct connection timeout, trying to connect through proxy: $e");
        return false;
      }

      // Misc errors, not related to connectivity to danta server, just leave a log and return `false`
      debugPrint("Direct connection failed due to an unexpected reason: $e");
      return false;
    } catch (e) {
      debugPrint("Unknown problem when trying direct access: $e");
      return false;
    }
  }

  /// Priorly validate the response to see if it indicates a successful request.
  ///
  /// Throws exception if the response is invalid.
  Response<dynamic> validateResponse(Response<dynamic> response) {
    if (response.realUri.toString().startsWith(WEBVPN_REDIRECTED_TO_LOGIN_PREFIX)) {
      throw WebvpnRequestException(
          "Request through WebVPN failed: not logged in");
    }
    if (response.requestOptions.responseType == ResponseType.json) {
      if (response.data is! Map && response.data is! List) {
        // If the response is not a JSON object or array, try to decode it
        jsonDecode(response.data.toString());
      }
    }
    return response;
  }

  /// Handle a request through WebVPN
  Future<void> handleWebVPNRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final translatedUrl = tryTranslateUrlToWebVPN(options.path);
    options.path = translatedUrl ?? options.path;
    options.extra[EXTRA_ROUTE_TYPE] =
        translatedUrl != null ? "webvpn_proxied" : "webvpn_direct";

    try {
      debugPrint(
          "Requesting through WebVPN: ${options.method} ${options.path}");
      final proxiedResponse = await FudanSession.request(
        options, validateResponse,
        manualLoginUrl: WEBVPN_LOGIN_URL,
        manualLoginMethod: "GET",
      );
      return handler.resolve(proxiedResponse, true);
    } on DioException catch (e) {
      return handler.reject(e, true);
    }
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.extra[EXTRA_ORIGINAL_URL] = options.path;
    // Try with direct connect if we haven't even tried
    if (_canConnectDirectly == null) {
      // The first request submits the job to evaluate if direct connection works and waits for result.
      // Other concurrent requests just simply wait for the result.
      tryDirectSession ??= tryDirect();
      _canConnectDirectly = await tryDirectSession;
    }

    if (_canConnectDirectly! || !SettingsProvider.getInstance().useWebvpn) {
      // If we can connect through direct request, or WebVPN is not enabled in settings, we should try to request directly.
      options.extra[EXTRA_ROUTE_TYPE] = "direct";
      return handler.next(options);
    }

    // Turn to the proxy
    await handleWebVPNRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isNotRouted = err.requestOptions.extra[EXTRA_ROUTE_TYPE] == "direct";
    final isConnectionError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError;
    if (isNotRouted && isConnectionError) {
      _canConnectDirectly = false;
      // FIXME: should retry the request through WebVPN here. But [onError] cannot be async.
      debugPrint(
          "Direct connection timeout, trying to connect through proxy next time: $err");
    }
    return handler.next(err);
  }
}

class WebvpnProxy {
  static Future<Response<T>> requestWithProxy<T>(
      Dio dio, RequestOptions options) async {
    return await dio.fetch<T>(options);
  }
}
