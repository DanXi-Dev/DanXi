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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/data_center_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing how crowded each of the campus dining halls is.
class CardCrowdData extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  CardCrowdDataState createState() => CardCrowdDataState();

  const CardCrowdData({super.key, this.arguments});
}

class CardCrowdDataState extends State<CardCrowdData> {
  PersonInfo? _personInfo;
  Map<String, TrafficInfo>? _trafficInfo;
  Campus? _selectItem = Campus.NONE;
  int? _sliding;

  @override
  void initState() {
    super.initState();
    _personInfo = StateProvider.personInfo.value;
    _selectItem = SettingsProvider.getInstance().campus;
    _sliding = _selectItem!.index;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onSelectedItemChanged(_selectItem);
    });
  }

  /// Load dining hall data
  Future<void> _onSelectedItemChanged(Campus? e) async {
    setState(() {
      _selectItem = e;
      _trafficInfo = null;
    });
    _trafficInfo = await DataCenterRepository.getInstance()
        .getCrowdednessInfo(_personInfo, _selectItem!.index)
        .catchError((e) {
      // If it's not time for a meal
      if (e is UnsuitableTimeException) {
        Noticing.showNotice(context, S.of(context).out_of_dining_time);
      }
      return null;
    });
    refreshSelf();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iosContentBottomPadding: false,
      iosContentPadding: false,
      appBar: PlatformAppBarX(
          title: TopController(
              controller: PrimaryScrollController.of(context),
              child: Text(S.of(context).dining_hall_crowdedness))),
      body: WithScrollbar(
        controller: PrimaryScrollController.of(context),
        child: ListView(
          controller: PrimaryScrollController.of(context),
          children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PlatformWidget(
                      material: (_, __) => DropdownButton<Campus>(
                            items: _getItems(),
                            isExpanded: true,
                            // Don't select anything if _selectItem == Campus.NONE
                            value:
                                _selectItem == Campus.NONE ? null : _selectItem,
                            hint: Text(_selectItem.displayTitle(context)),
                            onChanged: (Campus? e) => _onSelectedItemChanged(e),
                          ),
                      cupertino: (_, __) =>
                          CupertinoSlidingSegmentedControl<int>(
                            onValueChanged: (int? value) {
                              _sliding = value;
                              _onSelectedItemChanged(Campus.values[_sliding!]);
                            },
                            groupValue: _sliding,
                            children: _getCupertinoItems(),
                          )),
                ),
              ] +
              _getListWidgets(),
        ),
      ),
    );
  }

  List<DropdownMenuItem<Campus>> _getItems() => Constant.CAMPUS_VALUES.map((e) {
        return DropdownMenuItem(value: e, child: Text(e.displayTitle(context)));
      }).toList(growable: false);

  Map<int, Text> _getCupertinoItems() => Constant.CAMPUS_VALUES
      .map((e) => Text(e.displayTitle(context)))
      .toList(growable: false)
      .asMap();

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_trafficInfo == null) return widgets;

    DataCenterRepository.getInstance()
        .toZoneList(_selectItem.displayTitle(context), _trafficInfo)
        .forEach((key, value) {
      widgets.add(_buildZoneCard(key!, value));
    });
    return widgets;
  }

  Card _buildZoneCard(String zoneName, Map<String, TrafficInfo> infoList) {
    List<Widget> infoIndicators = [];
    infoList.forEach((key, value) {
      infoIndicators.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(key),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text("${value.current} / ${value.max}"),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: value.max == 0 ? 0 : value.current / value.max,
            )
          ],
        ),
      ));
    });
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          // Make the title align to left
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlatformX.isMaterial(context)
                    ? Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      )
                    : Icon(
                        CupertinoIcons.location_circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                Text(zoneName,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    )),
              ],
            ),
            Column(
              children: infoIndicators,
            )
          ],
        ),
      ),
    );
  }
}
