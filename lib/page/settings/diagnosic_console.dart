/*
 *     Copyright (C) 2022  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/ad_manager.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DiagnosticConsole extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const DiagnosticConsole({Key? key, this.arguments}) : super(key: key);

  @override
  _DiagnosticConsoleState createState() => _DiagnosticConsoleState();
}

class _DiagnosticConsoleState extends State<DiagnosticConsole> {
  final StringBufferNotifier _console = StringBufferNotifier();

  late List<DiagnosticMethod> diagnoses;

  @override
  void initState() {
    super.initState();
    diagnoses = [diagnoseFDUHole, diagnoseGoogleAds];
    unawaited(diagnose());
  }

  Future<void> diagnose() async {
    for (var method in diagnoses) {
      try {
        await method();
      } catch (e, st) {
        _console.writeln("Met error when diagnosing! Error is:$e");
        _console.writeln(st);
      } finally {
        _console.writeln("");
      }
    }
  }

  Future<void> diagnoseFDUHole() async {
    _console.writeln(
        "FDUHole is user initialized: ${OpenTreeHoleRepository.getInstance().isUserInitialized}");
    _console.writeln(
        "FDUHole is user admin: ${OpenTreeHoleRepository.getInstance().isAdmin}");
    _console.writeln(
        "FDUHole Push Token last uploaded on this device: ${OpenTreeHoleRepository.getInstance().lastUploadToken}");
    _console.writeln(
        "FDUHole Token stored: ${context.read<SettingsProvider>().fduholeToken}");

    String? deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
    } catch (error, stackTrace) {
      _console.writeln("Met error when retrieving Device Id! Error is:$error");
      _console.writeln(stackTrace);
    }
    if (deviceId == null) {
      _console.writeln("Your Device Id(Random UUID): ${const Uuid().v4()}");
    } else {
      _console.writeln("Your Device Id(Real ID): $deviceId");
    }
  }

  Future<void> diagnoseGoogleAds() async {
    if (!PlatformX.isMobile) return;
    _console.writeln("Trying to load google ads……");
    BannerAd bannerAd;
    final BannerAdListener listener = BannerAdListener(
      // Called when an ad is successfully received.
      onAdLoaded: (Ad ad) {
        _console.writeln(
            "Successfully load! ad responseId = ${ad.responseInfo?.responseId}");
      },
      // Called when an ad request failed.
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        _console.writeln("Unable to load ads! error is $error");
        // Dispose the ad here to free resources.
        ad.dispose();
      },
      // Called when an ad opens an overlay that covers the screen.
      onAdOpened: (Ad ad) {},
      // Called when an ad removes an overlay that covers the screen.
      onAdClosed: (Ad ad) {},
      // Called when an impression occurs on the ad.
      onAdImpression: (Ad ad) {},
    );
    bannerAd = BannerAd(
      adUnitId: AdManager.unitIdList[0],
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
    bannerAd.load();
  }

  Future<void> changePassword() async {
    if (!OpenTreeHoleRepository.getInstance().isAdmin) return;
    String? email = await Noticing.showInputDialog(context, "Input email");
    String? password =
        await Noticing.showInputDialog(context, "Input password");
    if ((email ?? "").isEmpty || (password ?? "").isEmpty) return;

    int? result = await OpenTreeHoleRepository.getInstance()
        .adminChangePassword(email!, password!);
    if (result != null && result < 300) {
      Noticing.showModalNotice(context,
          message: S.of(context).operation_successful);
    }
  }

  @override
  Widget build(BuildContext context) => PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar:
            PlatformAppBarX(title: Text(S.of(context).diagnostic_information)),
        body: WithScrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            primary: true,
            child: Column(
              children: [
                PlatformElevatedButton(
                  child: const Text("Password Change [Only ADMIN]"),
                  onPressed: changePassword,
                ),
                ChangeNotifierProvider.value(
                    value: _console,
                    child: Consumer<StringBufferNotifier>(
                        builder: (context, value, child) =>
                            Text(value.toString()))),
              ],
            ),
          ),
          controller: PrimaryScrollController.of(context),
        ),
      );
}

typedef DiagnosticMethod = Future<void> Function();

/// A mixin of [StringBuffer] with [ChangeNotifier].
class StringBufferNotifier with ChangeNotifier {
  final StringBuffer _buffer = StringBuffer();

  int get length => _buffer.length;

  /// Returns whether the buffer is empty. This is a constant-time operation.
  bool get isEmpty => length == 0;

  /// Returns whether the buffer is not empty. This is a constant-time
  /// operation.
  bool get isNotEmpty => !isEmpty;

  /// Adds the string representation of [object] to the buffer.
  void write(Object? object) {
    _buffer.write(object);
    notifyListeners();
  }

  /// Adds the string representation of [charCode] to the buffer.
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
    notifyListeners();
  }

  /// Writes all [objects] separated by [separator].
  ///
  /// Writes each individual object in [objects] in iteration order,
  /// and writes [separator] between any two objects.
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _buffer.writeAll(objects, separator);
    notifyListeners();
  }

  void writeln([Object? obj = ""]) {
    _buffer.writeln(obj);
    notifyListeners();
  }

  /// Clears the string buffer.
  void clear() {
    _buffer.clear();
    notifyListeners();
  }

  /// Returns the contents of buffer as a single string.
  String toString() => _buffer.toString();
}
