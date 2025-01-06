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
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/bus_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/vague_time.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';

class BusFeature extends Feature {
  ConnectionStatus _status = ConnectionStatus.NONE;

  /// The bus schedules retrieved.
  List<BusScheduleItem>? _busList;

  bool? isHoliday;

  @override
  Widget get icon => Icon(PlatformIcons(context!).bus);

  @override
  String get mainTitle => S.of(context!).bus_query;

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    isHoliday = isTodayHoliday();
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadBusList(StateProvider.personInfo.value).catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  bool isTodayHoliday() {
    final today = DateTime.now().weekday;
    return (today == DateTime.sunday) || (today == DateTime.saturday);
  }

  _loadBusList(PersonInfo? personInfo) async {
    _status = ConnectionStatus.CONNECTING;
    _busList = await FudanBusRepository.getInstance()
        .loadBusList(personInfo, holiday: isHoliday!);
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.DONE:
        return S.of(context!).no_matching_bus;
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).failed;
    }
  }

  @override
  Widget? get customSubtitle {
    if (_status == ConnectionStatus.DONE && _busList != null) {
      return buildSubtitle(
          nextBusForCampus(SettingsProvider.getInstance().campus));
    }
    return null;
  }

  Widget? buildSubtitle(BusScheduleItem? element) {
    if (element == null) return null;
    Campus? from, to;
    switch (element.direction) {
      case BusDirection.NONE:
        break;
      case BusDirection.BACKWARD:
        from = element.end;
        to = element.start;
        break;
      case BusDirection.DUAL:
      case BusDirection.FORWARD:
        from = element.start;
        to = element.end;
        break;
    }
    String connectChar = element.direction == BusDirection.DUAL
        ? BusDirectionExtension.DUAL_ARROW
        : BusDirectionExtension.FORWARD_ARROW;
    return Wrap(
      children: [
        Text(
          "${DateFormat("HH:mm").format(element.realStartTime!.toExactTime())} "
          "${from.displayTitle(context!)}"
          "$connectChar"
          "${to.displayTitle(context!)}",
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          maxLines: 1,
        )
      ],
    );
  }

  BusScheduleItem? nextBusForCampus(Campus campus) {
    // Split dual-direction bus with different start times into two single-direction buses to avoid confusion.
    final List<BusScheduleItem> filteredBusList = _busList!
        .where((element) => (element.start == campus || element.end == campus))
        .expand(((element) => (element.direction == BusDirection.DUAL &&
                !element.startTime!
                    .toExactTime()
                    .isAtSameMomentAs(element.endTime!.toExactTime()))
            ? [
                element.copyWith(direction: BusDirection.FORWARD),
                BusScheduleItem.reversed(element)
                    .copyWith(direction: BusDirection.FORWARD)
              ]
            : [element]))
        .toList();
    // Get the next bus time
    filteredBusList.sort();
    for (var element in filteredBusList) {
      VagueTime? startTime = element.realStartTime;
      if (startTime != null &&
          startTime.toExactTime().isAfter(DateTime.now())) {
        return element;
      }
    }
    if (filteredBusList.isEmpty) return null;
    return filteredBusList.first;
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_busList != null) {
      smartNavigatorPush(context!, "/bus/detail",
          arguments: {"busList": _busList, "dataIsHoliday": isHoliday});
    } else {
      refreshData();
    }
  }

  @override
  Widget? get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return const FeatureProgressIndicator();
    }
    return null;
  }

  @override
  bool get clickable => true;
}
