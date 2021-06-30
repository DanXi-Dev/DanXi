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
import 'package:dan_xi/repository/fudan_pe_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

class PEFeature extends Feature {
  PersonInfo _info;
  List<ExerciseItem> _exercises;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  void _loadExercises() async {
    _status = ConnectionStatus.CONNECTING;
    _exercises = await FudanPERepository.getInstance()
        .loadExerciseRecords(_info)
        .onError((error, stackTrace) {
      _status = ConnectionStatus.FAILED;
      return null;
    });
    if (_exercises != null) _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic> arguments]) {
    _info = context.personInfo;

    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _exercises = null;
      _loadExercises();
    }
  }

  @override
  String get mainTitle => S.of(context).pe_exercises;

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context).loading;
      case ConnectionStatus.DONE:
        if (_exercises.isEmpty)
          return S.of(context).no_data;
        else {
          // 1 Morning, 2 Must-do, 3 Select-do
          List<int> exerciseCategory = [0, 0, 0];
          _exercises.forEach((element) {
            switch (element.title) {
              case '早操':
                exerciseCategory[0] += element.times;
                break;
              case '课外活动':
                exerciseCategory[2] += element.times;
                break;
              case '晚锻炼':
                exerciseCategory[2] += element.times;
                break;
              case '仰卧起坐':
                exerciseCategory[1] += element.times;
                break;
              case '引体向上':
                exerciseCategory[1] += element.times;
                break;
              case '中长跑':
                exerciseCategory[1] += element.times;
                break;
              case '立定跳远':
                exerciseCategory[1] += element.times;
                break;
              case '周末上午':
                exerciseCategory[2] += element.times;
                break;
              case '加章1':
                exerciseCategory[0] += element.times;
                break;
              case '加章2':
                exerciseCategory[1] += element.times;
                break;
              case '加章3':
                exerciseCategory[2] += element.times;
                break;
            }
          });
          return "早锻: ${exerciseCategory[0]} 必锻: ${exerciseCategory[1]} 选锻: ${exerciseCategory[2]}";
        }
        break;
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context).failed;
    }
    return '';
  }

  @override
  Widget get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return ScaleTransform(
        scale: PlatformX.isMaterial(context) ? 0.5 : 1.0,
        child: PlatformCircularProgressIndicator(),
      );
    }
    return null;
  }

  @override
  Widget get icon => PlatformX.isAndroid
      ? const Icon(Icons.wb_sunny)
      : const Icon(SFSymbols.sun_max);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_exercises != null && _exercises.isNotEmpty) {
      String body = "";
      _exercises.forEach((element) {
        body += "\n${element.title}: ${element.times}";
      });
      Noticing.showNotice(context, body,
          title: S.of(context).pe_exercises, androidUseSnackbar: false);
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
