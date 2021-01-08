import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:http/http.dart';

import '../person.dart';
import 'uis_login_tool.dart';

class QRCodeRepository {
  Dio _dio = Dio();
  DefaultCookieJar _cookieJar = DefaultCookieJar();
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fworkflow1.fudan.edu.cn%2Fsite%2Flogin%2Fcas-login%3Fredirect_url%3Dhttps%253A%252F%252Fworkflow1.fudan.edu.cn%252Fopen%252Fconnection%252Findex%253Fapp_id%253Dc5gI0Ro%2526state%253D%2526redirect_url%253Dhttps%253A%252F%252Fecard.fudan.edu.cn%252Fepay%252Fwxpage%252Ffudan%252Fzfm%252Fqrcode%253Furl%253D0";
  static const String QR_URL =
      "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode";

  QRCodeRepository._() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final _instance = QRCodeRepository._();

  factory QRCodeRepository.getInstance() => _instance;

  Future<String> getQRCode(PersonInfo info, {int retryTimes = 5}) async {
    for (int i = 0; i < retryTimes; i++) {
      await UISLoginTool.loginUIS(_dio, LOGIN_URL, _cookieJar, info);
      var res = await _dio.get(QR_URL);
      var soup = Beautifulsoup(res.data.toString());
      try {
        return soup.find(id: "#myText").attributes['value'];
        //ignore it in the case of network errors.
      } catch (ignored) {}
    }
    return null;
  }
}
