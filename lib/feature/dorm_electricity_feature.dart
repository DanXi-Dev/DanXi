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
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/dorm_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Every feature should extends [Feature]. You may find
/// `lib/feature/base_feature.dart` helpful.
///
/// Generally to implement a feature, you should do the following things:
/// - Set bool [clickable] to true if needed. Most features are clickable. Override
///   [onTap] if you want to do something when user taps the feature.
/// - Set bool [loadOnTap] to false if you want to load data immediately.
///   If you do so, [buildFeature] will not be called until user first tap the
///   feature.
/// - Set [icon] to an [Icon] if needed. Select one from [Icons] or [CupertinoIcons]
///   as you like.
/// - Set [mainTitle] to a [String] if needed. The main title of a feature is
///   usually the name of the feature, which remains unchanged.
/// - Set [subTitle] to a [String] if needed. You can display information here.
/// - Override [buildFeature].
/// - Refer to `lib/feature/base_feature.dart` for more details.
///
/// If the feature relates to a network request, you should do the following things:
/// - Create a repository in `lib/repository/` if needed. See `lib/repository/base_repository.dart`.
///   You may find the extensive comments in `lib/repository/fdu/dorm_repository.dart`
///   helpful.
/// - You can initialize a [ConnectionStatus] variable to [ConnectionStatus.NONE]
///   to indicate the connection status. Call [notifyUpdate] when the request is done.
class DormElectricityFeature extends Feature {
  /// The data instance. See `lib/repository/fdu/dorm_repository.dart`.
  ElectricityItem? _electricity;

  /// Status of the request.
  /// Whenever the status is changed, call [notifyUpdate] to update the widget.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadData() async {
    _status = ConnectionStatus.CONNECTING;
    try {
      // Await the repository to load data.
      _electricity = await FudanDormRepository.getInstance()
          .loadElectricityInfo(StateProvider.personInfo.value);
      _status = ConnectionStatus.DONE;
    } catch (e) {
      _status = ConnectionStatus.FAILED;
    }
    // Remember to call [notifyUpdate] to update the widget.
    notifyUpdate();
  }

  /// Load data when the feature is created.
  ///
  /// Only load data once.
  /// If user needs to refresh the data, [refreshSelf] will be called on the whole
  /// page, not just on [FeatureContainer]. The feature will be recreated then.
  ///
  /// If the feature is [loadOnTap], [buildFeature] will be called when user taps.
  /// Otherwise, [buildFeature] will be called when the feature is created.
  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    if (_status == ConnectionStatus.NONE) {
      _electricity = null;
      _loadData();
    }
  }

  /// the Main title of the feature, usually to be the name of the feature. We
  /// use [S] to support i18n.
  @override
  String get mainTitle => S.of(context!).dorm_electricity;

  /// The subtitle of the feature. We usually display the data here.
  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.DONE:
        return S.of(context!).dorm_electricity_subtitle(
            _electricity!.available, _electricity!.used);
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).failed;
    }
  }

  /// The tertiary title of the feature. We usually display the loading progress
  /// here. Some features have a button here to navigate to a new page or do
  /// something else. See [WelcomeFeature] and [NextCourseFeature].
  @override
  Widget? get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return const FeatureProgressIndicator();
    }
    return null;
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.bolt)
      : const Icon(CupertinoIcons.bolt);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  /// Be careful that [onTap] will not be called if the feature does not have
  /// it's first tap when [loadOnTap] is true.
  ///
  /// If you want to do something when user taps the feature, override this method.
  /// A typical example is to show a modal dialog, navigate to a new page via
  /// [smartNavigatorPush] or reload the data when it failed.
  @override
  void onTap() {
    if (_status == ConnectionStatus.DONE) {
      final String body =
          '${_electricity?.dormName}\n${S.of(context!).dorm_electricity_subtitle(_electricity!.available, _electricity!.used)}\n\n${S.of(context!).last_updated(_electricity!.updateTime.toString())}';
      Noticing.showModalNotice(context!,
          message: body, title: S.of(context!).dorm_electricity);
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
