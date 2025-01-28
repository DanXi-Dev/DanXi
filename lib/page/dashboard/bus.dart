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

import 'dart:async';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/bus_repository.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';

/// A list page showing campus bus schedule.
class BusPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  BusPageState createState() => BusPageState();

  const BusPage({super.key, this.arguments});
}

class BusPageState extends State<BusPage> {
  Future<List<BusScheduleItem>?>? _busListWeekday;
  Future<List<BusScheduleItem>?>? _busListHoliday;
  List<BusScheduleItem>? _busListWeekdayLoaded;
  List<BusScheduleItem>? _busListHolidayLoaded;

  /// The slide bar's position of holiday/workday.
  int? _holidaySliding;

  /// Start location.
  Campus? _startSelectItem = Campus.NONE;

  /// End location.
  Campus? _endSelectItem = Campus.NONE;

  /// By default, only buses after DateTime.now() is displayed.
  /// Set this to true to display all buses.
  bool _showAll = false;

  Future<List<BusScheduleItem>?> _setContent() async {
    List<BusScheduleItem>? content;
    if (_holidaySliding == 1) {
      content = _busListHolidayLoaded = await _busListHoliday;
    } else {
      content = _busListWeekdayLoaded = await _busListWeekday;
    }
    return _filterBus(content!);
  }

