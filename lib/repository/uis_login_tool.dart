import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dan_xi/person.dart';
import 'package:dio/dio.dart';

class UISLoginTool {
  static Future<Response> loginUIS(
      Dio dio, String serviceUrl, DefaultCookieJar jar, PersonInfo info) async {
    jar.deleteAll();
    var data = {};
    var res = await dio.get(serviceUrl);
    Beautifulsoup(res.data.toString()).find_all("input").forEach((element) {
      if (element.attributes['type'] != "button") {
        data[element.attributes['name']] = element.attributes['value'];
      }
    });
    data['username'] = info.id;
    data["password"] = info.password;
    res = await dio.post(serviceUrl,
        data: data.entries.map((p) => '${p.key}=${p.value}').join('&'),
        options: Options(
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false,
            validateStatus: (status) {
              return status < 400;
            }));
    return await DioUtils.processRedirect(dio, res);
  }
}
