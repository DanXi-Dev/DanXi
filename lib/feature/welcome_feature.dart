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
  ConnectionStatus _status = ConnectionStatus.NONE;

  /// A list of card details.
  ///
  /// We only use them to determine whether the user has entry permission to the campus.
  List<CardDetailInfo>? _cardInfos;

  Future<void> _loadCardStatus() async {
    _status = ConnectionStatus.CONNECTING;
    _cardInfos = await DataCenterRepository.getInstance()
        .getCardDetailInfo(StateProvider.personInfo.value);
    _status = ConnectionStatus.DONE;
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

    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadCardStatus().catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

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
    String _infoText;
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        status = ScaleTransform(
            scale: PlatformX.isMaterial(context!) ? 0.5 : 1.0,
            child: PlatformCircularProgressIndicator());
        _infoText = "";
        break;
      case ConnectionStatus.DONE:
        if (_cardInfos?.any((element) => !element.permission.contains("是")) ??
            false) {
          status = Icon(
            PlatformX.isMaterial(context!)
                ? Icons.block
                : CupertinoIcons.xmark_circle,
            color: Theme.of(context!).errorColor,
          );
          _infoText = S.of(context!).abnormal_entry_permission;
        } else {
          status = Icon(
            PlatformX.isMaterial(context!)
                ? Icons.verified
                : CupertinoIcons.checkmark_alt_circle,
            color: Colors.green,
          );
          _infoText = S.of(context!).everything_is_ok;
        }
        break;
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        status = const Icon(Icons.error);
        _infoText = S.of(context!).failed;
        break;
    }

    return InkWell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          status,
          /*if (_infoText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(_infoText, textScaleFactor: 0.8)
          ]*/
          const SizedBox(height: 2),
          Text(S.of(context!).entry_permission, textScaleFactor: 0.8)
        ],
      ),
      onTap: () {
        switch (_status) {
          case ConnectionStatus.NONE:
          case ConnectionStatus.CONNECTING:
            break;
          case ConnectionStatus.DONE:
            Noticing.showModalNotice(context!,
                title: S.of(context!).entry_permission,
                message: _cardInfos!.isEmpty
                    ? S.of(context!).no_data
                    : _cardInfos!.map((e) => e.permission).join("\n"));
            break;
          case ConnectionStatus.FAILED:
          case ConnectionStatus.FATAL_ERROR:
            _status = ConnectionStatus.NONE;
            notifyUpdate();
            break;
        }
      },
    );
  }
}
