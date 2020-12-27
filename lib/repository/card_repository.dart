import 'dart:convert';

import 'package:dan_xi/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CardRepository {
  PersonInfo _info;
  String _cookie = "";

  CardRepository._();

  static final _instance = CardRepository._();

  factory CardRepository.getInstance() => _instance;

  Future<void> login(PersonInfo info) async {
    _info = info;
    var headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,en-US;q=0.7,en;q=0.3',
      'Referer':
          'http://ecard.fudan.edu.cn/web/guest/index?p_p_state=maximized&p_p_mode=view&saveLastPath=false&_58_struts_action=%2Flogin%2Flogin&p_p_id=58&p_p_lifecycle=0&_58_redirect=%2Fweb%2Fguest%2Fpersonal',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Origin': 'http://ecard.fudan.edu.cn',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'Accept-Encoding': 'gzip',
    };

    var params = {
      'p_p_id': '58',
      'p_p_lifecycle': '1',
      'p_p_state': 'maximized',
      'p_p_mode': 'view',
      '_58_struts_action': '/login/login',
    };
    var query = params.entries.map((p) => '${p.key}=${p.value}').join('&');

    var data =
        '_58_formDate=${DateTime.now().millisecondsSinceEpoch}&_58_saveLastPath=false&_58_redirect=%2Fweb%2Fguest%2Fpersonal&_58_doActionAfterLogin=false&_58_login=${_info.id}&_58_password=${_info.password}&_58_rememberMe=false';

    var res = await http.post(
        'http://ecard.fudan.edu.cn/web/guest/index?$query',
        headers: headers,
        body: data);
    _cookie = res.headers['set-cookie'];
    if (!_cookie.contains("iPlanetDirectoryPro")) {
      throw new LoginException();
    }
  }

  Future<String> getName() async {
    if (_info != null && _info.name.length > 0) return _info.name;
    return (await loadCardInfo(1)).name;
  }

  Future<CardInfo> loadCardInfo(int logDays) async {
    if (_cookie == "") {
      throw new LoginException();
    }
    var cardInfo = CardInfo();

    //获取用户页面信息
    var headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'zh-CN,en-US;q=0.7,en;q=0.3',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Referer': 'http://ecard.fudan.edu.cn/web/guest/personal',
      'Upgrade-Insecure-Requests': '1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'Cookie': _cookie,
      'Accept-Encoding': 'gzip',
    };
    var userPageResponse = await http
        .get('http://ecard.fudan.edu.cn/web/guest/personal', headers: headers);
    cardInfo.cash = userPageResponse.body
        .between("余&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;额：</span>", "元");
    cardInfo.name = userPageResponse.body
        .between("姓&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;名：</span>", "</li>");
    //获取饭卡交易记录
    headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0',
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'zh-CN,en-US;q=0.7,en;q=0.3',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      'Origin': 'http://ecard.fudan.edu.cn',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Referer': 'http://ecard.fudan.edu.cn/web/guest/personal',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'Cookie': _cookie,
      'Accept-Encoding': 'gzip',
    };
    var params = {
      'p_p_id': 'ptransdetail_WAR_yktPortalportlet',
      'p_p_lifecycle': '2',
      'p_p_state': 'normal',
      'p_p_mode': 'view',
      'p_p_resource_id': 'queryTransdtl',
      'p_p_cacheability': 'cacheLevelPage',
      'p_p_col_id': 'column-2',
      'p_p_col_count': '1',
    };
    var end = new DateTime.now();
    var start = end.add(Duration(days: -logDays));
    var formatter = new DateFormat('yyyy-MM-dd');
    var query = params.entries.map((p) => '${p.key}=${p.value}').join('&');
    var cardLogResponse = await http.post(
        'http://ecard.fudan.edu.cn/web/guest/personal?$query',
        headers: headers,
        body:
            "_ptransdetail_WAR_yktPortalportlet_begindate=${formatter.format(start)}&_ptransdetail_WAR_yktPortalportlet_enddate=${formatter.format(end)}");
    List logList = jsonDecode(cardLogResponse.body);
    cardInfo.records = [];
    logList.forEach((element) {
      cardInfo.records.add(CardRecord(
          DateTime.parse("${element[1]}T${element[2]}"),
          element[3],
          element[4],
          element[5].toString().trim(),
          element[6],
          element[7]));
    });
    return cardInfo;
  }

  Future<TrafficInfo> loadTrafficInfo(String name) async {
    if (_cookie == "") {
      throw new LoginException();
    }
    TrafficInfo info = TrafficInfo(name);
    var headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0',
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'zh-CN,en-US;q=0.7,en;q=0.3',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      'Origin': 'http://ecard.fudan.edu.cn',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Referer':
          'http://ecard.fudan.edu.cn/web/guest/accdata?p_p_id=pAccData_WAR_yktPortalportlet&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'Cookie': _cookie,
      'Accept-Encoding': 'gzip',
    };
    var params = {
      'p_p_id': 'pAccData_WAR_yktPortalportlet',
      'p_p_lifecycle': '2',
      'p_p_state': 'normal',
      'p_p_mode': 'view',
      'p_p_resource_id': 'last5m',
      'p_p_cacheability': 'cacheLevelPage',
      'p_p_col_id': 'column-1',
      'p_p_col_count': '1',
    };
    var query = params.entries.map((p) => '${p.key}=${p.value}').join('&');
    var data =
        '_pAccData_WAR_yktPortalportlet_businame=${Uri.encodeComponent(name)}';
    var res = await http.post(
        'http://ecard.fudan.edu.cn/web/guest/accdata?$query',
        headers: headers,
        body: data);
    List<dynamic> json = jsonDecode(res.body);
    json.forEach((element) {
      if (element is List) {
        var time = DateTime.now();
        info.record[DateTime(time.year, time.month, time.day,
                (element[1] as int) ~/ 100, (element[1] as int) % 100)] =
            NumberRecordInfo(element[2], element[3]);
      }
    });
    return info;
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
  String moneyBefore;
  String moneyAfter;

  CardRecord(this.time, this.type, this.location, this.payment,
      this.moneyBefore, this.moneyAfter);
}

class LoginException implements Exception {}
