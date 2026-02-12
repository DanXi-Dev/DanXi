/*
 *     Copyright (C) 2021  DanXi-Dev
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

import 'dart:math';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/data_center_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/scale_transform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class WelcomeFeature extends Feature {
  /// A list of card details.
  ///
  /// We only use them to determine whether the user has entry permission to the campus.
  List<CardDetailInfo>? _cardInfos;

  Future<void> _loadCardStatus() async {
    status = const ConnectionConnecting();
    _cardInfos = await DataCenterRepository.getInstance().getCardDetailInfo();
    status = const ConnectionDone();
    notifyUpdate();
  }

  /// A sentence to show welcome to user, depending on the time and date.
  String _helloQuote = "";

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    try {
      List<String> celebrationWords = [];
      for (var celebration in SettingsProvider.getInstance().celebrationWords) {
        if (celebration.match(DateTime.now())) {
          celebrationWords.addAll(celebration.celebrationWords);
        }
      }
      if (celebrationWords.isNotEmpty) {
        // Randomly choose a celebration sentence to show.
        _helloQuote =
            celebrationWords[Random().nextInt(celebrationWords.length)];
        return;
      }
      // It is no problem if we cannot obtain a festival celebration welcome sentence.
    } catch (_) {}
    int time = DateTime.now().hour;
    if (time >= 23 || time <= 4) {
      _helloQuote = S.of(context!).late_night;
    } else if (time >= 5 && time <= 8) {
      _helloQuote = S.of(context!).good_morning;
    } else if (time >= 9 && time <= 11) {
      _helloQuote = S.of(context!).good_noon;
    } else if (time >= 12 && time <= 16) {
      _helloQuote = S.of(context!).good_afternoon;
    } else if (time >= 17 && time <= 22) {
      _helloQuote = S.of(context!).good_night;
    }
  }

  @override
  bool get loadOnTap => false;

  @override
  String get mainTitle =>
      S.of(context!).welcome(StateProvider.personInfo.value?.name ?? "?");

  @override
  String get subTitle => _helloQuote;

  @override
  Widget? get customSubtitle {
    if (SettingsProvider.getInstance().debugMode) {
      return const Text(
        "Welcome, developer. [Debug Mode Enabled]",
        style: TextStyle(color: Colors.red),
      );
    }
    return null;
  }

  @override
  Widget get trailing {
    Widget status;
    switch (this.status) {
      case ConnectionNone():
        status = Icon(
          PlatformX.isMaterial(context!)
              ? Icons.refresh
              : CupertinoIcons.refresh,
        );
        break;
      case ConnectionConnecting():
        status = PlatformCircularProgressIndicator();
        if (PlatformX.isMaterial(context!)) {
          status = SizedBox(
              width: 24,
              height: 24,
              child: ScaleTransform(scale: 0.5, child: status));
        }
        break;
      case ConnectionDone():
        if (_cardInfos?.any((element) => !element.permission.contains("是")) ??
            false) {
          status = Icon(
            PlatformX.isMaterial(context!)
                ? Icons.block
                : CupertinoIcons.xmark_circle,
            color: Theme.of(context!).colorScheme.error,
          );
        } else {
          status = Icon(
            PlatformX.isMaterial(context!)
                ? Icons.verified
                : CupertinoIcons.checkmark_alt_circle,
            color: Colors.green,
          );
        }
        break;
      case ConnectionFailed():
      case ConnectionFatalError():
        status = const Icon(Icons.error);
        break;
    }

    return InkWell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          status,
          const SizedBox(height: 2),
          Text(S.of(context!).entry_permission,
              textScaler: TextScaler.linear(0.8))
        ],
      ),
      onTap: () {
        switch (this.status) {
          case ConnectionNone():
            _loadCardStatus().catchError((error, stackTrace) {
              this.status = ConnectionFailed(error, stackTrace);
              notifyUpdate();
            });
            break;
          case ConnectionConnecting():
            break;
          case ConnectionDone():
            Noticing.showModalNotice(context!,
                title: S.of(context!).entry_permission,
                message: _cardInfos!.isEmpty
                    ? S.of(context!).no_data
                    : _cardInfos!.map((e) => e.permission).join("\n"));
            break;
          case ConnectionFailed():
          case ConnectionFatalError():
            this.status = const ConnectionNone();
            notifyUpdate();
            break;
        }
      },
    );
  }
}
