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
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Constant {
  static const bool IS_PRODUCTION_ENVIRONMENT =
      bool.fromEnvironment('dart.vm.product');

  static EventBus eventBus = EventBus();
  static const String UIS_URL = "https://uis.fudan.edu.cn/authserver/login";

  static const FUDAN_DAILY_COUNTDOWN_SECONDS = 5;

  static String yuanSymbol(String num) {
    if (num == null || num.trim().isEmpty) return "";
    return '\u00A5' + num;
  }

  static ThemeData lightTheme(bool isCupertino) {
    if (isCupertino) {
      return ThemeData(
        brightness: Brightness.light,
        accentColor: Color(0xFF007AFF),
        cardTheme: CardTheme(
          margin: EdgeInsets.fromLTRB(10,8,10,8),
          elevation: 5,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: Color(0xFF007AFF)),
        ),
      );
    }
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      cardTheme: CardTheme(
        margin: EdgeInsets.fromLTRB(10,8,10,8),
      ),
    );
  }

  static ThemeData darkTheme(bool isCupertino) {
    if (isCupertino) {
      return ThemeData(
        brightness: Brightness.dark,
        accentColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Colors.black,
        backgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(),
        cardTheme: CardTheme(
          margin: EdgeInsets.fromLTRB(10,8,10,8),
          elevation: 5,
          color: Color.fromRGBO(28, 28, 30, 1.0),
          //shadowColor: Color.fromRGBO(28, 28, 30, 50),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: Color(0xFF007AFF)),
        ),
        canvasColor: Colors.black,
        dialogBackgroundColor: Color.fromRGBO(28, 28, 30, 1.0),
      );
    }
    return ThemeData(
      brightness: Brightness.dark,
      cardTheme: CardTheme(
        margin: EdgeInsets.fromLTRB(10,8,10,8),
      ),
    );
  }

  static Color getColorFromString(String color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'deep-purple':
        return Colors.deepPurple;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      case 'light-blue':
        return Colors.lightBlue;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'light-green':
        return Colors.lightGreen;
      case 'lime':
        return Colors.lime;
      case 'yellow':
        return Colors.yellow;
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'deep-orange':
        return Colors.deepOrange;
      case 'brown':
        return Colors.brown;
      case 'blue-grey':
        return Colors.blueGrey;
      case 'grey':
        return Colors.grey;
    }
    return Colors.black;
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
  List<String> getTeachingBuildings() {
    switch (this) {
      case Campus.HANDAN_CAMPUS:
        return ['HGX', 'H2', 'H3', 'H4', 'H5', 'H6'];
        break;
      case Campus.FENGLIN_CAMPUS:
        return ['F1', 'F2'];
        break;
      case Campus.JIANGWAN_CAMPUS:
        return ['JA', 'JB'];
        break;
      case Campus.ZHANGJIANG_CAMPUS:
        return ['Z2'];
        break;
      case Campus.NONE:
        break;
    }
    return null;
  }

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
