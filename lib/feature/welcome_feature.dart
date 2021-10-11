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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:flutter/material.dart';

class WelcomeFeature extends Feature {
  PersonInfo? _info;

  /// A sentence to show welcome to users depending on the time.
  String _helloQuote = "";

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    _info = StateProvider.personInfo.value;
    int time = DateTime.now().hour;
    if (time >= 23 || time <= 4) {
      _helloQuote = S.of(context!)!.late_night;
    } else if (time >= 5 && time <= 8) {
      _helloQuote = S.of(context!)!.good_morning;
    } else if (time >= 9 && time <= 11) {
      _helloQuote = S.of(context!)!.good_noon;
    } else if (time >= 12 && time <= 16) {
      _helloQuote = S.of(context!)!.good_afternoon;
    } else if (time >= 17 && time <= 22) {
      _helloQuote = S.of(context!)!.good_night;
    }
  }

  @override
  String get mainTitle => S.of(context!)!.welcome(_info?.name);

  @override
  String get subTitle => _helloQuote;

  @override
  Widget? get customSubtitle {
    if (SettingsProvider.getInstance().debugMode)
      return Text(
        "Welcome, developer. [Debug Mode Enabled]",
        style: TextStyle(color: Colors.red),
      );
    return null;
  }
}
