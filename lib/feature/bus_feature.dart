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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/fudan_bus_repository.dart';
import 'package:dan_xi/util/vague_time.dart';
import 'package:dan_xi/widget/small_tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';

class BusFeature extends Feature {
  static const _FORWARD_ARROW = " → ";
  static const _DUAL_ARROW = " ↔ ";
  ConnectionStatus _status = ConnectionStatus.NONE;
  List<BusScheduleItem> _busList;

  @override
  Widget get icon => Icon(PlatformIcons(context).bus);

  @override
  String get mainTitle => S.of(context).bus_query;

  @override
  void buildFeature([Map<String, dynamic> arguments]) {
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadBusList(context.personInfo).catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  _loadBusList(PersonInfo personInfo) async {
    _status = ConnectionStatus.CONNECTING;
    _busList = await FudanBusRepository.getInstance().loadBusList(personInfo);
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context).loading;
      // if _busList != null, subTitle will be [customSubtitle] rather than [subTitle] here,
      // so [ConnectionStatus.DONE] here is same as FAILED or FATAL_ERROR.
      case ConnectionStatus.DONE:
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context).failed;
    }
    return '';
  }

  @override
  Widget get customSubtitle {
    if (_status == ConnectionStatus.DONE && _busList != null) {
      _busList.forEach((element) {
        if (element.realStartTime == null) {
          debugPrint(element.id);
        }
      });
      // Get the next bus time
      _busList.sort();
      for (var element in _busList) {
        VagueTime startTime = element.realStartTime;
        if (startTime != null &&
            startTime.toExactTime().isAfter(DateTime.now())) {
          return buildSubtitle(element);
        }
      }
      return buildSubtitle(_busList.first);
    }
    return null;
  }

  Widget buildSubtitle(BusScheduleItem element) {
    Campus from, to;
    switch (element.direction) {
      case BusDirection.NONE:
        break;
      case BusDirection.DUAL:
      case BusDirection.BACKWARD:
        from = element.end;
        to = element.start;
        break;
      case BusDirection.FORWARD:
        from = element.start;
        to = element.end;
        break;
    }
    String connectChar =
        element.direction == BusDirection.DUAL ? _DUAL_ARROW : _FORWARD_ARROW;
    return Wrap(
      children: [
        SmallTag(
          label: S.of(context).next_bus,
        ),
        const SizedBox(
          width: 6,
        ),
        Text(
          "${DateFormat("HH:mm").format(element.realStartTime.toExactTime())} "
          "${from.displayTitle(context)}"
          "$connectChar"
          "${to.displayTitle(context)}",
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          maxLines: 1,
        )
      ],
    );
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_busList != null) {
      // TODO
      // smartNavigatorPush(context, "/card/crowdData",
      //     arguments: {"personInfo": context.personInfo});
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
