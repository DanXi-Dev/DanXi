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

import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/sports_reserve_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// This is an app-specific test class.
/// You can write your feature-testing codes here, without worrying about whether
/// [StateProvider] and [SettingsProvider] have been initialized.
class _TestLifeCycle {
  /// When app completes initialization of [StateProvider] and [SettingsProvider],
  /// the [context] is from [HomePage].
  static void onStart(BuildContext context) {
    /// TEST CODE
  }

  static void onStartAsync(BuildContext context) async {
    await SportsReserveRepository.getInstance()
        .getStadiumList(StateProvider.personInfo.value);
  }
}

/// Don't modify this class. It should be invoked only by the app.
class TestLifeCycle {
  static void onStart(BuildContext context) {
    if (kDebugMode) {
      _TestLifeCycle.onStartAsync(context);
      _TestLifeCycle.onStart(context);
    }
  }
}
