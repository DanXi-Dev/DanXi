import 'dart:async';

import 'package:catcher/catcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/card_detail.dart';
import 'package:dan_xi/page/card_traffic.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/repository/qr_code_repository.dart';
import 'package:dan_xi/util/fdu_wifi_detection.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/wifi_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/l10n.dart';

final QuickActions quickActions = QuickActions();

void main() {
  CatcherOptions debugOptions = CatcherOptions(PageReportMode(), [
    ConsoleHandler()
  ], localizationOptions: [
    LocalizationOptions.buildDefaultEnglishOptions(),
    LocalizationOptions.buildDefaultChineseOptions(),
  ]);
  //Bmob.init("https://api2.bmob.cn", Secret.APP_ID, Secret.API_KEY);
  Catcher(
      rootWidget: DanxiApp(),
      debugConfig: debugOptions,
      releaseConfig: debugOptions);
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
      title: "DanXi",
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: HomePage(),
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
      //Catcher integration
      navigatorKey: Catcher.navigatorKey,
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SharedPreferences _preferences;
  ValueNotifier<PersonInfo> _personInfo = ValueNotifier(null);
  ValueNotifier<String> _connectStatus = ValueNotifier("");
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  int _pageindex = 0;

  final List<Function> _subpageBuilders = [
    () => HomeSubpage(),
    () => BBSSubpage()
  ];

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
          return AlertDialog(
              title: Text(S.of(context).fudan_qr_code),
              content: Container(
                  width: double.maxFinite,
                  child: Center(
                      child: FutureBuilder<String>(
                          future: QRCodeRepository.getInstance()
                              .getQRCode(_personInfo.value),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            return snapshot.hasData
                                ? QrImage(data: snapshot.data, size: 200.0)
                                : Text(S.of(context).loading_qr_code);
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
      ShortcutItem(
          type: 'action_qr_code',
          localizedTitle: S.current.fudan_qr_code,
          icon: 'ic_launcher'),
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
    var progressDialog = showProgressDialog(
        loadingText: S.of(context).logining, context: context);
    var name = "";
    await CardRepository.getInstance().login(new PersonInfo(id, pwd, "")).then(
        (_) async => {
              progressDialog.dismiss(),
              _preferences.setString("id", id),
              _preferences.setString("password", pwd),
              name = await CardRepository.getInstance().getName(),
              _preferences.setString("name", name),
              setState(() {
                _personInfo.value = new PersonInfo(id, pwd, name);
              }),
              Navigator.of(context).pop(),
            },
        onError: (e) => {progressDialog.dismiss(), throw e});
  }

  void _showLoginDialog({bool forceLogin = false}) {
    var nameController = new TextEditingController();
    var pwdController = new TextEditingController();
    showDialog<Null>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text(S.of(context).login_uis),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: S.of(context).login_uis_uid,
                      icon: Icon(Icons.perm_identity)),
                  autofocus: true,
                ),
                TextField(
                  controller: pwdController,
                  decoration: InputDecoration(
                      labelText: S.of(context).login_uis_pwd,
                      icon: Icon(Icons.lock_outline)),
                  obscureText: true,
                )
              ],
            ),
            actions: [
              TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () {
                  if (forceLogin)
                    Navigator.of(context).pop();
                  else
                    FlutterApp.exitApp();
                },
              ),
              TextButton(
                child: Text(S.of(context).login),
                onPressed: () async {
                  if (nameController.text.length * pwdController.text.length >
                      0) {
                    await _tryLogin(nameController.text, pwdController.text);
                  }
                },
              )
            ],
          );
        });
  }

  Future<void> _loadSharedPreference({bool forceLogin = false}) async {
    _preferences = await SharedPreferences.getInstance();
    if (!_preferences.containsKey("id") || forceLogin) {
      _showLoginDialog(forceLogin: forceLogin);
    } else {
      setState(() {
        _personInfo.value = new PersonInfo(_preferences.getString("id"),
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
      } catch (ignored) {}
      setState(() {
        _connectStatus.value = result == null || result['name'] == null
            ? S.current.current_connection_failed
            : FDUWiFiConverter.recognizeWiFi(result['name']);
      });
    } else {
      setState(() {
        _connectStatus.value = S.of(context).current_connection_no_wifi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Start run");
    return _personInfo.value == null
        ? Scaffold(
            appBar: AppBar(
            title: Text(S.of(context).app_name),
          ))
        : Scaffold(
            appBar: AppBar(
              title: Text(
                S.of(context).app_name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: _connectStatus),
                ChangeNotifierProvider.value(value: _personInfo),
              ],
              child: _subpageBuilders[_pageindex](),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  backgroundColor: Colors.purple,
                  icon: Icon(Icons.dashboard),
                  label: S.of(context).dashboard,
                ),
                BottomNavigationBarItem(
                  backgroundColor: Colors.indigo,
                  icon: Icon(Icons.forum),
                  label: S.of(context).forum,
                ),
                // BottomNavigationBarItem(
                //   backgroundColor: Colors.blue,
                //   icon: Icon(Icons.person),
                //   label: "我",
                // ),
              ],
              currentIndex: _pageindex,
              type: BottomNavigationBarType.shifting,
              onTap: (index) {
                if (index != _pageindex) {
                  setState(() {
                    _pageindex = index;
                  });
                }
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await _loadSharedPreference(forceLogin: true);
              },
              tooltip: S.of(context).change_account,
              child: Icon(Icons.login),
            ),
          );
  }
}
