/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/generated/l10n.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';

class Constant {
  static EventBus eventBus = EventBus();
  static const String UIS_URL = "https://uis.fudan.edu.cn/authserver/login";

  static const FUDAN_DAILY_COUNTDOWN_SECONDS = 4;

  static String yuanSymbol(String num) {
    if (num == null || num.trim().isEmpty) return "";
    return '\u00A5' + num;
  }

  /// A copy of [Campus.values], omitting [Campus.NONE].
  static const CAMPUS_VALUES = [
    Campus.HANDAN_CAMPUS,
    Campus.FENGLIN_CAMPUS,
    Campus.JIANGWAN_CAMPUS,
    Campus.ZHANGJIANG_CAMPUS
  ];
}

enum Campus {
  HANDAN_CAMPUS,
  FENGLIN_CAMPUS,
  JIANGWAN_CAMPUS,
  ZHANGJIANG_CAMPUS,
  NONE
}

extension CampusEx on Campus {
  String displayTitle(BuildContext context) {
    switch (this) {
      case Campus.HANDAN_CAMPUS:
        return S.of(context).handan_campus;
        break;
      case Campus.FENGLIN_CAMPUS:
        return S.of(context).fenglin_campus;
        break;
      case Campus.JIANGWAN_CAMPUS:
        return S.of(context).jiangwan_campus;
        break;
      case Campus.ZHANGJIANG_CAMPUS:
        return S.of(context).zhangjiang_campus;
        break;
      // Select area when it's none
      case Campus.NONE:
        return S.of(context).choose_area;
        break;
    }
    return null;
  }
}

enum ConnectionStatus { NONE, CONNECTING, DONE, FAILED, FATAL_ERROR }
