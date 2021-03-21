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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/repository/fudan_daily_repository.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:provider/provider.dart';

class HomeSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  _HomeSubpageState createState() => _HomeSubpageState();

  HomeSubpage({Key key});
}

class _HomeSubpageState extends State<HomeSubpage>
    with AutomaticKeepAliveClientMixin {
  String _helloQuote = "";
  CardInfo _cardInfo;
  bool _fudanDailyTicked = true;
  ConnectionStatus _fudanDailyStatus = ConnectionStatus.NONE;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  Future<String> _loadCard(PersonInfo info) async {
    await CardRepository.getInstance().login(info);
    TimeTable table =
        await TimeTableRepository.getInstance().loadTimeTableRemotely(info);
    _cardInfo = await CardRepository.getInstance().loadCardInfo(7);
    return _cardInfo.cash;
  }

  void _processForgetTickIssue() {
    showPlatformDialog(
        context: context,
        builder: (_) => PlatformAlertDialog(
              title: Text(S.of(context).fatal_error),
              content: Text(S.of(context).tick_issue_1),
              actions: [
                PlatformButton(
                    child: Text(S.of(context).i_see),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    int time = DateTime.now().hour;
    if (time >= 23 || time <= 4) {
      _helloQuote = S.of(context).late_night;
    } else if (time >= 5 && time <= 8) {
      _helloQuote = S.of(context).good_morning;
    } else if (time >= 9 && time <= 11) {
      _helloQuote = S.of(context).good_noon;
    } else if (time >= 12 && time <= 16) {
      _helloQuote = S.of(context).good_afternoon;
    } else if (time >= 17 && time <= 22) {
      _helloQuote = S.of(context).good_night;
    }
    PersonInfo info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;
    String connectStatus = Provider.of<ValueNotifier<String>>(context)?.value;
    return Column(
      children: <Widget>[
        Card(
            child: Column(
          children: [
            ListTile(
              title: Text(S.of(context).welcome(info?.name)),
              subtitle: Text(_helloQuote),
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text(S.of(context).current_connection),
              subtitle: Text(connectStatus),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(S.of(context).ecard_balance),
              subtitle: FutureBuilder(
                  future: _loadCard(info),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      String response = snapshot.data;
                      return Text(response);
                    } else {
                      return Text(S.of(context).loading);
                    }
                  }),
              onTap: () {
                if (_cardInfo != null) {
                  Navigator.of(context).pushNamed("/card/detail",
                      arguments: {"cardInfo": _cardInfo, "personInfo": info});
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.stacked_line_chart),
              title: Text(S.of(context).dining_hall_crowdedness),
              onTap: () {
                Navigator.of(context).pushNamed("/card/crowdData",
                    arguments: {"cardInfo": _cardInfo, "personInfo": info});
              },
            )
          ],
        )),
        Card(
          child: ListTile(
            title: Text(S.of(context).fudan_daily),
            leading: const Icon(Icons.cloud_upload),
            subtitle: FutureBuilder(
                future: FudanDailyRepository.getInstance().hasTick(info),
                builder: (_, AsyncSnapshot<bool> snapshot) {
                  if (snapshot.hasData) {
                    _fudanDailyStatus = ConnectionStatus.DONE;
                    _fudanDailyTicked = snapshot.data;
                    return Text(_fudanDailyTicked
                        ? S.of(context).fudan_daily_ticked
                        : S.of(context).fudan_daily_tick);
                  } else if (snapshot.hasError) {
                    _fudanDailyStatus = ConnectionStatus.FAILED;
                    return Text(S.of(context).failed);
                  } else {
                    _fudanDailyStatus = ConnectionStatus.CONNECTING;
                    return Text(S.of(context).loading);
                  }
                }),
            onTap: () async {
              switch (_fudanDailyStatus) {
                case ConnectionStatus.DONE:
                  if (!_fudanDailyTicked) {
                    var progressDialog = showProgressDialog(
                        loadingText: S.of(context).ticking, context: context);
                    await FudanDailyRepository.getInstance().tick(info).then(
                        (value) => {progressDialog.dismiss(), setState(() {})},
                        onError: (e) {
                      progressDialog.dismiss();
                      if (e is NotTickYesterdayException) {
                        _processForgetTickIssue();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context).tick_failed)));
                      }
                    });
                  }
                  break;
                case ConnectionStatus.FAILED:
                  setState(
                      () => _fudanDailyStatus = ConnectionStatus.CONNECTING);
                  break;
                case ConnectionStatus.FATAL_ERROR:
                case ConnectionStatus.CONNECTING:
                case ConnectionStatus.NONE:
                  break;
              }
            },
          ),
        )
      ],
    );
  }
}
