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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class FudanAAONoticesFeature extends Feature {
  List<Notice> _initialData;

  void _loadNotices() async {
    _initialData = await Retrier.runAsyncWithRetry(() =>
        FudanAAORepository.getInstance()
            .getNotices(FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT, 1));
    notifyUpdate();
  }

  @override
  void buildFeature() {
    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_initialData == null) {
      _loadNotices();
    }
  }

  @override
  String get mainTitle => S.of(context).fudan_aao_notices;

  @override
  String get subTitle =>
      _initialData == null ? S.of(context).loading : _initialData.first.title;

  @override
  Widget get icon => const Icon(Icons.developer_board);

  @override
  void onTap() {
    if (_initialData != null) {
      Navigator.of(context).pushNamed("/notice/aao/list",
          arguments: {"initialData": _initialData});
    }
  }

  @override
  bool get clickable => true;
}
