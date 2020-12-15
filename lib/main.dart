import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dan_xi/card_repository.dart';
import 'package:dan_xi/fdu_wifi_detection.dart';
import 'package:dan_xi/fudan_daily_repository.dart';
import 'package:dan_xi/person.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Map<String, Function> routes = {
    '/card/detail': (context, {arguments}) =>
        CardDetailPage(arguments: arguments)
  };

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "旦兮",
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: MyHomePage(title: "旦兮"),
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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String hello = "";
  String connection = "无";
  CardInfo _cardInfo;
  SharedPreferences _preferences;
  PersonInfo personInfo;
  bool fudanDailyTicked = true;

  Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //_dio.interceptors.add(CookieManager(cookieJar))
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((_) => {_loadNetwork()});
    _loadSharedPreference();
    _loadNetwork();
  }

  Future<void> _loadSharedPreference({bool forceLogin = false}) async {
    _preferences = await SharedPreferences.getInstance();
    if (!_preferences.containsKey("id") || forceLogin) {
      var nameCtrler = new TextEditingController();
      var pwdCtrler = new TextEditingController();
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
                    controller: nameCtrler,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: "UIS账号", icon: Icon(Icons.perm_identity)),
                    autofocus: true,
                  ),
                  TextField(
                    controller: pwdCtrler,
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
                    if (nameCtrler.text.length * pwdCtrler.text.length > 0) {
                      var progressDialog = showProgressDialog(
                          loadingText: "尝试登录中...", context: context);
                      var name = "";
                      await CardRepository.getInstance()
                          .login(new PersonInfo(
                              nameCtrler.text, pwdCtrler.text, ""))
                          .then(
                              (_) async => {
                                    progressDialog.dismiss(),
                                    _preferences.setString(
                                        "id", nameCtrler.text),
                                    _preferences.setString(
                                        "password", pwdCtrler.text),
                                    name = await CardRepository.getInstance()
                                        .getName(),
                                    _preferences.setString("name", name),
                                    setState(() {
                                      personInfo = new PersonInfo(
                                          nameCtrler.text,
                                          pwdCtrler.text,
                                          name);
                                    }),
                                    Navigator.of(context).pop(),
                                  },
                              onError: (_) => {
                                    progressDialog.dismiss(),
                                    Fluttertoast.showToast(
                                        msg: "登录失败，请检查用户名和密码是否正确！")
                                  });
                    }
                  },
                )
              ],
            );
          });
    } else {
      setState(() {
        personInfo = new PersonInfo(_preferences.getString("id"),
            _preferences.getString("password"), _preferences.getString("name"));
      });
    }
  }

  Future<dynamic> _getWiFiInfo(ConnectivityResult result) async {
    var ans = {};
    switch (result) {
      case ConnectivityResult.wifi:
        String wifiName, wifiIP;

        try {
          if (!kIsWeb && Platform.isIOS) {
            LocationAuthorizationStatus status =
                await _connectivity.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status =
                  await _connectivity.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiName = await _connectivity.getWifiName();
            } else {
              await _connectivity.requestLocationServiceAuthorization();
              wifiName = await _connectivity.getWifiName();
            }
          } else {
            wifiName = await _connectivity.getWifiName().catchError((_, stack) {
              return null;
            });
          }
        } on PlatformException {
          wifiName = null;
        }
        ans['name'] = wifiName;

        try {
          wifiIP = await _connectivity.getWifiIP();
        } on PlatformException {
          wifiIP = null;
        }
        ans['ip'] = wifiIP;
        break;
      default:
        break;
    }
    return ans;
  }

  Future<void> _loadNetwork() async {
    var connectivity = await _connectivity.checkConnectivity();
    if (connectivity == ConnectivityResult.wifi) {
      var result;
      try {
        result = await _getWiFiInfo(connectivity);
      } catch (e) {
        print(e);
      }
      setState(() {
        connection = result == null || result['name'] == null
            ? "获取WiFi名称失败"
            : FDUWiFiConverter.recognizeWiFi(result['name']);
      });
    } else {
      setState(() {
        connection = "没有链接到WiFi";
      });
    }
  }

  Future<String> _loadCard() async {
    await CardRepository.getInstance().login(personInfo);
    _cardInfo = await CardRepository.getInstance().loadCardInfo(7);
    return _cardInfo.cash;
  }

  @override
  Widget build(BuildContext context) {
    int time = DateTime.now().hour;
    if (time >= 23 || time <= 4) {
      hello = "披星戴月，不负韶华";
    } else if (time >= 5 && time <= 8) {
      hello = "一日之计在于晨";
    } else if (time >= 9 && time <= 11) {
      hello = "快到中午啦";
    } else if (time >= 12 && time <= 16) {
      hello = "下午的悠闲时光~";
    } else if (time >= 17 && time <= 22) {
      hello = "晚上好~";
    }

    print("Start run");
    return personInfo == null
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
                    new ListTile(
                      title: Text("欢迎你,${personInfo?.name}"),
                      subtitle: Text(hello),
                    ),
                    Divider(),
                    new ListTile(
                      leading: Icon(Icons.wifi),
                      title: Text("当前连接"),
                      subtitle: Text(connection),
                    ),
                    new ListTile(
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
                        Navigator.of(context).pushNamed("/card/detail",
                            arguments: {
                              "cardInfo": _cardInfo,
                              "personInfo": personInfo
                            });
                      },
                    ),
                  ],
                )),
                Card(
                  child: ListTile(
                    title: Text("平安复旦"),
                    leading: Icon(Icons.cloud_upload),
                    subtitle: FutureBuilder(
                        future: FudanDailyRepository.getInstance()
                            .hasTick(personInfo),
                        builder: (_, AsyncSnapshot<bool> snapshot) {
                          if (snapshot.hasData) {
                            fudanDailyTicked = snapshot.data;
                            return Text(
                                fudanDailyTicked ? "你今天已经上报过了哦！" : "点击上报");
                          } else {
                            return Text("获取中...");
                          }
                        }),
                    onTap: () async {
                      if (fudanDailyTicked) return;
                      var progressDialog = showProgressDialog(
                          loadingText: "打卡中...", context: context);
                      await FudanDailyRepository.getInstance()
                          .tick(personInfo)
                          .then((value) => {
                                progressDialog.dismiss(),
                                setState(() {
                                  personInfo = personInfo;
                                })
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
              tooltip: 'Increment',
              child: Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
  }
}

class CardDetailPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _CardDetailPageState createState() => _CardDetailPageState();

  CardDetailPage({Key key, this.arguments});
}

class _CardDetailPageState extends State<CardDetailPage> {
  CardInfo _cardInfo;
  PersonInfo _personInfo;

  @override
  void initState() {
    _cardInfo = widget.arguments['cardInfo'];
    _personInfo = widget.arguments['personInfo'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("饭卡消费记录")),
      body: ListView(
        children: _getListWidgets(),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    _cardInfo.records.forEach((element) {
      widgets.add(ListTile(
        leading: Icon(Icons.monetization_on),
        title: Text(element.payment),
        isThreeLine: true,
        subtitle: Text("${element.location}\n${element.time.toString()}"),
      ));
    });

    return widgets;
  }
}
