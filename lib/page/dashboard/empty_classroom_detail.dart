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
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/empty_classroom_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/selector.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';

/// A list page showing usages of classrooms.
class EmptyClassroomDetailPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  _EmptyClassroomDetailPageState createState() =>
      _EmptyClassroomDetailPageState();

  const EmptyClassroomDetailPage({Key? key, this.arguments}) : super(key: key);
}

class _EmptyClassroomDetailPageState extends State<EmptyClassroomDetailPage> {
  PersonInfo? _personInfo;

  List<Tag>? _campusTags;
  int? _selectCampusIndex = 0;

  List<Tag>? _buildingTags;
  late Map<int, Text> _buildingList;
  int __selectBuildingIndex = 0;

  int get _selectBuildingIndex => __selectBuildingIndex;

  set _selectBuildingIndex(int value) {
    __selectBuildingIndex = value;
    SettingsProvider.getInstance().lastECBuildingChoiceRepresentation = value;
  }

  double _selectDate = 0;

  _loadDefaultRoom() async {
    _selectCampusIndex = SettingsProvider.getInstance().campus.index;
    _selectBuildingIndex =
        SettingsProvider.getInstance().lastECBuildingChoiceRepresentation;
    refreshSelf();
  }

  @override
  void initState() {
    super.initState();
    _personInfo = StateProvider.personInfo.value;
    _loadDefaultRoom();
  }

  DateTime? selectDate;

  Widget _buildCupertinoDatePicker() => SizedBox(
      height: ViewportUtils.getMainNavigatorHeight(context) / 3,
      child: CupertinoDatePicker(
        backgroundColor: Theme.of(context).bottomAppBarColor,
        mode: CupertinoDatePickerMode.date,
        initialDateTime: DateTime.now(),
        minimumDate: DateTime.now().add(const Duration(days: -1)),
        maximumDate: DateTime.now().add(const Duration(days: 14)),
        onDateTimeChanged: (DateTime value) {
          setState(() {
            selectDate = value;
          });
        },
      ));

