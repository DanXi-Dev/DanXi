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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:flutter/material.dart';
import 'package:lunar/calendar/Lunar.dart';

class WelcomeFeature extends Feature {
  PersonInfo? _info;

  /// A sentence to show welcome to users depending on the time.
  String _helloQuote = "";

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    _info = StateProvider.personInfo.value;

    try {
      var lunarFestivals = Lunar.fromDate(DateTime.now()).getFestivals();
      String days = Constant.SPECIAL_DAYS.keys
          .firstWhere((key) => lunarFestivals.contains(key));
      _helloQuote = Constant.SPECIAL_DAYS[days]![
          Random().nextInt(Constant.SPECIAL_DAYS[days]!.length)];
      return;
    } catch (ignored) {}
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
  String get mainTitle => S.of(context!).welcome(_info?.name ?? "?");

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
}
