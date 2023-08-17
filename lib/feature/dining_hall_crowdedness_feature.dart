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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/data_center_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:dan_xi/widget/libraries/small_tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiningHallCrowdednessFeature extends Feature {
  PersonInfo? _info;
  Map<String, TrafficInfo>? _trafficInfo;
  String? _leastCrowdedCanteen;
  String? _mostCrowdedCanteen;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadCrowdednessSummary(PersonInfo? info) async {
    Campus preferredCampus = SettingsProvider.getInstance().campus;
    try {
      _trafficInfo = await DataCenterRepository.getInstance()
          .getCrowdednessInfo(info, preferredCampus.index);
      generateSummary(preferredCampus);
    } on UnsuitableTimeException {
      _status = ConnectionStatus.FATAL_ERROR;
    } catch (e) {
      _status = ConnectionStatus.FAILED;
    }
    notifyUpdate();
  }

  void generateSummary(Campus preferredCampus) {
    if (_trafficInfo != null) {
      if (preferredCampus == Campus.HANDAN_CAMPUS) {
        var crowdednessSum = List<num>.filled(5, 0);
        /* About crowdedness List
         Index 0：北区
         Index 1：南区
         Index 2：旦苑
         Index 3：南苑
         Index 4：南区教工
       */
        // Map<String, Map<String, TrafficInfo>> zoneList =
        //     DiningHallCrowdednessRepository.getInstance()
        //         .toZoneList(preferredCampus.displayTitle(context), _trafficInfos);
        _trafficInfo!.forEach((keyUnprocessed, value) {
          if (value.current != 0) {
            //Ignore zero entries
            var keyList = keyUnprocessed.split('-');
            var key = keyList[0];
            var keySubtitle = '';
            if (keyList.length > 1) keySubtitle = keyList[1];
            switch (key) {
              case '北区':
              case '北区食堂':
                crowdednessSum[0] += value.current / value.max;
                break;
              case '南区':
              case '南区食堂':
                if (keySubtitle == '') {
                  crowdednessSum[1] += value.current / value.max;
                } else {
                  switch (keySubtitle) {
                    case '南苑餐厅':
                    case '南苑餐厅(东大)':
                      crowdednessSum[3] += value.current / value.max;
                      break;
                    case '教工快餐':
                    case '教工快餐(东大)':
                      crowdednessSum[4] += value.current / value.max;
                      break;
                    default:
                      crowdednessSum[1] += value.current / value.max;
                  }
                }
                break;
              case '旦苑':
                crowdednessSum[2] += value.current / value.max;
                break;
            }
          }
        });
        switch (crowdednessSum.indexOf(crowdednessSum.reduce(max))) {
          case 0:
            _mostCrowdedCanteen = '北区餐厅';
            break;
          case 1:
            _mostCrowdedCanteen = '南区餐厅';
            break;
          case 2:
            _mostCrowdedCanteen = '旦苑餐厅';
            break;
          case 3:
            _mostCrowdedCanteen = '南苑餐厅';
            break;
          case 4:
            _mostCrowdedCanteen = '南区教工餐厅';
            break;
          default:
            _mostCrowdedCanteen = 'NULL';
        }
        switch (crowdednessSum.indexOf(crowdednessSum.reduce(min))) {
          case 0:
            _leastCrowdedCanteen = '北区餐厅';
            break;
          case 1:
            _leastCrowdedCanteen = '南区餐厅';
            break;
          case 2:
            _leastCrowdedCanteen = '旦苑餐厅';
            break;
          case 3:
            _leastCrowdedCanteen = '南苑餐厅';
            break;
          case 4:
            _leastCrowdedCanteen = '南区教工餐厅';
            break;
          default:
            _leastCrowdedCanteen = 'NULL';
        }
      } else {
        Map<String, double> crowdedness = {};
        _trafficInfo!.forEach((key, value) {
          if (value.current != 0) crowdedness[key] = value.current / value.max;
        });
        _mostCrowdedCanteen = crowdedness.keys.firstWhere(
            (element) => crowdedness[element] == crowdedness.values.reduce(max),
            orElse: () => 'null');
        _leastCrowdedCanteen = crowdedness.keys.firstWhere(
            (element) => crowdedness[element] == crowdedness.values.reduce(min),
            orElse: () => 'null');
      }
      _status = ConnectionStatus.DONE;
    } else {
      _status = ConnectionStatus.FAILED;
    }
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    _info = StateProvider.personInfo.value;
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _status = ConnectionStatus.CONNECTING;
      _trafficInfo = null;
      _mostCrowdedCanteen = "";
      _leastCrowdedCanteen = "";
      _loadCrowdednessSummary(_info);
    }
  }

  @override
  String get mainTitle => S.of(context!).dining_hall_crowdedness;

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.DONE:
        if (_mostCrowdedCanteen != null && _leastCrowdedCanteen != null) {
          return S.of(context!).most_least_crowded_canteen(
              _mostCrowdedCanteen!, _leastCrowdedCanteen!);
        }
        return '';
      case ConnectionStatus.FAILED:
        return S.of(context!).failed;
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).out_of_dining_time;
    }
  }

  @override
  Wrap? get customSubtitle {
    if (_status == ConnectionStatus.DONE) {
      return Wrap(
        children: [
          SmallTag(
            label: S.of(context!).tag_most_crowded,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            _mostCrowdedCanteen!,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 1,
          ),
          const SizedBox(
            width: 6,
          ),
          SmallTag(
            label: S.of(context!).tag_least_crowded,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            _leastCrowdedCanteen!,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            maxLines: 1,
          ),
        ],
      );
    }
    return null;
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.stacked_line_chart)
      : const Icon(CupertinoIcons.person_3_fill);

  @override
  Widget? get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return const FeatureProgressIndicator();
    }
    return null;
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_trafficInfo != null) {
      smartNavigatorPush(context!, "/card/crowdData");
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