  Widget _buildFutureWidget() => FutureWidget<List<BusScheduleItem>?>(
      future: _setContent(),
      successBuilder: (context, snapshot) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: _getListWidgets(snapshot.data as List<BusScheduleItem>),
          ),
      errorBuilder: (BuildContext context,
              AsyncSnapshot<List<BusScheduleItem>?> snapShot) =>
          ErrorPageWidget.buildWidget(context, snapShot.error,
              stackTrace: snapShot.stackTrace, onTap: () => refreshSelf()),
      loadingBuilder: (_) =>
          Center(child: PlatformCircularProgressIndicator()));

  Widget _autoSelectWidget() {
    if (_holidaySliding == 1) {
      if (_busListHolidayLoaded == null) {
        return _buildFutureWidget();
      } else {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          primary: true,
          children: _getListWidgets(_filterBus(_busListHolidayLoaded!)),
        );
      }
    } else {
      if (_busListWeekdayLoaded == null) {
        return _buildFutureWidget();
      } else {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          primary: true,
          children: _getListWidgets(_filterBus(_busListWeekdayLoaded!)),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!['dataIsHoliday']) {
      _busListWeekday = LazyFuture.pack(FudanBusRepository.getInstance()
          .loadBusList(StateProvider.personInfo.value, holiday: false));
      _busListHolidayLoaded = widget.arguments!['busList'];
      _holidaySliding = 1;
    } else {
      _busListHoliday = LazyFuture.pack(FudanBusRepository.getInstance()
          .loadBusList(StateProvider.personInfo.value, holiday: true));
      _busListWeekdayLoaded = widget.arguments!['busList'];
      _holidaySliding = 0;
    }

    // Default to HanDan
    _startSelectItem = Campus.HANDAN_CAMPUS;
    _onStartLocationChanged(_startSelectItem);

    _endSelectItem = SettingsProvider.getInstance().campus;
    _onEndLocationChanged(_endSelectItem);
  }

  void _onStartLocationChanged(Campus? e) {
    setState(() {
      _startSelectItem = e;
    });
  }

  void _onEndLocationChanged(Campus? e) {
    setState(() {
      _endSelectItem = e;
    });
  }

  void _onLocationSwapped() {
    setState(() {
      final temp = _startSelectItem;
      _startSelectItem = _endSelectItem;
      _endSelectItem = temp;
    });
  }

  List<BusScheduleItem> _filterBus(List<BusScheduleItem> origBusList) {
    // Normalize all backward entries and reversed dual entries
    return origBusList
        .map((element) {
          if (element.direction == BusDirection.BACKWARD) {
            return BusScheduleItem.reversed(element);
          } else if (element.direction == BusDirection.DUAL &&
              element.start == _endSelectItem &&
              element.end == _startSelectItem) {
            return BusScheduleItem.reversed(element);
          } else {
            return element;
          }
        })
        .where((element) => (element.start == _startSelectItem &&
            element.end == _endSelectItem))
        .toList();
  }

  List<DropdownMenuItem<Campus>> _getItems() => Constant.CAMPUS_VALUES.map((e) {
        return DropdownMenuItem(value: e, child: Text(e.displayTitle(context)));
      }).toList(growable: false);

  Map<int, Text> _getCupertinoItems() => Constant.CAMPUS_VALUES
      .map((e) => Text(e.displayTitle(context)))
      .toList(growable: false)
      .asMap();

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iosContentBottomPadding: false,
        iosContentPadding: false,
        appBar: PlatformAppBarX(
            title: TopController(
                controller: PrimaryScrollController.of(context),
                child: Text(S.of(context).bus_query))),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: CupertinoSlidingSegmentedControl<int>(
                  onValueChanged: (int? value) {
                    setState(() {
                      _holidaySliding = value;
                    });
                  },
                  groupValue: _holidaySliding,
                  children: {
                    0: Text(S.of(context).weekday),
                    1: Text(S.of(context).holiday)
                  },
                ),
              ),
              LayoutGrid(
                areas: '''
                start_title start swap
                dest_title  dest  swap
                ''',
                gridFit: GridFit.loose,
                columnSizes: [auto, auto, auto],
                rowSizes: [auto, auto],
                columnGap: 8,
                children: [
                  Center(child: Text(S.of(context).bus_start))
                      .inGridArea('start_title'),
                  Center(child: Text(S.of(context).bus_dest))
                      .inGridArea('dest_title'),
                  PlatformWidget(
                    material: (_, __) => DropdownButton<Campus>(
                      items: _getItems(),
                      // Don't select anything if _selectItem == Campus.NONE
                      value: _startSelectItem == Campus.NONE
                          ? null
                          : _startSelectItem,
                      hint: Text(_startSelectItem.displayTitle(context)),
                      onChanged: (Campus? e) => _onStartLocationChanged(e),
                    ),
                    cupertino: (_, __) => Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: CupertinoSlidingSegmentedControl<int>(
                        onValueChanged: (int? value) {
                          _onStartLocationChanged(Campus.values[value!]);
                        },
                        groupValue: _startSelectItem?.index,
                        children: _getCupertinoItems(),
                      ),
                    ),
                  ).inGridArea('start'),
                  PlatformWidget(
                    material: (_, __) => DropdownButton<Campus>(
                      items: _getItems(),
                      // Don't select anything if _selectItem == Campus.NONE
                      value:
                          _endSelectItem == Campus.NONE ? null : _endSelectItem,
                      hint: Text(_endSelectItem.displayTitle(context)),
                      onChanged: (Campus? e) => _onEndLocationChanged(e),
                    ),
                    cupertino: (_, __) => Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: CupertinoSlidingSegmentedControl<int>(
                        onValueChanged: (int? value) {
                          _onEndLocationChanged(Campus.values[value!]);
                        },
                        groupValue: _endSelectItem?.index,
                        children: _getCupertinoItems(),
                      ),
                    ),
                  ).inGridArea('dest'),
                  Center(
                    child: PlatformIconButton(
                      icon: Icon(PlatformX.isCupertino(context)
                          ? CupertinoIcons.arrow_swap
                          : Icons.swap_vert),
                      onPressed: _onLocationSwapped,
                    ),
                  ).inGridArea('swap'),
                ],
              ),
              Expanded(
                child: WithScrollbar(
                    controller: PrimaryScrollController.of(context),
                    child: _autoSelectWidget()),
              ),
            ],
          ),
        ));
  }

  List<Widget> _getListWidgets(List<BusScheduleItem> filteredBusList) {
    final currentTime = DateTime.now();
    final format = NumberFormat("00");
    List<Widget> widgets = [
      Card(
        child: ListTile(
          leading: Icon(PlatformIcons(context).info),
          title: Text(_showAll
              ? S.of(context).school_bus_showing_all
              : S.of(context).school_bus_not_showing_all(
                  format.format(currentTime.hour),
                  format.format(currentTime.minute))),
          subtitle: Text(_showAll
              ? S.of(context).school_bus_tap_to_not_show_all(
                  format.format(currentTime.hour),
                  format.format(currentTime.minute))
              : S.of(context).school_bus_tap_to_show_all),
          onTap: () => setState(() {
            _showAll = !_showAll;
          }),
        ),
      )
    ];
    for (var value in filteredBusList) {
      if (_showAll ||
          value.realStartTime == null ||
          value.realStartTime!.toExactTime().isAfter(currentTime)) {
        widgets.add(_buildBusCard(value));
      }
    }
    return widgets;
  }

  Card _buildBusCard(BusScheduleItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.start.displayTitle(context),
                      textScaler: TextScaler.linear(1.2),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(item.startTime?.toDisplayFormat() ?? ""),
                  ],
                ),
                Text(
                  item.direction.toText()!,
                  textScaler: TextScaler.linear(1.5),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.end.displayTitle(context),
                      textScaler: TextScaler.linear(1.2),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(item.endTime?.toDisplayFormat() ?? ""),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
