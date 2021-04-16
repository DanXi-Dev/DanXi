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
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/empty_classroom_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/forgettable_future_builder.dart';
import 'package:dan_xi/widget/tag_selector/selector.dart';
import 'package:dan_xi/widget/tag_selector/tag.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmptyClassroomDetailPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _EmptyClassroomDetailPageState createState() =>
      _EmptyClassroomDetailPageState();

  EmptyClassroomDetailPage({Key key, this.arguments});
}

class _EmptyClassroomDetailPageState extends State<EmptyClassroomDetailPage> {
  PersonInfo _personInfo;

  List<Tag> _campusTags;
  int _selectCampusIndex = 0;

  List<Tag> _buildingTags;
  Map<int, Text> _buildingList;
  int _selectBuildingIndex = 0;

  ScrollController _controller = ScrollController();

  _loadDefaultRoom() async {
    _selectCampusIndex =
        SettingsProvider.of(await SharedPreferences.getInstance()).campus.index;
    refreshSelf();
  }

  @override
  void initState() {
    super.initState();
    _personInfo = widget.arguments['personInfo'];
    _loadDefaultRoom();
  }

  @override
  Widget build(BuildContext context) {
    // Build tags and texts.
    _campusTags = Constant.CAMPUS_VALUES
        .map((e) => Tag(e.displayTitle(context),
            PlatformX.isAndroid ? Icons.location_on : SFSymbols.location))
        .toList();
    _buildingTags = Constant.CAMPUS_VALUES[_selectCampusIndex]
        .getTeachingBuildings()
        .map((e) =>
            Tag(e, PlatformX.isAndroid ? Icons.home_work : SFSymbols.location))
        .toList();
    _buildingList = Constant.CAMPUS_VALUES[_selectCampusIndex]
        .getTeachingBuildings()
        .map((e) => Text(e))
        .toList()
        .asMap();

    return PlatformProvider(
        builder: (BuildContext context) => PlatformScaffold(
              iosContentBottomPadding: true,
              iosContentPadding: true,
              appBar: PlatformAppBar(
                  title: TopController(
                    controller: _controller,
                    child: Text(S.of(context).empty_classrooms),
                  )),
              body: Column(children: [
                SizedBox(
                  height: PlatformX.isMaterial(context) ? 0 : 12,
                ),
                PlatformWidget(
                    material: (_, __) => TagContainer(
                        fillRandomColor: false,
                        fixedColor: Colors.purple,
                        fontSize: 16,
                        enabled: true,
                        singleChoice: true,
                        defaultChoice: _selectCampusIndex,
                        onChoice: (Tag tag, list) {
                          int index = _campusTags.indexWhere(
                              (element) => element.tagTitle == tag.tagTitle);
                          if (index >= 0 && index != _selectCampusIndex) {
                            _selectCampusIndex = index;
                            _selectBuildingIndex = 0;
                            refreshSelf();
                          }
                        },
                        tagList: _campusTags),
                    cupertino: (_, __) => CupertinoSlidingSegmentedControl<int>(
                          onValueChanged: (int value) {
                            _selectCampusIndex = value;
                            _selectBuildingIndex = 0;
                            refreshSelf();
                          },
                          groupValue: _selectCampusIndex,
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
                    material: (_, __) => TagContainer(
                        fillRandomColor: false,
                        fixedColor: Colors.blue,
                        fontSize: 16,
                        enabled: true,
                        singleChoice: true,
                        defaultChoice: _selectBuildingIndex,
                        onChoice: (Tag tag, list) {
                          int index = _buildingTags.indexWhere(
                              (element) => element.tagTitle == tag.tagTitle);
                          if (index >= 0 && index != _selectBuildingIndex) {
                            _selectBuildingIndex = index;
                            refreshSelf();
                          }
                        },
                        tagList: _buildingTags),
                    cupertino: (_, __) => CupertinoSlidingSegmentedControl<int>(
                          onValueChanged: (int value) {
                            if (value >= 0 && value != _selectBuildingIndex) {
                              _selectBuildingIndex = value;
                              refreshSelf();
                            }
                          },
                          groupValue: _selectBuildingIndex,
                          children: _buildingList,
                        )),
                const SizedBox(height: 15),
                ForgettableFutureBuilder(
                  builder: (BuildContext context,
                      AsyncSnapshot<List<RoomInfo>> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        return _buildLoadingWidget();
                        break;
                      case ConnectionState.done:
                        return snapshot.hasError
                            ? _buildErrorWidget()
                            : Expanded(
                            child: MediaQuery.removePadding(
                                context: context,
                                removeTop: true,
                                child: PlatformWidget(
                                    material: (_, __) => Scrollbar(
                                        interactive: PlatformX.isDesktop,
                                        child: ListView(
                                          controller: _controller,
                                          children: _getListWidgets(
                                              snapshot.data),
                                        )),
                                    cupertino: (_, __) =>
                                        CupertinoScrollbar(
                                            child: ListView(
                                              controller: _controller,
                                              children: _getListWidgets(
                                                  snapshot.data),
                                            )))));
                        break;
                    }
                    return null;
                  },
                  future: EmptyClassroomRepository.getInstance()
                      .getBuildingRoomInfo(
                      _personInfo,
                      _buildingList[_selectBuildingIndex].data,
                      DateTime.now()),
                ),
              ]),
            ));
  }

  List<Widget> _getListWidgets(List<RoomInfo> data) {
    List<Widget> widgets = [];
    if (data != null)
      data.forEach((element) {
        widgets.add(Material(
            color: isCupertino(context) ? Colors.white : null,
            child:
            Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const SizedBox(width: 1,),
                        Text(element.roomName, style: TextStyle(fontSize: 18),),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _buildBusinessViewForRoom(element),
                        ),
                        const SizedBox(width: 1,),
                      ]
                  ),
                  Divider(),
                ]
              //subtitle: Divider(height: 5,),
            )));
      });
    return widgets;
  }

  List<Widget> _buildBusinessViewForRoom(RoomInfo roomInfo) {
    var _list = <Widget>[];
    var _time = 1;
    roomInfo.busy.forEach((element) {
      _list.add(Container(
        decoration: BoxDecoration(
            color: element ? Colors.red : Colors.green,
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        width: MediaQuery.of(context).size.width / 32,
        margin: EdgeInsets.symmetric(horizontal: 2),
        height: 22,
      ));
      if (_time++ % 5 == 0) _list.add(SizedBox(width: 7,));
    });
    return _list;
  }

  Widget _buildLoadingWidget() => GestureDetector(
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _buildErrorWidget() => GestureDetector(
        child: Center(
          child: Text(S.of(context).failed),
        ),
        onTap: () {
          refreshSelf();
        },
      );
}
