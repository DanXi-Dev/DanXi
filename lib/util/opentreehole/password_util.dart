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

class PasswordUtil {
  static const String NORMAL_CHARACTERS =
      "qwertyuiopasdfghjklzxcvbnm1234567890";

  static String generateNormalPassword(int length) {
    String result = "";
    Random rand = Random.secure();
    for (int i = 0; i < length; i++) {
      result += NORMAL_CHARACTERS[rand.nextInt(NORMAL_CHARACTERS.length)];
    }
    return result;
  }
}
