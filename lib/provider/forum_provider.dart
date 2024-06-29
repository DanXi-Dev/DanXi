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
import 'package:dan_xi/model/forum/division.dart';
import 'package:dan_xi/model/forum/jwt.dart';
import 'package:dan_xi/model/forum/user.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/page/forum/hole_editor.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/forum/editor_object.dart';
import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that exports some global states about the forum to the app.
///
/// Also see:
/// * [StateProvider]
class ForumProvider with ChangeNotifier {
  static late ForumProvider _instance;

  factory ForumProvider.getInstance() => _instance;

  static void init(ForumProvider injectProvider) {
    _instance = injectProvider;
  }

  ForumProvider();

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
