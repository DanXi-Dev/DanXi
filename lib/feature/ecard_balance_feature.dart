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
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

class EcardBalanceFeature extends Feature {
  PersonInfo _info;
  String _balance;
  CardInfo _cardInfo;
  CardRecord _lastTransaction;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadCard(PersonInfo info) async {
    _status = ConnectionStatus.CONNECTING;
    _cardInfo = await Retrier.tryAsyncWithFix(
        () => CardRepository.getInstance().loadCardInfo(0),
        (exception) => CardRepository.getInstance().init(info));
    _balance = _cardInfo.cash;

    // If there's any transaction, we'll show it in the subtitle
    if (_cardInfo.records.isNotEmpty)
      _lastTransaction = _cardInfo.records.first;
    if (_balance == null) {
      _status = ConnectionStatus.FAILED;
    } else {
      _status = ConnectionStatus.DONE;
    }
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic> arguments]) {
    _info = StateProvider.personInfo.value;

    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _balance = "";
      _loadCard(_info).catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context).ecard_balance;

  @override
  String get subTitle {
    return '¥7.00 本部学校面包房';
  }

  //@override
  //String get tertiaryTitle => _lastTransaction?.location;

  @override
  Widget get trailing {
    return Text(
      Constant.yuanSymbol("93.39"),
      textScaleFactor: 1.2,
      style: TextStyle(
          color: num.tryParse(_balance) == null
              ? null
              : num.tryParse(_balance) < 20.0
                  ? Theme.of(context).errorColor
                  : null),
    );
  }

  @override
  Widget get icon => PlatformX.isAndroid
      ? const Icon(Icons.account_balance_wallet)
      : const Icon(SFSymbols.creditcard);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_cardInfo != null) {
      smartNavigatorPush(context, "/card/detail",
          arguments: {"cardInfo": _cardInfo});
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
