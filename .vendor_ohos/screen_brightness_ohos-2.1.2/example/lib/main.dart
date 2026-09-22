import 'package:flutter/material.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final RouteObserver<Route> routeObserver = RouteObserver<Route>();

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      onGenerateRoute: (settings) {
        late final Widget page;
        switch (settings.name) {
          case HomePage.routeName:
            page = const HomePage();
            break;

          case ControllerPage.routeName:
            page = const ControllerPage();
            break;

          case RouteAwarePage.routeName:
            page = const RouteAwarePage();
            break;

          case BlankPage.routeName:
            page = const BlankPage();
            break;

          case SettingPage.routeName:
            page = const SettingPage();
            break;

          default:
            throw UnimplementedError('page name not found');
        }

        return MaterialPageRoute(
          builder: (context) => page,
          settings: settings,
        );
      },
      navigatorObservers: [
        routeObserver,
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  static const routeName = '/home';

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen brightness example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<double>(
              future: ScreenBrightnessPlatform.instance.application,
              builder: (context, snapshot) {
                double applicationBrightness = 0;
                if (snapshot.hasData) {
                  applicationBrightness = snapshot.data!;
                }

                return StreamBuilder<double>(
                  stream: ScreenBrightnessPlatform
                      .instance.onApplicationScreenBrightnessChanged,
                  builder: (context, snapshot) {
                    double changedApplicationBrightness = applicationBrightness;
                    if (snapshot.hasData) {
                      changedApplicationBrightness = snapshot.data!;
                    }

                    return Text(
                        'Application brightness $changedApplicationBrightness');
                  },
                );
              },
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(ControllerPage.routeName),
              child: const Text('Controller example page'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteAwarePage.routeName),
              child: const Text('Route aware example page'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SettingPage.routeName),
              child: const Text('Setting page'),
            ),
          ],
        ),
      ),
    );
  }
}

class ControllerPage extends StatefulWidget {
  static const routeName = '/controller';

  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  Future<void> setSystemBrightness(double brightness) async {
    try {
      await ScreenBrightnessPlatform.instance
          .setSystemScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set system brightness';
    }
  }

  Future<void> setApplicationBrightness(double brightness) async {
    try {
      await ScreenBrightnessPlatform.instance
          .setApplicationScreenBrightness(brightness);
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set application brightness';
    }
  }

  Future<void> resetApplicationBrightness() async {
    try {
      await ScreenBrightnessPlatform.instance
          .resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to reset application brightness';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<double>(
            future: ScreenBrightnessPlatform.instance.system,
            builder: (context, snapshot) {
              double systemBrightness = 0;
              if (snapshot.hasData) {
                systemBrightness = snapshot.data!;
              }

              return StreamBuilder<double>(
                  stream: ScreenBrightnessPlatform
                      .instance.onSystemScreenBrightnessChanged,
                  builder: (context, snapshot) {
                    double changedSystemBrightness = systemBrightness;
                    if (snapshot.hasData) {
                      changedSystemBrightness = snapshot.data!;
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('System brightness: $changedSystemBrightness'),
                        Slider.adaptive(
                          value: changedSystemBrightness,
                          onChanged: (value) {
                            setSystemBrightness(value);
                          },
                        ),
                      ],
                    );
                  });
            },
          ),
          FutureBuilder<double>(
            future: ScreenBrightnessPlatform.instance.application,
            builder: (context, snapshot) {
              double applicationBrightness = 0;
              if (snapshot.hasData) {
                applicationBrightness = snapshot.data!;
              }

              return StreamBuilder<double>(
                stream: ScreenBrightnessPlatform
                    .instance.onApplicationScreenBrightnessChanged,
                builder: (context, snapshot) {
                  double changedApplicationBrightness = applicationBrightness;
                  if (snapshot.hasData) {
                    changedApplicationBrightness = snapshot.data!;
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<bool>(
                        future: ScreenBrightnessPlatform
                            .instance.hasApplicationScreenBrightnessChanged,
                        builder: (context, snapshot) {
                          return Text(
                              'Application brightness has changed via plugin: ${snapshot.data}');
                        },
                      ),
                      Text(
                          'Application brightness: $changedApplicationBrightness'),
                      Slider.adaptive(
                        value: changedApplicationBrightness,
                        onChanged: (value) {
                          setApplicationBrightness(value);
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          resetApplicationBrightness();
                        },
                        child: const Text('reset brightness'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class RouteAwarePage extends StatefulWidget {
  static const routeName = '/routeAware';

  const RouteAwarePage({super.key});

  @override
  State<RouteAwarePage> createState() => _RouteAwarePageState();
}

class _RouteAwarePageState extends State<RouteAwarePage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyApp.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    MyApp.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    super.didPush();
    ScreenBrightnessPlatform.instance.setApplicationScreenBrightness(0.7);
  }

  @override
  void didPushNext() {
    super.didPushNext();
    ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
  }

  @override
  void didPop() {
    super.didPop();
    ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    ScreenBrightnessPlatform.instance.setApplicationScreenBrightness(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route aware'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(BlankPage.routeName),
          child: const Text('Next page'),
        ),
      ),
    );
  }
}

class BlankPage extends StatelessWidget {
  static const routeName = '/blankPage';

  const BlankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blank'),
      ),
    );
  }
}

class SettingPage extends StatefulWidget {
  static const routeName = '/setting';

  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isAutoReset = true;
  bool isAnimate = true;
  bool canChangeSystemBrightness = true;

  @override
  void initState() {
    super.initState();
    getIsAutoResetSetting();
    getIsAnimateSetting();
    getCanChangeSystemBrightness();
  }

  Future<void> getIsAutoResetSetting() async {
    final isAutoReset = await ScreenBrightnessPlatform.instance.isAutoReset;
    setState(() {
      this.isAutoReset = isAutoReset;
    });
  }

  Future<void> getIsAnimateSetting() async {
    final isAnimate = await ScreenBrightnessPlatform.instance.isAnimate;
    setState(() {
      this.isAnimate = isAnimate;
    });
  }

  Future<void> getCanChangeSystemBrightness() async {
    final canChangeSystemBrightness =
    await ScreenBrightnessPlatform.instance.canChangeSystemBrightness;
    setState(() {
      this.canChangeSystemBrightness = canChangeSystemBrightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Auto Reset'),
            trailing: Switch(
              value: isAutoReset,
              onChanged: (value) async {
                await ScreenBrightnessPlatform.instance.setAutoReset(value);
                await getIsAutoResetSetting();
              },
            ),
          ),
          ListTile(
            title: const Text('Animate'),
            trailing: Switch(
              value: isAnimate,
              onChanged: (value) async {
                await ScreenBrightnessPlatform.instance.setAnimate(value);
                await getIsAnimateSetting();
              },
            ),
          ),
          ListTile(
            title: const Text('Can change system brightness'),
            trailing: Switch(
              value: canChangeSystemBrightness,
              onChanged: (value) {},
            ),
          ),
        ],
      ),
    );
  }
}
