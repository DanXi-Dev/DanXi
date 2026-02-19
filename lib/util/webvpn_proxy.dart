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
  static final Map<String, String> _vpnPrefix = {
    "www.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421e7e056d221347d5871048ce29b5a2e",
    "auth.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38",
    "danke.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73",
    "forum.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f6f853892a7e6e546b0086a09d1b203a46",
    "image.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f9fa409b227e6e546b0086a09d1b203ab8",
    "yjsxk.fudan.edu.cn":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421e9fd52842c7e6e457a0987e29d51367bba7b",
    "10.64.130.6":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421a1a70fca737e39032e46df",
  };
  static const String DIRECT_CONNECT_TEST_URL = "https://forum.fduhole.com";
  static const String EXTRA_ROUTE_TYPE = "webvpn_route_type";
  static const String EXTRA_ORIGINAL_URL = "webvpn_original_url";
  static const String WEBVPN_HOST = "webvpn.fudan.edu.cn";
  static final Uri WEBVPN_LOGIN_URL =
      Uri.parse("https://$WEBVPN_HOST/login?cas_login=true");
  static const String WEBVPN_REDIRECTED_TO_LOGIN_PREFIX = "https://$WEBVPN_HOST/login";

  static Future<bool>? tryDirectSession;
  static bool? _canConnectDirectly;

  /// Try to translate a URL to its WebVPN equivalent. Return `null` if the URL is not supported by WebVPN.
  static String? tryTranslateUrlToWebVPN(String url) {
    Uri? u = Uri.tryParse(url);
    if (u == null) {
      return null;
    }

    final uriScheme = u.scheme.isEmpty ? "http" : u.scheme;
    if (uriScheme != "http" && uriScheme != "https") {
      return null;
    }

    final encodedPath = _encodeUrlToPath(uriScheme, url);
    return "https://$WEBVPN_HOST$encodedPath";
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

  static const String _WRDVPN_KEY = "wrdvpnisthebest!";
  static const String _WRDVPN_IV = "wrdvpnisthebest!";
  static final _protocolRegex = RegExp(r"^https?://");
  static final _ipv6Regex = RegExp(r"\[[0-9a-fA-F:]+?\]");

  static String _encodeUrlToPath(
    String protocol,
    String search, {
    String key = _WRDVPN_KEY,
    String iv = _WRDVPN_IV,
  }) {
    final resourcePath = search.replaceFirst(_protocolRegex, "");
    final ipv6Match = _ipv6Regex.firstMatch(resourcePath);
    final ipv6 = ipv6Match?.group(0) ?? "";

    final remainingAfterIpv6 = resourcePath.substring(ipv6.length);
    final List<String> parts = remainingAfterIpv6.split("?")[0].split(":");
    final port = parts.length > 1 ? parts[1].split("/")[0] : "";

    final hostAndPath = port.isEmpty
        ? remainingAfterIpv6
        : resourcePath.replaceFirst(":$port", "", ipv6.length);
    final String encoded;
    if (protocol == "connection") {
      encoded = ipv6.isEmpty ? hostAndPath : ipv6 + hostAndPath;
    } else {
      final slashIndex = hostAndPath.indexOf("/");
      if (slashIndex == -1) {
        final host = ipv6.isEmpty ? hostAndPath : ipv6;
        encoded = _encrypt(host, key, iv);
      } else {
        final host = ipv6.isEmpty ? hostAndPath.substring(0, slashIndex) : ipv6;
        final path = hostAndPath.substring(slashIndex);
        final encrypted = _encrypt(host, key, iv);
        encoded = encrypted + path;
      }
    }

    return port.isEmpty ? "/$protocol/$encoded" : "/$protocol-$port/$encoded";
  }

  static String _encrypt(String text, String keyText, String ivText) {
    final originalLength = text.length;
    final paddedText = _padText(text);

    final textBytes = utf8.encode(paddedText);
    final keyBytes = utf8.encode(keyText);
    final ivBytes = utf8.encode(ivText);

    final engine = AESEngine();
    final cipher = CFBBlockCipher(engine, 16);
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
}

class WebvpnProxy {
  static Future<Response<T>> requestWithProxy<T>(
      Dio dio, RequestOptions options) async {
    return await dio.fetch<T>(options);
  }
}
