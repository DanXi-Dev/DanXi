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
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';

class EcardBalanceFeature extends Feature {
  PersonInfo _info;
  String _balance;
  CardInfo _cardInfo;
  CardRecord _lastTransaction;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadCard(PersonInfo info) async {
    _status = ConnectionStatus.CONNECTING;
    await CardRepository.getInstance().login(info);
    _cardInfo = await CardRepository.getInstance().loadCardInfo(0);

    _balance = _cardInfo.cash;

    if (_cardInfo.records.isNotEmpty)
      _lastTransaction = _cardInfo.records.first;
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  @override
  void buildFeature() {
    _info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;

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
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context).loading;
      case ConnectionStatus.DONE:
        if (_lastTransaction == null)
          return "";
        else
          return S.of(context).last_transaction +
              Constant.yuanSymbol(_lastTransaction?.payment) +
              " " +
              _lastTransaction?.location;
        break;
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context).failed;
    }
    return '';
  }

  @override
  Row get customSubtitle {
    if (_status == ConnectionStatus.DONE) {
      if (_lastTransaction == null)
        return null;
      else
        return Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.all(Radius.circular(4.0))),
              child: Text(
                S.of(context).last_transaction,
                style: TextStyle(
                    color: Theme.of(context).hintColor.computeLuminance() >=
                            0.5
                        ? Colors.black
                        : Colors.white,
                        fontSize: 11),
              ),
            ),
            const SizedBox(
              width: 4,
            ),
            Text(Constant.yuanSymbol(_lastTransaction?.payment)),
            const SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                _lastTransaction?.location,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                maxLines: 1,
              ),
            )
          ],
        );
    }
    return null;
  }

  //@override
  //String get tertiaryTitle => _lastTransaction?.location;

  @override
  Widget get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return ScaleTransform(
        scale: 0.5,
        child: CircularProgressIndicator(),
      );
    } else if (_status == ConnectionStatus.DONE)
      return Text(
        Constant.yuanSymbol(_balance),
        textScaleFactor: 1.2,
      );
    return null;
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
      Navigator.of(context).pushNamed("/card/detail",
          arguments: {"cardInfo": _cardInfo, "personInfo": _info});
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
