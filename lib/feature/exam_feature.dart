/*
 *     Copyright (C) 2021 kavinzhao
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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:dan_xi/public_extension_methods.dart';

class ExamFeature extends Feature {
  PersonInfo _info;

  @override
  void buildFeature() {
    _info = context.personInfo;

    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    /*if (_status == ConnectionStatus.NONE) {
      _subTitle = S.of(context).loading;
    }*/
  }

  @override
  String get mainTitle => S.of(context).exam_schedule;

  @override
  String get subTitle => S.of(context).tap_to_view;

  @override
  Widget get icon => PlatformX.isAndroid
      ? const Icon(Icons.document_scanner)
      : const Icon(SFSymbols.doc_append);

  @override
  void onTap() async {
    Navigator.of(context)
        .pushNamed('/exam/detail', arguments: {'personInfo': _info});
  }

  @override
  bool get clickable => true;
}