  @override
  Widget build(BuildContext context) {
    // Build tags and texts.
    _campusTags = Constant.CAMPUS_VALUES
        .map((e) => Tag(e.displayTitle(context),
            PlatformX.isAndroid ? Icons.location_on : CupertinoIcons.location))
        .toList();
    _buildingTags = Constant.CAMPUS_VALUES[_selectCampusIndex!]
        .getTeachingBuildings()!
        .map((e) => Tag(
            e, PlatformX.isAndroid ? Icons.home_work : CupertinoIcons.location))
        .toList();
    _buildingList = Constant.CAMPUS_VALUES[_selectCampusIndex!]
        .getTeachingBuildings()!
        .map((e) => Text(e))
        .toList()
        .asMap();
    if (_selectBuildingIndex >= _buildingList.keys.length) {
      _selectBuildingIndex = 0;
    }

    if (PlatformX.isMaterial(context)) {
      selectDate = DateTime.now().add(Duration(days: _selectDate.round()));
    } else {
      selectDate ??= DateTime.now();
    }

    return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: false,
        appBar: PlatformAppBarX(
            title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text(S.of(context).empty_classrooms),
        )),
        body: SafeArea(
            bottom: false,
            child: Material(
              child: Column(children: [
                SizedBox(
                  height: PlatformX.isMaterial(context) ? 0 : 12,
                ),

                // Use different widgets on iOS/Android: Tag/Tab.
                PlatformWidget(
                    material: (_, __) => TagContainer(
                        fillRandomColor: false,
                        fixedColor: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        enabled: true,
                        wrapped: false,
                        singleChoice: true,
                        defaultChoice: _selectCampusIndex,
                        onChoice: (Tag tag, list) {
                          int index = _campusTags!.indexWhere(
                              (element) => element.tagTitle == tag.tagTitle);
                          if (index >= 0 && index != _selectCampusIndex) {
                            _selectCampusIndex = index;
                            _selectBuildingIndex = 0;
                            refreshSelf();
                          }
                        },
                        tagList: _campusTags),
                    cupertino: (_, __) => CupertinoSlidingSegmentedControl<int>(
                          onValueChanged: (int? value) {
                            _selectCampusIndex = value;
                            _selectBuildingIndex = 0;
                            refreshSelf();
                          },
                          groupValue: _selectCampusIndex,
                          children: Constant.CAMPUS_VALUES
                              .map((e) => Text(e.displayTitle(context)!))
                              .toList()
                              .asMap(),
                        )),
                //Building Selector
                SizedBox(
                  height: PlatformX.isMaterial(context) ? 0 : 12,
                ),
                PlatformWidget(
                    material: (_, __) => TagContainer(
                        fillRandomColor: false,
                        fixedColor: Theme.of(context).colorScheme.secondary,
                        fontSize: 16,
                        wrapped: false,
                        enabled: true,
                        singleChoice: true,
                        defaultChoice: _selectBuildingIndex,
                        onChoice: (Tag tag, list) {
                          int index = _buildingTags!.indexWhere(
                              (element) => element.tagTitle == tag.tagTitle);
                          if (index >= 0 && index != _selectBuildingIndex) {
                            _selectBuildingIndex = index;
                            refreshSelf();
                          }
                        },
                        tagList: _buildingTags),
                    cupertino: (_, __) => CupertinoSlidingSegmentedControl<int>(
                          onValueChanged: (int? value) {
                            if (value! >= 0 && value != _selectBuildingIndex) {
                              _selectBuildingIndex = value;
                              refreshSelf();
                            }
                          },
                          groupValue: _selectBuildingIndex,
                          children: _buildingList,
                        )),
                const SizedBox(height: 12),

                PlatformWidget(
                  cupertino: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(S.of(context).current_date),
                      TextButton(
                        onPressed: () {
                          showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) =>
                                  _buildCupertinoDatePicker());
                        },
                        child: Text("${selectDate!.month}/${selectDate!.day}"),
                      ),
                    ],
                  ),
                  material: (_, __) =>
                      _buildSlider(DateFormat("MM/dd").format(selectDate!)),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            S.of(context).classroom,
                            style: const TextStyle(fontSize: 18),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                alignment: Alignment.centerLeft,
                                width: (ViewportUtils.getMainNavigatorWidth(
                                                    context) /
                                                32 +
                                            4) *
                                        5 +
                                    7,
                                child: Text(
                                  "| " + S.of(context).morning,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                width: (ViewportUtils.getMainNavigatorWidth(
                                                    context) /
                                                32 +
                                            4) *
                                        5 +
                                    7,
                                child: Text(
                                  "| " + S.of(context).afternoon,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                width: (ViewportUtils.getMainNavigatorWidth(
                                                context) /
                                            32 +
                                        4) *
                                    3,
                                child: Text(
                                  "| " + S.of(context).evening,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ]),
                    const Divider(),
                  ]),
                ),
                Expanded(
                  child: FutureWidget<List<RoomInfo>?>(
                      future: EmptyClassroomRepository.getInstance()
                          .getBuildingRoomInfo(
                              _personInfo,
                              _buildingList[_selectBuildingIndex]!.data![0],
                              _buildingList[_selectBuildingIndex]!.data,
                              selectDate),
                      successBuilder: (BuildContext context,
                              AsyncSnapshot<dynamic> snapshot) =>
                          WithScrollbar(
                              controller: PrimaryScrollController.of(context),
                              child: ListView(
                                primary: true,
                                children: _getListWidgets(snapshot.data),
                              )),
                      errorBuilder: (_, snapShot) => _buildErrorWidget(),
                      loadingBuilder: _buildLoadingWidget()),
                )
              ]),
            )));
  }

  List<Widget> _getListWidgets(List<RoomInfo>? data) {
    List<Widget> widgets = [];
    if (data != null) {
      for (var element in data) {
        widgets.add(Material(
            child: Container(
          padding: const EdgeInsets.fromLTRB(25, 5, 25, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        element.roomName!,
                        textScaleFactor: 1,
                      ),
                      Text(
                        S.of(context).seats(element.seats ?? "?"),
                        textScaleFactor: 0.8,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _buildBusinessViewForRoom(element),
                  ),
                ]),
            const Divider(),
          ]
              //subtitle: Divider(height: 5,),
              ),
        )));
      }
    }
    return widgets;
  }

  Widget _buildSlider(String dateIndicator) {
    return PlatformWidget(
      cupertino: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dateIndicator),
          PlatformSlider(
            value: _selectDate,
            onChanged: (v) {
              _selectDate = v;
              refreshSelf();
            },
            max: 6,
            min: 0,
            divisions: 6,
          )
        ],
      ),
      material: (_, __) => Slider(
        value: _selectDate,
        onChanged: (v) {
          _selectDate = v;
          refreshSelf();
        },
        label: dateIndicator,
        max: 6,
        min: 0,
        divisions: 6,
      ),
    );
  }

  List<Widget> _buildBusinessViewForRoom(RoomInfo roomInfo) {
    var _list = <Widget>[];
    var _time = 1;
    var _slot = TimeTable.defaultNow().slot + 1;

    // Prevent repeated read from disk
    final accessibilityColoring =
        SettingsProvider.getInstance().useAccessibilityColoring;

    for (var element in roomInfo.busy!) {
      if (accessibilityColoring) {
        _list.add(Container(
          decoration: BoxDecoration(
              border: _slot == _time
                  ? Border.all(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      width: 2.5,
                    )
                  : Border.all(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      width: 0.75,
                    ),
              color:
                  element ? Theme.of(context).textTheme.bodyText1!.color : null,
              borderRadius: const BorderRadius.all(Radius.circular(5.0))),
          width: ViewportUtils.getMainNavigatorWidth(context) / 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 22,
        ));
      } else {
        _list.add(Container(
          decoration: BoxDecoration(
              border: _slot == _time
                  ? Border.all(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      width: 1.5,
                    )
                  : null,
              color: element ? Colors.red : Colors.green,
              borderRadius: const BorderRadius.all(Radius.circular(5.0))),
          width: ViewportUtils.getMainNavigatorWidth(context) / 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 22,
        ));
      }

      if (_time++ % 5 == 0) {
        _list.add(const SizedBox(
          width: 7,
        ));
      }
    }
    return _list;
  }

  Widget _buildLoadingWidget() => Center(
        child: PlatformCircularProgressIndicator(),
      );

  Widget _buildErrorWidget() {
    return GestureDetector(
      child: Center(
        child: Text(S.of(context).failed),
      ),
      onTap: () {
        refreshSelf();
      },
    );
  }
}
