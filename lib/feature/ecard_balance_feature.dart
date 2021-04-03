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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class EcardBalanceFeature extends Feature {
  PersonInfo _info;
  String _balance;
  CardInfo _cardInfo;

  void _loadCard(PersonInfo info) async {
    await CardRepository.getInstance().login(info);
    _cardInfo = await CardRepository.getInstance().loadCardInfo(-1);
    _balance = _cardInfo.cash;
    notifyUpdate();
  }

  @override
  void buildFeature() {
    _info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;

    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_cardInfo == null) {
      _balance = S.of(context).loading;
      _loadCard(_info);
    }
  }

  @override
  String get mainTitle => S.of(context).ecard_balance;

  @override
  String get subTitle => _balance;

  @override
  Widget get icon => const Icon(Icons.account_balance_wallet);

  @override
  void onTap() {
    if (_cardInfo != null) {
      Navigator.of(context).pushNamed("/card/detail",
          arguments: {"cardInfo": _cardInfo, "personInfo": _info});
    }
  }

  @override
  bool get clickable => true;
}
