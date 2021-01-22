import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';

import 'inpersistent_cookie_manager.dart';

class CardRepository {
  PersonInfo _info;
  Dio _dio = Dio();
  NonpersistentCookieJar _cookieJar =
      NonpersistentCookieJar(ignoreExpires: true);
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fecard.fudan.edu.cn%2Fepay%2Fj_spring_cas_security_check";
  static const String USER_DETAIL_URL =
      "http://ecard.fudan.edu.cn/epay/myepay/index";
  static const String CONSUME_DETAIL_URL =
      "http://ecard.fudan.edu.cn/epay/consume/query";
  static const String CONSUME_DETAIL_CSRF_URL =
      "http://ecard.fudan.edu.cn/epay/consume/index";

  static var _consumeDetailHeader = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0",
    "Accept": "text/xml",
    "Accept-Language": "zh-CN,en-US;q=0.7,en;q=0.3",
    "Content-Type": "application/x-www-form-urlencoded",
    "Origin": "http://ecard.fudan.edu.cn",
    "DNT": "1",
    "Connection": "keep-alive",
    "Referer": "http://ecard.fudan.edu.cn/epay/consume/index",
    "Sec-GPC": "1"
  };

  CardRepository._() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final _instance = CardRepository._();

  factory CardRepository.getInstance() => _instance;

  bool _testLoginSuccess() {
    return _cookieJar
        .loadForRequest(Uri.parse("http://ecard.fudan.edu.cn/"))
        .any((element) => element.name == "iPlanetDirectoryPro");
  }

  Future<void> login(PersonInfo info) async {
    _info = info;
    await Retryer.runAsyncWithRetry(() async {
      await UISLoginTool.loginUIS(_dio, LOGIN_URL, _cookieJar, _info);
      if (!_testLoginSuccess()) {
        throw new LoginException();
      }
      return null;
    });
  }

  Future<String> getName() async {
    if (_info != null && _info.name.length > 0) return _info.name;
    return (await loadCardInfo(-1)).name;
  }

  Future<Iterable<CardRecord>> _loadOnePageCardRecord(
      Map<String, String> requestData, int pageNum) async {
    requestData['pageNo'] = pageNum.toString();
    var detailResponse = await _dio.post(CONSUME_DETAIL_URL,
        data: requestData.encodeMap(),
        options: Options(headers: _consumeDetailHeader));
    var soup = Beautifulsoup(
        detailResponse.data.toString().between("<![CDATA[", "]]>"));
    var elements = soup.find(id: "tbody").querySelectorAll("tr");
    Iterable<CardRecord> records = elements.map((e) {
      var details = e.querySelectorAll("td");
      return CardRecord(
          DateTime.parse(
              "${details[0].children[0].text.trim().replaceAll("\.", "-")}T${details[0].children[1].text.trim()}"),
          details[1].children[0].text.trim(),
          details[2].text.trim().replaceAll("&nbsp;", ""),
          details[3].text.trim().replaceAll("&nbsp;", ""));
    });
    return records;
  }

  Future<List<CardRecord>> loadCardRecord(int logDays) async {
    print("Start load record.");
    if (logDays < 0) return null;
    //Get csrf id.
    var consumeCsrfPageResponse = await _dio.get(CONSUME_DETAIL_CSRF_URL);
    var consumeCsrfPageSoup =
        Beautifulsoup(consumeCsrfPageResponse.data.toString());
    var metas = consumeCsrfPageSoup.find_all("meta");
    var element = metas.firstWhere(
        (element) => element.attributes["name"] == "_csrf",
        orElse: () => null);
    print("Csrf is $element");
    var csrfId = element.attributes["content"];

    //Build the request body.
    var end = new DateTime.now();
    var start = end.add(Duration(days: -logDays));
    var formatter = new DateFormat('yyyy-MM-dd');
    var data = {
      "aaxmlrequest": "true",
      "pageNo": "1",
      "tabNo": "1",
      "pager.offset": "10",
      "tradename": "",
      "starttime": formatter.format(start),
      "endtime": formatter.format(end),
      "timetype": "1",
      "_tradedirect": "on",
      "_csrf": csrfId,
    };

    //Get the number of pages.

    var detailResponse = await _dio.post(CONSUME_DETAIL_URL,
        data: data.encodeMap(),
        options: Options(headers: _consumeDetailHeader));

    var totalPages =
        int.parse(detailResponse.data.toString().between('</b>/', "页"));

    //Get pages.
    List<CardRecord> list = [];
    for (int pageIndex = 1; pageIndex <= totalPages; pageIndex++) {
      list.addAll(await _loadOnePageCardRecord(data, pageIndex));
    }

    return list;
  }

  Future<CardInfo> loadCardInfo(int logDays) async {
    if (!_testLoginSuccess()) {
      throw new LoginException();
    }
    var cardInfo = CardInfo();

    //获取用户页面信息
    var userPageResponse = await _dio.get(USER_DETAIL_URL);
    cardInfo.cash =
        userPageResponse.data.toString().between("<p>账户余额：", "元</p>");
    cardInfo.name = userPageResponse.data.toString().between("姓名：", "</p>");

    List<CardRecord> records =
        await Retryer.runAsyncWithRetry(() => loadCardRecord(logDays));
    cardInfo.records = records;
    return cardInfo;
  }
}

class CardInfo {
  String cash;
  String name;
  List<CardRecord> records;
}

class CardRecord {
  DateTime time;
  String type;
  String location;
  String payment;

  CardRecord(this.time, this.type, this.location, this.payment);
}

class LoginException implements Exception {}
