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

import 'package:otp/otp.dart';
import 'package:base32/base32.dart';

class Secret {
  static const APP_ID = "";
  static const API_KEY = "";

  /// The api key to register/login FDUHole.
  static const String FDUHOLE_API_KEY = "";
  static generateOneTimeAPIKey() {
    return OTP.generateTOTPCodeString(base32.encodeString(FDUHOLE_API_KEY),
        DateTime.now().millisecondsSinceEpoch,
        length: 16, interval: 5, isGoogle: true);
  }

  /// One unit id for each Ad placement.
  /// Respectively, Dashboard, TreeHole, Agenda, Settings.
  static const List<String> ADMOB_UNIT_ID_LIST_ANDROID = [
    "",
    "",
    "",
    "",
  ];
  static const List<String> ADMOB_UNIT_ID_LIST_IOS = [
    "",
    "",
    "",
    "",
  ];
}
