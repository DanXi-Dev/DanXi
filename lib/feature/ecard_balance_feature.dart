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
import 'package:dan_xi/page/dashboard/card_detail.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/ecard_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EcardBalanceFeature extends Feature {
  @override
  bool get loadOnTap => false;

  /// The card balance. (e.g. "12.31")
  String? _balance;

  /// User's card information.
  CardInfo? _cardInfo;

  /// The last transaction information to show in the [subTitle].
  CardRecord? _lastTransaction;

  Future<void> _loadCard(PersonInfo? info) async {
    status = const ConnectionConnecting();
    _cardInfo = await CardRepository.getInstance().loadCardInfo(info, 0);
    _balance = _cardInfo!.cash;

    // If there's any transaction, we'll show it in the subtitle
    if (_cardInfo!.records!.isNotEmpty) {
      _lastTransaction = _cardInfo!.records!.first;
    }
    if (_balance == null) {
      status = ConnectionFailed(Exception('Balance is null'));
    } else {
      status = const ConnectionDone();
    }
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (status is ConnectionNone) {
      _balance = "";
      _loadCard(StateProvider.personInfo.value).catchError((error, stackTrace) {
        status = ConnectionFailed(error, stackTrace);
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context!).ecard_balance;

  @override
  String get subTitle {
    switch (status) {
      case ConnectionNone():
      case ConnectionConnecting():
        return S.of(context!).loading;
      case ConnectionDone():
        return "${Constant.yuanSymbol(_lastTransaction?.payment)} ${_lastTransaction?.location ?? ""}";
      case ConnectionFailed():
      case ConnectionFatalError():
        return S.of(context!).failed;
    }
  }

  //@override
  //String get tertiaryTitle => _lastTransaction?.location;

  @override
  Widget? get trailing {
    if (status is ConnectionConnecting) {
      return const FeatureProgressIndicator();
    } else if (status is ConnectionDone) {
      return Text(
        Constant.yuanSymbol(_balance),
        textScaler: TextScaler.linear(1.2),
        style: TextStyle(
            color: num.tryParse(_balance!) == null
                ? null
                : num.tryParse(_balance!)! < 20.0
                    ? Theme.of(context!).colorScheme.error
                    : null),
      );
    }
    return null;
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.account_balance_wallet)
      : const Icon(CupertinoIcons.creditcard);

  void refreshData() {
    status = const ConnectionNone();
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_cardInfo != null) {
      smartNavigatorPush(context!, "/card/detail",
          arguments: CardDetailPageArguments(_cardInfo!));
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
