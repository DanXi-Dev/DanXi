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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floors.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/util/opentreehole/human_duration.dart';

class OTHoleRenderable extends OTHole {
  String humanReadableCreatedTime;
  String humanReadableLastRepliedTime;
  String renderedFirstFloorText;
  String renderedLastFloorText;

  factory OTHoleRenderable.fromOTHole(OTHole postElement) {
    String renderedFirstFloorText = renderText(
        postElement.floors!.first_floor!.filteredContent!,
        S.current.image_tag,
        S.current.formula);
    String renderedLastFloorText = renderText(
        postElement.floors!.last_floor!.filteredContent!,
        S.current.image_tag,
        S.current.formula);
    String humanReadableCreatedTime = HumanDuration.tryFormat(
        DateTime.parse(postElement.time_created!).toLocal());
    String humanReadableLastRepliedTime = HumanDuration.tryFormat(
        DateTime.parse(postElement.floors!.last_floor!.time_created!)
            .toLocal());
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
