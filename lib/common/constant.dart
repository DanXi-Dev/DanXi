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

import 'package:event_bus/event_bus.dart';

class Constant {
  static const campusArea = ['邯郸校区', '枫林校区', '江湾校区', '张江校区'];
  static EventBus eventBus = EventBus();
  static const String UIS_URL = "https://uis.fudan.edu.cn/authserver/login";

  /* SharedPrefs Campus
   * Key: campus
   * Has 4 values: handan_campus, fenglin_campus, jiangwan_campus, zhangjiang_campus
   */
  static const String HANDAN_CAMPUS = 'handan_campus';
  static const String FENGLIN_CAMPUS = 'fenglin_campus';
  static const String JIANGWAN_CAMPUS = 'jiangwan_campus';
  static const String ZHANGJIANG_CAMPUS = 'zhangjiang_campus';

  static String yuanSymbol(String num) {
    if (num == null || num.trim().isEmpty) return "";
    return '\u00A5' + num;
  }
}

enum ConnectionStatus { NONE, CONNECTING, DONE, FAILED, FATAL_ERROR }
