import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dan_xi/repository/inpersistent_cookie_manager.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dio/dio.dart';

class UISLoginTool {
  static Future<Response> loginUIS(Dio dio, String serviceUrl,
      NonpersistentCookieJar jar, PersonInfo info) async {
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
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    return await DioUtils.processRedirect(dio, res);
  }
}
