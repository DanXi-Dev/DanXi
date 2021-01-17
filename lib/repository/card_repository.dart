import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dan_xi/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';

class CardRepository {
  PersonInfo _info;
  Dio _dio = Dio();
  DefaultCookieJar _cookieJar = DefaultCookieJar();
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fecard.fudan.edu.cn%2Fepay%2Fj_spring_cas_security_check";
  static const String USER_DETAIL_URL =
      "http://ecard.fudan.edu.cn/epay/myepay/index";
  static const String CONSUME_DETAIL_URL =
      "http://ecard.fudan.edu.cn/epay/consume/query";
  static const String CONSUME_DETAIL_CSRF_URL =
      "http://ecard.fudan.edu.cn/epay/consume/index";

  static var _CONSUME_DETAIL_HEADER = {
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
    await UISLoginTool.loginUIS(_dio, LOGIN_URL, _cookieJar, _info);
    if (!_testLoginSuccess()) {
      throw new LoginException();
    }
  }

  Future<String> getName() async {
    if (_info != null && _info.name.length > 0) return _info.name;
    return (await loadCardInfo(0)).name;
  }

  Future<Iterable<CardRecord>> _loadOnePageCardRecord(
      Map<String, String> requestData, int pageNum) async {
    requestData['pageNo'] = pageNum.toString();
    var detailResponse = await _dio.post(CONSUME_DETAIL_URL,
        data: requestData.encodeMap(),
        options: Options(headers: _CONSUME_DETAIL_HEADER));
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
    if (!_testLoginSuccess()) {
      throw new LoginException();
    }
    if (logDays < 0) return null;
    //Get csrf id.
    var consumeCsrfPageResponse = await _dio.get(CONSUME_DETAIL_CSRF_URL);
    var consumeCsrfPageSoup =
        Beautifulsoup(consumeCsrfPageResponse.data.toString());
    var metas = consumeCsrfPageSoup.find_all("meta");
    var element =
        metas.firstWhere((element) => element.attributes["name"] == "_csrf");
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
        options: Options(headers: _CONSUME_DETAIL_HEADER));

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
    cardInfo.name = userPageResponse.data.toString().between("<p>姓名：", "</p>");
    List<CardRecord> records =
        await Retryer.runAsyncWithRetry(() => loadCardRecord(logDays));
    cardInfo.records = records;
    return cardInfo;
  }

  //TODO 获取人流量信息
  Future<TrafficInfo> loadTrafficInfo(String name) async {
    // if (_cookie == "") {
    //   throw new LoginException();
    // }
    // TrafficInfo info = TrafficInfo(name);
    // var headers = {
    //   'User-Agent':
    //       'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0',
    //   'Accept': 'application/json, text/javascript, */*; q=0.01',
    //   'Accept-Language': 'zh-CN,en-US;q=0.7,en;q=0.3',
    //   'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    //   'X-Requested-With': 'XMLHttpRequest',
    //   'Origin': 'http://ecard.fudan.edu.cn',
    //   'DNT': '1',
    //   'Connection': 'keep-alive',
    //   'Referer':
    //       'http://ecard.fudan.edu.cn/web/guest/accdata?p_p_id=pAccData_WAR_yktPortalportlet&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1',
    //   'Pragma': 'no-cache',
    //   'Cache-Control': 'no-cache',
    //   'Cookie': _cookie,
    //   'Accept-Encoding': 'gzip',
    // };
    // var params = {
    //   'p_p_id': 'pAccData_WAR_yktPortalportlet',
    //   'p_p_lifecycle': '2',
    //   'p_p_state': 'normal',
    //   'p_p_mode': 'view',
    //   'p_p_resource_id': 'last5m',
    //   'p_p_cacheability': 'cacheLevelPage',
    //   'p_p_col_id': 'column-1',
    //   'p_p_col_count': '1',
    // };
    // var query = params.entries.map((p) => '${p.key}=${p.value}').join('&');
    // var data =
    //     '_pAccData_WAR_yktPortalportlet_businame=${Uri.encodeComponent(name)}';
    // var res = await http.post(
    //     'http://ecard.fudan.edu.cn/web/guest/accdata?$query',
    //     headers: headers,
    //     body: data);
    // List<dynamic> json = jsonDecode(res.body);
    // json.forEach((element) {
    //   if (element is List) {
    //     var time = DateTime.now();
    //     info.record[DateTime(time.year, time.month, time.day,
    //             (element[1] as int) ~/ 100, (element[1] as int) % 100)] =
    //         NumberRecordInfo(element[2], element[3]);
    //   }
    // });
    // return info;
    return null;
  }
}

class CardInfo {
  String cash;
  String name;
  List<CardRecord> records;
}

class TrafficInfo {
  String name;
  Map<DateTime, NumberRecordInfo> record;

  TrafficInfo(String name) {
    this.name = name;
    record = {};
  }
}

class NumberRecordInfo {
  int person;
  int card;

  NumberRecordInfo(this.person, this.card);
}

class CardRecord {
  DateTime time;
  String type;
  String location;
  String payment;

  // String moneyBefore;
  // String moneyAfter;

  CardRecord(this.time, this.type, this.location, this.payment);
}

class LoginException implements Exception {}
