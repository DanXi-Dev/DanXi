import 'package:dio/dio.dart';

class DioUtils {
  // ignore: non_constant_identifier_names
  static get NON_REDIRECT_OPTION_WITH_FORM_TYPE {
    return Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) {
          return status < 400;
        });
  }

  static Future<Response> processRedirect(Dio dio, Response response) async {
    //Prevent the redirect being processed by HttpClient, with the 302 response caught manually.
    if (response.statusCode == 302 &&
        response.headers['location'] != null &&
        response.headers['location'].length > 0) {
      return processRedirect(
          dio,
          await dio.get(response.headers['location'][0],
              options: Options(
                  contentType: Headers.formUrlEncodedContentType,
                  followRedirects: false,
                  validateStatus: (status) {
                    return status < 400;
                  })));
    } else {
      return response;
    }
  }
}
