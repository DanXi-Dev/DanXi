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
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';

class AdManager {
  static get appId => PlatformX.isAndroid
      ? Constant.ADMOB_APP_ID_ANDROID
      : Constant.ADMOB_APP_ID_IOS;

  static get unitIdList => PlatformX.isAndroid
      ? Constant.ADMOB_UNIT_ID_LIST_ANDROID
      : Constant.ADMOB_UNIT_ID_LIST_IOS;

  /// Initialize the banner Ad
  ///
  /// Usage:
  ///
  /// BannerAd bannerAd;
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   bannerAd = AdManager.initBannerAd();
  /// }
  ///
  /// ... and later in UI, use
  /// AdWidget(ad: bannerAd)
  ///
  static BannerAd? loadBannerAd(int index) {
    if (!PlatformX.isMobile) return null;

    return const BannerAd();
  }
}

/// A widget that automatically returns a AdWidget placed in a container
/// or nothing if user has not opted-in to Ads or [bannerAd] is [null]
class AutoBannerAdWidget extends StatelessWidget {
  final BannerAd? bannerAd;

  const AutoBannerAdWidget({Key? key, required this.bannerAd})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

/// Dummy BannerAd
class BannerAd extends StatelessWidget {
  const BannerAd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
