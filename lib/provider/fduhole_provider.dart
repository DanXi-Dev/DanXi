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

import 'package:collection/collection.dart';
import 'package:dan_xi/model/opentreehole/division.dart';
import 'package:dan_xi/model/opentreehole/jwt.dart';
import 'package:dan_xi/model/opentreehole/user.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/opentreehole/editor_object.dart';
import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that exports some global states about FDUHole to the app.
///
/// Also see:
/// * [StateProvider]
class FDUHoleProvider with ChangeNotifier {
  static late FDUHoleProvider _instance;

  factory FDUHoleProvider.getInstance() => _instance;

  static void init(FDUHoleProvider injectProvider) {
    _instance = injectProvider;
  }

  FDUHoleProvider();

  /// Caches of [OTEditor].
  final Map<EditorObject?, PostEditorText> editorCache = {};

  final Map<String?, CourseReviewEditorText> courseReviewEditorCache = {};

  /// The current division id;
  int? divisionId;

  OTDivision? get currentDivision => _divisionCache
      .firstWhereOrNull((element) => element.division_id == divisionId);

  set currentDivisionId(int? divisionId) {
    this.divisionId = divisionId;
    notifyListeners();
  }

  /// The token used for session authentication.
  ///
  /// Note: changing this will NOT trigger any notification.
  JWToken? token;

  /// Current user profile, stored as cache by the repository
  OTUser? _userInfo;

  OTUser? get userInfo => _userInfo;

  set userInfo(OTUser? value) {
    _userInfo = value;
    notifyListeners();
  }

  /// Cached OTDivisions.
  ///
  /// Note: DO NOT call modify methods on this list, as it will not trigger
  /// the listeners!
  List<OTDivision> _divisionCache = List.empty(growable: false);

  List<OTDivision> get divisionCache => _divisionCache;

  set divisionCache(List<OTDivision> value) {
    _divisionCache = List.unmodifiable(value);
    notifyListeners();
  }

  /// Whether the user has logged in and we have fetched his/her profile.
  bool get isUserInitialized => token != null && userInfo != null;
}
