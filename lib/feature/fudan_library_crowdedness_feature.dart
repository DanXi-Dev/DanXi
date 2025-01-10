/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'package:dan_xi/repository/fdu/library_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FudanLibraryCrowdednessFeature extends Feature {
  @override
  bool get loadOnTap => false;

  /// The numbers of each library visitors at the moment.
  Map<String, String>? _libraryCrowdedness;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  void _loadLibraryCrowdedness() async {
    _status = ConnectionStatus.CONNECTING;
    try {
      _libraryCrowdedness =
          await FudanLibraryRepository.getInstance().getLibraryRawData();
      _status = ConnectionStatus.DONE;
    } catch (error) {
      _status = ConnectionStatus.FAILED;
    }
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _libraryCrowdedness = null;
      _loadLibraryCrowdedness();
    }
  }

  @override
  String get mainTitle => S.of(context!).fudan_library_crowdedness;

  List<String> get _resultText {
    List<String> result = [];
    _libraryCrowdedness!.forEach((key, value) {
      result.add("$key: $value");
    });
    return result;
  }

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.DONE:
        if (_libraryCrowdedness!.isEmpty) {
          return S.of(context!).no_data;
        } else {
          return _resultText.join(" ");
        }
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).failed;
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
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.local_library)
      : const Icon(CupertinoIcons.book);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_libraryCrowdedness != null && _libraryCrowdedness!.isNotEmpty) {
      Noticing.showModalNotice(context!,
          message: _resultText.join("\n"),
          title: S.of(context!).fudan_library_crowdedness);
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
