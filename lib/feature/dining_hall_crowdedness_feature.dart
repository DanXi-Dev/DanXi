/*
 *     Copyright (C) 2021  w568w
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
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/dining_hall_crowdedness_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiningHallCrowdednessFeature extends Feature {
  PersonInfo _info;
  Map<String, TrafficInfo> _trafficInfos;
  String _leastCrowdedCanteen;
  String _mostCrowdedCanteen;
  SharedPreferences _preferences;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadCrowdednessSummary(PersonInfo info) async {
    _status = ConnectionStatus.CONNECTING;
    Campus preferredCampus = SettingsProvider.of(_preferences).campus;
    _trafficInfos = await DiningHallCrowdednessRepository.getInstance()
        .getCrowdednessInfo(info, preferredCampus.index)
        .catchError((e) {
      if (e is UnsuitableTimeException) {
        // If it's not time for a meal
        _status = ConnectionStatus.FATAL_ERROR;
      }
    });
    if (_status != ConnectionStatus.FATAL_ERROR)
      generateSummary(preferredCampus);
    notifyUpdate();
  }

  void generateSummary(Campus preferredCampus) {
    //TODO: DUE TO THE FACT THAT I'M NOT FAMILIAR WITH DART'S SYNTAX, THE FOLLOWING CODE IS SOMEHOW *STUPID* AND HAS HARDCODED CONTENTS. REVISE WHEN POSSIBLE
    if (_trafficInfos != null) {
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
        _trafficInfos.forEach((keyUnprocessed, value) {
          if (value.current != 0) {
            //Ignore zero entries
            var key = keyUnprocessed.split('\n')[0];
            var keySubtitle = '';
            if (keyUnprocessed.length > 1)
              keySubtitle = keyUnprocessed.split('\n')[1];
            switch (key) {
              case '北区':
                crowdednessSum[0] += value.current / value.max;
                break;
              case '南区':
                if (keySubtitle == '') {
                  crowdednessSum[1] += value.current / value.max;
                } else {
                  switch (keySubtitle) {
                    case '南苑餐厅':
                      //WARNING: Workaround defective data
                      //crowdednessSum[3] += value.current / value.max;
                      break;
                    case '教工快餐':
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
        crowdednessSum[3] = 9999; //WARNING: Workaround defective data
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
        var crowdedness = new Map<String, double>();
        _trafficInfos.forEach((key, value) {
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
  void buildFeature() {
    _info = context.personInfo;
    _preferences = Provider.of<SharedPreferences>(context);
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _trafficInfos = null;
      _mostCrowdedCanteen = "";
      _leastCrowdedCanteen = "";
      _loadCrowdednessSummary(_info).catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context).dining_hall_crowdedness;

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context).loading;
      case ConnectionStatus.DONE:
        if (_mostCrowdedCanteen != null && _leastCrowdedCanteen != null)
          return S.of(context).most_least_crowded_canteen(
              _mostCrowdedCanteen, _leastCrowdedCanteen);
        return '';
      case ConnectionStatus.FAILED:
        return S.of(context).failed;
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context).out_of_dining_time;
    }
    return '';
  }

  @override
  Row get customSubtitle {
    if (_status == ConnectionStatus.DONE) {
      return Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(4.0))),
            child: Text(
              S.of(context).tag_most_crowded,
              style: TextStyle(
                  color: Theme.of(context).hintColor.computeLuminance() >= 0.5
                      ? Colors.black
                      : Colors.white,
                  fontSize: 12),
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          Text(_mostCrowdedCanteen),
          const SizedBox(
            width: 7,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withOpacity(0.3),
                borderRadius: BorderRadius.all(Radius.circular(4.0))),
            child: Text(
              S.of(context).tag_least_crowded,
              style: TextStyle(
                  color: Theme.of(context).hintColor.computeLuminance() >= 0.5
                      ? Colors.black
                      : Colors.white,
                  fontSize: 12),
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            _leastCrowdedCanteen,
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
  Widget get icon => PlatformX.isAndroid
      ? const Icon(Icons.stacked_line_chart)
      : const Icon(SFSymbols.person_3_fill);

  @override
  Widget get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return ScaleTransform(
        scale: 0.5,
        child: CircularProgressIndicator(),
      );
    }
    return null;
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_trafficInfos != null) {
      Navigator.of(context)
          .pushNamed("/card/crowdData", arguments: {"personInfo": _info});
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
