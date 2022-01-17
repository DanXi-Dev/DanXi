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

import 'package:dan_xi/model/person.dart';
import 'package:flutter/cupertino.dart';

/// Manage global states of the app.
///
/// Code structural warning: You should ONLY directly refer to this class in the codes of
/// Application layer, rather than in Util, Model or Repository. Do NOT touch the decoupling
/// of this project!
class StateProvider {
  StateProvider() {
    throw UnimplementedError();
  }

  /// The user's basic information.
  static final ValueNotifier<PersonInfo> personInfo = ValueNotifier(null);
}
