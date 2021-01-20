import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/card_detail.dart';
import 'package:dan_xi/page/card_traffic.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/repository/fudan_daily_repository.dart';
import 'package:dan_xi/repository/qr_code_repository.dart';
import 'package:dan_xi/util/fdu_wifi_detection.dart';
import 'package:dan_xi/util/wifi_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

final QuickActions quickActions = QuickActions();

void main() {
  runApp(DanxiApp());
}

class DanxiApp extends StatelessWidget {
  final Map<String, Function> routes = {
    '/card/detail': (context, {arguments}) =>
        CardDetailPage(arguments: arguments),
    '/card/crowdData': (context, {arguments}) =>
        CardCrowdData(arguments: arguments)
  };

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "旦兮",
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomePage(title: "旦兮"),
      onGenerateRoute: (settings) {
        final String name = settings.name;
        final Function pageContentBuilder = this.routes[name];
        if (pageContentBuilder != null) {
          final Route route = MaterialPageRoute(
              builder: (context) =>
                  pageContentBuilder(context, arguments: settings.arguments));
          return route;
        }
        return null;
      },
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _helloQuote = "";
  String _connectionStatus = "无";
  CardInfo _cardInfo;
  SharedPreferences _preferences;
  PersonInfo _personInfo;
  bool _fudanDailyTicked = true;

  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _showQRCode() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: Text("复活码"),
              content: Container(
                  width: double.maxFinite,
                  child: Center(
                      child: FutureBuilder<String>(
                          future: QRCodeRepository.getInstance()
                              .getQRCode(_personInfo),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.hasData) {
                              return QrImage(data: snapshot.data, size: 200.0);
                            } else {
                              return Text("加载复活码中...\n(由于复旦校园服务器较差，可能需要5~10秒)");
                            }
                          }))));
        });
  }

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = WiFiUtils.getConnectivity()
        .onConnectivityChanged
        .listen((_) => {_loadNetworkState()});
    _loadSharedPreference();
    _loadNetworkState();
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'action_qr_code', localizedTitle: '复活码', icon: 'ic_launcher'),
    ]);

    quickActions.initialize((shortcutType) {
      if (shortcutType == 'action_qr_code') {
        if (_personInfo != null) {
          _showQRCode();
        }
      }
    });
  }

  Future<void> _tryLogin(String id, String pwd) async {
    var progressDialog =
        showProgressDialog(loadingText: "尝试登录中...", context: context);
    var name = "";
    await CardRepository.getInstance().login(new PersonInfo(id, pwd, "")).then(
        (_) async => {
              progressDialog.dismiss(),
              _preferences.setString("id", id),
              _preferences.setString("password", pwd),
              name = await CardRepository.getInstance().getName(),
              _preferences.setString("name", name),
              setState(() {
                _personInfo = new PersonInfo(id, pwd, name);
              }),
              Navigator.of(context).pop(),
            },
        onError: (_) => {
              progressDialog.dismiss(),
              Fluttertoast.showToast(msg: "登录失败，请检查用户名和密码是否正确！")
            });
  }

  Future<void> _loadSharedPreference({bool forceLogin = false}) async {
    _preferences = await SharedPreferences.getInstance();
    if (!_preferences.containsKey("id") || forceLogin) {
      var nameController = new TextEditingController();
      var pwdController = new TextEditingController();
      showDialog<Null>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: Text("登录Fudan UIS"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "UIS账号", icon: Icon(Icons.perm_identity)),
                    autofocus: true,
                  ),
                  TextField(
                    controller: pwdController,
                    decoration: InputDecoration(
                        labelText: "UIS密码", icon: Icon(Icons.lock_outline)),
                    obscureText: true,
                  )
                ],
              ),
              actions: [
                FlatButton(
                  child: Text("取消"),
                  onPressed: () {
                    if (forceLogin)
                      Navigator.of(context).pop();
                    else
                      exit(0);
                  },
                ),
                FlatButton(
                  child: Text("登录"),
                  onPressed: () async {
                    if (nameController.text.length * pwdController.text.length >
                        0) {
                      _tryLogin(nameController.text, pwdController.text);
                    }
                  },
                )
              ],
            );
          });
    } else {
      setState(() {
        _personInfo = new PersonInfo(_preferences.getString("id"),
            _preferences.getString("password"), _preferences.getString("name"));
      });
    }
  }

  Future<void> _loadNetworkState() async {
    var connectivity = await WiFiUtils.getConnectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.wifi) {
      var result;
      try {
        result = await WiFiUtils.getWiFiInfo(connectivity);
      } catch (e) {
        print(e);
      }
      setState(() {
        _connectionStatus = result == null || result['name'] == null
            ? "获取WiFi名称失败，检查位置服务开启情况"
            : FDUWiFiConverter.recognizeWiFi(result['name']);
      });
    } else {
      setState(() {
        _connectionStatus = "没有链接到WiFi";
      });
    }
  }

  Future<String> _loadCard() async {
    Fluttertoast.showToast(msg: "Testtest!");
    await CardRepository.getInstance().login(_personInfo);
    _cardInfo = await CardRepository.getInstance().loadCardInfo(7);
    return _cardInfo.cash;
  }

  @override
  Widget build(BuildContext context) {
    int time = DateTime.now().hour;
    if (time >= 23 || time <= 4) {
      _helloQuote = "披星戴月，不负韶华";
    } else if (time >= 5 && time <= 8) {
      _helloQuote = "一日之计在于晨";
    } else if (time >= 9 && time <= 11) {
      _helloQuote = "快到中午啦";
    } else if (time >= 12 && time <= 16) {
      _helloQuote = "下午的悠闲时光~";
    } else if (time >= 17 && time <= 22) {
      _helloQuote = "晚上好~";
    }

    print("Start run");
    return _personInfo == null
        ? Scaffold(
            appBar: AppBar(
            title: Text(widget.title),
          ))
        : Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Column(
              children: <Widget>[
                Card(
                    child: Column(
                  children: [
                    ListTile(
                      title: Text("欢迎你,${_personInfo?.name}"),
                      subtitle: Text(_helloQuote),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.wifi),
                      title: Text("当前连接"),
                      subtitle: Text(_connectionStatus),
                    ),
                    ListTile(
                      leading: Icon(Icons.account_balance_wallet),
                      title: Text("饭卡余额"),
                      subtitle: FutureBuilder(
                          future: _loadCard(),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            if (snapshot.hasData) {
                              String response = snapshot.data;
                              return Text(response);
                            } else {
                              return Text("获取中...");
                            }
                          }),
                      onTap: () {
                        if (_cardInfo != null) {
                          Navigator.of(context).pushNamed("/card/detail",
                              arguments: {
                                "cardInfo": _cardInfo,
                                "personInfo": _personInfo
                              });
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.stacked_line_chart),
                      title: Text("食堂排队消费状况"),
                      onTap: () {
                        Navigator.of(context).pushNamed("/card/crowdData",
                            arguments: {
                              "cardInfo": _cardInfo,
                              "personInfo": _personInfo
                            });
                      },
                    )
                  ],
                )),
                Card(
                  child: ListTile(
                    title: Text("平安复旦"),
                    leading: Icon(Icons.cloud_upload),
                    subtitle: FutureBuilder(
                        future: FudanDailyRepository.getInstance()
                            .hasTick(_personInfo),
                        builder: (_, AsyncSnapshot<bool> snapshot) {
                          if (snapshot.hasData) {
                            _fudanDailyTicked = snapshot.data;
                            return Text(
                                _fudanDailyTicked ? "你今天已经上报过了哦！" : "点击上报");
                          } else {
                            return Text("获取中...");
                          }
                        }),
                    onTap: () async {
                      if (_fudanDailyTicked) return;
                      var progressDialog = showProgressDialog(
                          loadingText: "打卡中...", context: context);
                      await FudanDailyRepository.getInstance()
                          .tick(_personInfo)
                          .then(
                              (value) =>
                                  {progressDialog.dismiss(), setState(() {})},
                              onError: (_) => {
                                    progressDialog.dismiss(),
                                    Fluttertoast.showToast(msg: "打卡失败，请检查网络连接~")
                                  });
                    },
                  ),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await _loadSharedPreference(forceLogin: true);
              },
              tooltip: '切换账号',
              child: Icon(Icons.login),
            ),
          );
  }
}
