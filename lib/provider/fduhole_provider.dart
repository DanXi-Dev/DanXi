/*
 *     Copyright (C) 2022  DanXi-Dev
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

import 'package:dan_xi/model/opentreehole/division.dart';
import 'package:dan_xi/model/opentreehole/user.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/opentreehole/editor_object.dart';
import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that exports some global states about FDUHole to the app.
///
/// Also see:
/// * [StateProvider]
class FDUHoleProvider with ChangeNotifier {
  /// Caches of [OTEditor].
  final Map<EditorObject?, PostEditorText> editorCache = {};

  /// The current division.
  OTDivision? _currentDivision;

  OTDivision? get currentDivision => _currentDivision;

  set currentDivision(OTDivision? currentDivision) {
    _currentDivision = currentDivision;
    notifyListeners();
  }

  /// The token used for session authentication.
  ///
  /// Note: changing this will NOT trigger any notification.
  String? token;

  /// Current user profile, stored as cache by the repository
  OTUser? _userInfo;

  OTUser? get userInfo => _userInfo;

  set userInfo(OTUser? value) {
    _userInfo = value;
    notifyListeners();
  }

  bool get isUserInitialized => token != null && userInfo != null;
}
