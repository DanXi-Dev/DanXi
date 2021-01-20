import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'inpersistent_cookie_manager.dart';

class QRCodeRepository {
  Dio _dio = Dio();
  NonpersistentCookieJar _cookieJar = NonpersistentCookieJar();
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fworkflow1.fudan.edu.cn%2Fsite%2Flogin%2Fcas-login%3Fredirect_url%3Dhttps%253A%252F%252Fworkflow1.fudan.edu.cn%252Fopen%252Fconnection%252Findex%253Fapp_id%253Dc5gI0Ro%2526state%253D%2526redirect_url%253Dhttps%253A%252F%252Fecard.fudan.edu.cn%252Fepay%252Fwxpage%252Ffudan%252Fzfm%252Fqrcode%253Furl%253D0";
  static const String QR_URL =
      "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode";

  QRCodeRepository._() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final _instance = QRCodeRepository._();

  factory QRCodeRepository.getInstance() => _instance;

  Future<String> getQRCode(PersonInfo info) async {
    return Retryer.runAsyncWithRetry(() => _getQRCode(info), retryTimes: 5);
  }

  Future<String> _getQRCode(PersonInfo info) async {
    await UISLoginTool.loginUIS(_dio, LOGIN_URL, _cookieJar, info);
    var res = await _dio.get(QR_URL);
    var soup = Beautifulsoup(res.data.toString());
    return soup.find(id: "#myText").attributes['value'];
  }
}
