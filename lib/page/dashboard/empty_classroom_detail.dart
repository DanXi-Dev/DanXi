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
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/empty_classroom_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dan_xi/widget/forum/tag_selector/selector.dart';
import 'package:dan_xi/widget/forum/tag_selector/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'empty_classroom_detail.g.dart';

@Riverpod(keepAlive: true)
Future<List<RoomInfo>> buildingRoomInfo(Ref ref, String buildingName, DateTime date) async {
  return await EmptyClassroomRepository.getInstance().getBuildingRoomInfo(buildingName, date);
}

/// A list page showing usages of classrooms.
class EmptyClassroomDetailPage extends HookConsumerWidget {
  const EmptyClassroomDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectCampusIndex = useState<int>(SettingsProvider.getInstance().campus.index);
    final selectCampus = Constant.CAMPUS_VALUES[selectCampusIndex.value];

    int storedBuildingIndex = SettingsProvider.getInstance().lastECBuildingChoiceRepresentation;
    if (storedBuildingIndex >= selectCampus.getTeachingBuildings().length) {
      // Reset to 0 if last stored index is out of range.
      storedBuildingIndex = SettingsProvider.getInstance().lastECBuildingChoiceRepresentation = 0;
    }
    final selectBuildingIndex = useState<int>(storedBuildingIndex);
    useValueChanged<int, void>(selectBuildingIndex.value, (_, _) {
      // When building index changes, store it for next time use.
      SettingsProvider.getInstance().lastECBuildingChoiceRepresentation = selectBuildingIndex.value;
    });
    final selectDate = useState<DateTime>(DateTime.now());

    final roomInfoProvider = buildingRoomInfoProvider(selectCampus.getTeachingBuildings()[selectBuildingIndex.value], selectDate.value);
    final roomInfos = ref.watch(roomInfoProvider);

