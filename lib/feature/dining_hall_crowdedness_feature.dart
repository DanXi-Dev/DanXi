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
    _trafficInfos = await DiningHallCrowdednessRepository.getInstance()
        .getCrowdednessInfo(
            info, SettingsProvider.of(_preferences).campus.index)
        .catchError((e) {
      if (e is UnsuitableTimeException) {
        _status = ConnectionStatus.FATAL_ERROR;
      }
    });

    //TODO: DUE TO THE FACT THAT I'M NOT FAMILIAR WITH DART'S SYNTAX, THE FOLLOWING CODE IS SOMEHOW *STUPID* AND HAS HARDCODED CONTENTS. REVISE WHEN POSSIBLE
    if (_trafficInfos != null) {
      var crowdednessSum = List<num>.filled(5, 0);
      /* About crowdedness List
         Index 0：北区
         Index 1：南区
         Index 2：旦苑
         Index 3：南苑
         Index 4：南区教工
       */
      _trafficInfos.forEach((keyUnprocessed, value) {
        if (value.current != 0) {
          //Ignore zero entries
          var key = keyUnprocessed.split('\n')[0];
          var keySubtitle = '';
          if (keyUnprocessed.length > 1)
            keySubtitle = keyUnprocessed.split('\n')[1];
          switch (key) {
            case '北区':
              crowdednessSum[0] += value.current;
              break;
            case '南区':
              if (keySubtitle == '') {
                crowdednessSum[1] += value.current;
              } else {
                switch (keySubtitle) {
                  case '南苑餐厅':
                    crowdednessSum[3] += value.current;
                    break;
                  case '教工快餐':
                    crowdednessSum[4] += value.current;
                    break;
                  default:
                    crowdednessSum[1] += value.current;
                }
              }
              break;
            case '旦苑':
              crowdednessSum[2] += value.current;
              break;
          }
        }
      });
      switch (crowdednessSum.indexOf(crowdednessSum.reduce(min))) {
        case 0:
          _leastCrowdedCanteen = '北区';
          break;
        case 1:
          _leastCrowdedCanteen = '南区';
          break;
        case 2:
          _leastCrowdedCanteen = '旦苑';
          break;
        case 3:
          _leastCrowdedCanteen = '南苑';
          break;
        case 4:
          _leastCrowdedCanteen = '南区教工';
          break;
        default:
          _leastCrowdedCanteen = 'NULL';
      }
      switch (crowdednessSum.indexOf(crowdednessSum.reduce(max))) {
        case 0:
          _mostCrowdedCanteen = '北区';
          break;
        case 1:
          _mostCrowdedCanteen = '南区';
          break;
        case 2:
          _mostCrowdedCanteen = '旦苑';
          break;
        case 3:
          _mostCrowdedCanteen = '南苑';
          break;
        case 4:
          _mostCrowdedCanteen = '南区教工';
          break;
        default:
          _mostCrowdedCanteen = 'NULL';
      }
      _status = ConnectionStatus.DONE;
    }
    notifyUpdate();
  }

  @override
  void buildFeature() {
    _info = context.personInfo;
    _preferences = Provider.of<SharedPreferences>(context);
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _trafficInfos =
          null; //TODO: Initialize? I'm not sure about the data structure here.
      _leastCrowdedCanteen = '';
      _mostCrowdedCanteen = '';
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
        return S.of(context).most_crowded_canteen_currently_is +
            _mostCrowdedCanteen +
            S.of(context).canteen +
            S.of(context).comma_least_crowded_canteen_is +
            _leastCrowdedCanteen +
            S.of(context).canteen;
      case ConnectionStatus.FAILED:
        return S.of(context).failed;
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context).out_of_dining_time;
    }
    return '';
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
