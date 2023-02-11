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

// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floors.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/model/pair.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/language_manager.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/opentreehole/human_duration.dart';
import 'package:flutter/painting.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _OTHoleIsolateRenderableType {
  /// Render a list of [OTHole]s.
  RenderHoleList,

  /// Render a list of JSON objects.
  RenderJsonList,
}

class OTHoleRenderable extends OTHole {
  String humanReadableCreatedTime;
  String humanReadableLastRepliedTime;
  String renderedFirstFloorText;
  String renderedLastFloorText;

  static IsolateManager<List<OTHoleRenderable>?>? _isolateManager;

  /// Parse a list of JSON objects into a list of [OTHoleRenderable]s,
  /// and return the list.
  ///
  /// This method will be executed in a background isolate.
  @pragma("vm:entry-point")
  static Future<void> _isolateParsing(dynamic params) async {
    final controller =
        IsolateManagerController<List<OTHoleRenderable>?>(params);

    // Get initialParams.
    // Notice that this `initialParams` different from the `params` above.
    final initialParams = controller.initialParams as Map<String, dynamic>;
    final preferences = initialParams["pref"] as SharedPreferences;
    final locale = initialParams["locale"] as Locale;

    SettingsProvider.getInstance().preferences = preferences;
    await S.load(locale);

    // Listen to the message receiving from main isolate, this area of code will be called each time
    // you use `compute` or `sendMessage`.
    controller.onIsolateMessage.listen((message) {
      try {
        final type =
            (message as Pair<_OTHoleIsolateRenderableType, dynamic>).first;
        final data = message.second;
        switch (type) {
          case _OTHoleIsolateRenderableType.RenderHoleList:
            controller.sendResult((data as List<OTHole>)
                .map((e) => OTHoleRenderable.fromOTHole(e))
                .toList());
            break;
          case _OTHoleIsolateRenderableType.RenderJsonList:
            controller.sendResult((data as List<Map<String, dynamic>>)
                .map((e) => OTHoleRenderable.fromJson(e))
                .toList());
            break;
        }
      } catch (err) {
        // fixme: send the real exception to main isolate, instead of `null`!
        controller.sendResult(null);
      }
    });
  }

  static void _ensureIsolateManager() {
    _isolateManager ??=
        IsolateManager.createOwnIsolate(_isolateParsing, initialParams: {
      "pref": SettingsProvider.getInstance().preferences,
      "locale":
          LanguageManager.toLocale(SettingsProvider.getInstance().language)
    });
  }

  /// Parse a list of JSON objects into a list of [OTHoleRenderable]s,
  /// and return the list.
  static Future<List<OTHoleRenderable>?> fromJsonList(
      List<Map<String, dynamic>> jsonList) {
    _ensureIsolateManager();
    return _isolateManager!
        .compute(Pair(_OTHoleIsolateRenderableType.RenderJsonList, jsonList));
  }

  // Parse a list of [OTHole]s into a list of [OTHoleRenderable]s,
// and return the list.
  static Future<List<OTHoleRenderable>?> fromOTHoleList(List<OTHole> holeList) {
    _ensureIsolateManager();
    return _isolateManager!
        .compute(Pair(_OTHoleIsolateRenderableType.RenderHoleList, holeList));
  }

  factory OTHoleRenderable.fromOTHole(OTHole postElement) {
    String renderedFirstFloorText = renderText(
        postElement.floors?.first_floor?.filteredContent ?? "",
        S.current.image_tag,
        S.current.formula);
    String renderedLastFloorText = renderText(
        postElement.floors?.last_floor?.filteredContent ?? "",
        S.current.image_tag,
        S.current.formula);
    String humanReadableCreatedTime = HumanDuration.tryFormat(
        DateTime.tryParse(postElement.time_created ?? "")?.toLocal());
    String humanReadableLastRepliedTime = HumanDuration.tryFormat(
        DateTime.tryParse(postElement.floors?.last_floor?.time_created ?? "")
            ?.toLocal());
    return OTHoleRenderable(
        postElement.hole_id,
        postElement.division_id,
        postElement.time_created,
        postElement.time_updated,
        postElement.tags,
        postElement.view,
        postElement.reply,
        postElement.floors,
        humanReadableCreatedTime,
        humanReadableLastRepliedTime,
        renderedFirstFloorText,
        renderedLastFloorText);
  }

  factory OTHoleRenderable.fromJson(Map<String, dynamic> json) {
    OTHole hole = OTHole.fromJson(json);
    return OTHoleRenderable.fromOTHole(hole);
  }

  factory OTHoleRenderable.dummy() =>
      OTHoleRenderable.fromOTHole(OTHole.dummy());

  OTHoleRenderable(
      int? hole_id,
      int? division_id,
      String? time_created,
      String? time_updated,
      List<OTTag>? tags,
      int? view,
      int? reply,
      OTFloors? floors,
      this.humanReadableCreatedTime,
      this.humanReadableLastRepliedTime,
      this.renderedFirstFloorText,
      this.renderedLastFloorText)
      : super(hole_id, division_id, time_created, time_updated, tags, view,
            reply, floors);
}