    List<Widget> widgets = _getFixedWidgets(context, selectCampusIndex, selectBuildingIndex, selectDate);
    switch(roomInfos){
      case AsyncData(:final value):
        widgets.add(Expanded(
            child: WithScrollbar(
                controller: PrimaryScrollController.of(context),
                child: ListView(
                  primary: true,
                  children: _getListWidgets(context, value),
                ))));
      case AsyncLoading():
        widgets.add(Expanded(
            child: Center(
          child: PlatformCircularProgressIndicator(),
        )));
      case AsyncError(:final error, :final stackTrace):
        widgets.add(Expanded(
            child: ErrorPageWidget.buildWidget(context, error,
                stackTrace: stackTrace, onTap: () => ref.invalidate(roomInfoProvider))));
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
          child: Column(children: widgets)),
        );
  }

  List<Widget> _getFixedWidgets(BuildContext context, ValueNotifier<int> selectCampusIndex, ValueNotifier<int> selectBuildingIndex, ValueNotifier<DateTime> selectDate) {
    final campusTagWidgets = Constant.CAMPUS_VALUES
        .map((e) => Tag(
        e.displayTitle(context),
        PlatformX.isMaterial(context)
            ? Icons.location_on
            : CupertinoIcons.location))
        .toList();
    final buildingTagWidgets = Constant.CAMPUS_VALUES[selectCampusIndex.value]
        .getTeachingBuildings()
        .map((e) => Tag(
        e,
        PlatformX.isMaterial(context)
            ? Icons.home_work
            : CupertinoIcons.location))
        .toList();
    final buildingTextWidgets = Constant.CAMPUS_VALUES[selectCampusIndex.value]
        .getTeachingBuildings()
        .map((e) => Text(e))
        .toList()
        .asMap();

    return <Widget>[
      SizedBox(
        height: PlatformX.isMaterial(context) ? 0 : 12,
      ),
      // Use different widgets on iOS/Android: Tag/Tab.
      PlatformWidget(
          material: (_, _) => TagContainer(
              fillRandomColor: false,
              fixedColor: Theme.of(context).colorScheme.secondary,
              fontSize: 12,
              enabled: true,
              wrapped: false,
              singleChoice: true,
              defaultChoice: selectCampusIndex.value,
              onChoice: (Tag tag, list) {
                int index = campusTagWidgets
                    .indexWhere((element) => element.tagTitle == tag.tagTitle);
                if (index >= 0 && index != selectCampusIndex.value) {
                  selectCampusIndex.value = index;
                  selectBuildingIndex.value = 0;
                }
              },
              tagList: campusTagWidgets),
          cupertino: (_, _) => CupertinoSlidingSegmentedControl<int>(
            onValueChanged: (int? value) {
              selectCampusIndex.value = value!;
              selectBuildingIndex.value = 0;
            },
            groupValue: selectCampusIndex.value,
            children: Constant.CAMPUS_VALUES
                .map((e) => Text(e.displayTitle(context)))
                .toList()
                .asMap(),
          )),
      //Building Selector
      SizedBox(
        height: PlatformX.isMaterial(context) ? 0 : 12,
      ),
      PlatformWidget(
          material: (_, _) => TagContainer(
              fillRandomColor: false,
              fixedColor: Theme.of(context).colorScheme.secondary,
              fontSize: 16,
              wrapped: false,
              enabled: true,
              singleChoice: true,
              defaultChoice: selectBuildingIndex.value,
              onChoice: (Tag tag, list) {
                int index = buildingTagWidgets
                    .indexWhere((element) => element.tagTitle == tag.tagTitle);
                if (index >= 0 && index != selectBuildingIndex.value) {
                  selectBuildingIndex.value = index;
                }
              },
              tagList: buildingTagWidgets),
          cupertino: (_, _) => CupertinoSlidingSegmentedControl<int>(
            onValueChanged: (int? value) {
              if (value! >= 0 && value != selectBuildingIndex.value) {
                selectBuildingIndex.value = value;
              }
            },
            groupValue: selectBuildingIndex.value,
            children: buildingTextWidgets,
          )),
      const SizedBox(height: 12),

      PlatformWidget(
        cupertino: (_, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S.of(context).current_date),
            TextButton(
              onPressed: () {
                showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) =>
                        _buildCupertinoDatePicker(context, selectDate));
              },
              child: Text("${selectDate.value.month}/${selectDate.value.day}"),
            ),
          ],
        ),
        material: (_, _) => _buildSlider(selectDate),
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
                      width:
                      (ViewportUtils.getMainNavigatorWidth(context) / 32 +
                          4) *
                          5 +
                          7,
                      child: Text(
                        "| ${S.of(context).morning}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width:
                      (ViewportUtils.getMainNavigatorWidth(context) / 32 +
                          4) *
                          5 +
                          7,
                      child: Text(
                        "| ${S.of(context).afternoon}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width:
                      (ViewportUtils.getMainNavigatorWidth(context) / 32 +
                          4) *
                          3,
                      child: Text(
                        "| ${S.of(context).evening}",
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
    ];
  }

  Widget _buildCupertinoDatePicker(BuildContext context, ValueNotifier<DateTime> selectDate) => SizedBox(
      height: ViewportUtils.getMainNavigatorHeight(context) / 3,
      child: CupertinoDatePicker(
        backgroundColor: BottomAppBarTheme.of(context).color,
        mode: CupertinoDatePickerMode.date,
        initialDateTime: DateTime.now(),
        minimumDate: DateTime.now().add(const Duration(days: -1)),
        maximumDate: DateTime.now().add(const Duration(days: 14)),
        onDateTimeChanged: (DateTime value) {
          selectDate.value = value;
        },
      ));

  Widget _buildSlider(ValueNotifier<DateTime> selectDate) {
    final sliderValue = selectDate.value.difference(DateTime.now()).inDays.toDouble();
    return Slider(
        value: sliderValue,
        onChanged: (v) {
          selectDate.value = DateTime.now().add(Duration(days: v.round()));
        },
        label: DateFormat("MM/dd").format(selectDate.value),
        max: 6,
        min: 0,
        divisions: 6,
      );
  }

  List<Widget> _getListWidgets(BuildContext context, List<RoomInfo> data) {
    List<Widget> widgets = [];
    for (final element in data) {
      widgets.add(Container(
        padding: const EdgeInsets.fromLTRB(25, 5, 25, 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(element.roomName!, textScaler: TextScaler.linear(1)),
                        Text(
                          S.of(context).seats(element.seats ?? "?"),
                          textScaler: TextScaler.linear(0.8),
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    )),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _buildBusinessViewForRoom(context, element),
                ),
              ]),
          const Divider(),
        ]
          //subtitle: Divider(height: 5,),
        ),
      ));
    }
    return widgets;
  }

  List<Widget> _buildBusinessViewForRoom(BuildContext context, RoomInfo roomInfo) {
    final list = <Widget>[];
    int time = 1;
    final slot = TimeTable.defaultNow().slot + 1;

    final accessibilityColoring =
        SettingsProvider.getInstance().useAccessibilityColoring;

    for (final element in roomInfo.busy!) {
      if (accessibilityColoring) {
        list.add(Container(
          decoration: BoxDecoration(
              border: slot == time
                  ? Border.all(
                color: Theme.of(context).textTheme.bodyLarge!.color!,
                width: 2.5,
              )
                  : Border.all(
                color: Theme.of(context).textTheme.bodyLarge!.color!,
                width: 0.75,
              ),
              color:
              element ? Theme.of(context).textTheme.bodyLarge!.color : null,
              borderRadius: const BorderRadius.all(Radius.circular(5.0))),
          width: ViewportUtils.getMainNavigatorWidth(context) / 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 22,
        ));
      } else {
        list.add(Container(
          decoration: BoxDecoration(
              border: slot == time
                  ? Border.all(
                color: Theme.of(context).textTheme.bodyLarge!.color!,
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

      if (time++ % 5 == 0) {
        list.add(const SizedBox(
          width: 7,
        ));
      }
    }
    return list;
  }
}
