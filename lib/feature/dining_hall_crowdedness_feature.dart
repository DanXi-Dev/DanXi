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
import 'package:dan_xi/repository/dining_hall_crowdedness_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';

class DiningHallCrowdednessFeature extends Feature {
  PersonInfo _info;
  Map<String, TrafficInfo> _trafficInfos;
  String _leastCrowdedCanteen;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadCrowdednessSummary(PersonInfo info) async {
    _status = ConnectionStatus.CONNECTING;
    _trafficInfos = await DiningHallCrowdednessRepository.getInstance()
        .getCrowdednessInfo(
        info, Constant.campusArea.indexOf("邯郸校区")) //TODO: Support more campus
        .catchError((e) {
      if (e is UnsuitableTimeException) {
        _status = ConnectionStatus.FATAL_ERROR;
      }
    });

    //TODO: DUE TO THE FACT THAT I'M NOT FAMILIAR WITH DART'S SYNTAX, THE FOLLOWING CODE IS SOMEHOW *STUPID* AND HAS HARDCODED CONTENTS. REVISE WHEN POSSIBLE
    if (_trafficInfos != null) {
      var crowdedness_sum = List<int>.filled(5, 0);
      _trafficInfos.forEach((key, value) {
        if(value.current != 0) { //Ignore zero entries
          key = key.split('\n')[0];
          switch(key) {
            case '北区':
              crowdedness_sum[0] += value.current;
              break;
            case '南区':
              crowdedness_sum[1] += value.current;
              //TODO: Seperate 南苑
              break;
            case '旦苑':
              crowdedness_sum[2] += value.current;
              break;
          }
        }
      });
      var crowdedness_min = min(crowdedness_sum[0], min(crowdedness_sum[1], crowdedness_sum[2]));
      //TODO: Display crowdedness_max
      switch(crowdedness_sum.indexOf(crowdedness_min)) {
        case 0:
          _leastCrowdedCanteen = '北区';
          break;
        case 1:
          _leastCrowdedCanteen = '南区';
          break;
        case 2:
          _leastCrowdedCanteen = '旦苑';
          break;
      }
      _status = ConnectionStatus.DONE;
    }

    notifyUpdate();
  }

  @override
  void buildFeature() {
    _info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;

    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _trafficInfos = null; //TODO: Initialize? I'm not sure about the data structure here.
      _leastCrowdedCanteen = '';
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
        return S.of(context).least_crowded_canteen_is + _leastCrowdedCanteen + S.of(context).canteen;
      case ConnectionStatus.FAILED:
        return S.of(context).failed;
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context).out_of_dining_time;
    }
    return '';
  }

  @override
  Widget get icon => PlatformX.isAndroid ? const Icon(Icons.stacked_line_chart) : const Icon(SFSymbols.person_3_fill);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_trafficInfos != null) {
      Navigator.of(context).pushNamed("/card/crowdData",
          arguments: {"personInfo": _info});
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
