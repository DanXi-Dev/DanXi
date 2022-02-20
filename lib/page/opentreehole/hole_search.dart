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

import 'dart:io';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:provider/provider.dart';

/// A list page showing the reports for administrators.
class OTSearchPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const OTSearchPage({Key? key, this.arguments}) : super(key: key);

  @override
  _OTSearchPageState createState() => _OTSearchPageState();
}

class _OTSearchPageState extends State<OTSearchPage> {
  final RegExp pidPattern = RegExp(r'#{1}([0-9]+)');
  final RegExp floorPattern = RegExp(r'#{2}([0-9]+)');

  Future<void> _goToPIDResultPage(BuildContext context, int pid) async {
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    try {
      final OTHole? post =
          await OpenTreeHoleRepository.getInstance().loadSpecificHole(pid);
      smartNavigatorPush(context, "/bbs/postDetail", arguments: {
        "post": post!,
      });
    } catch (error, st) {
      if (error is DioError &&
          error.response?.statusCode == HttpStatus.notFound) {
        Noticing.showNotice(context, S.of(context).post_does_not_exist,
            title: S.of(context).fatal_error, useSnackBar: false);
      } else {
        Noticing.showModalError(context, error, trace: st);
      }
    }
    progressDialog.dismiss(showAnim: false);
  }

  Future<void> submit(String value) async {
    value = value.trim();
    if (value.isEmpty) return;

    final history = SettingsProvider.getInstance().searchHistory;
    // Populate history
    if (!history.contains(value)) {
      SettingsProvider.getInstance().searchHistory = [value] + history;
    }

    // Determine if user is using #PID pattern to reach a specific post
    try {
      final floorMatch = floorPattern.firstMatch(value)!;
      ProgressFuture progressDialog = showProgressDialog(
          loadingText: S.of(context).logout, context: context);
      try {
        final floor = (await OpenTreeHoleRepository.getInstance()
            .loadSpecificFloor(int.parse(floorMatch.group(1)!)))!;
        progressDialog.dismiss(showAnim: false);
        OTFloorMentionWidget.showFloorDetail(context, floor);
      } catch (error, st) {
        progressDialog.dismiss(showAnim: false);
        if (error is DioError &&
            error.response?.statusCode == HttpStatus.notFound) {
          Noticing.showNotice(context, S.of(context).post_does_not_exist,
              title: S.of(context).fatal_error, useSnackBar: false);
        } else {
          Noticing.showModalError(context, error, trace: st);
        }
      }
      return;
    } catch (ignored) {}
    try {
      final pidMatch = pidPattern.firstMatch(value)!;
      _goToPIDResultPage(context, int.parse(pidMatch.group(1)!));
      return;
    } catch (ignored) {}

    smartNavigatorPush(context, "/bbs/postDetail",
        arguments: {"searchKeyword": value});
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).search),
        trailingActions: const [],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Hero(
              transitionOnUserGestures: true,
              tag: 'OTSearchWidget',
              child: Padding(
                padding: Theme.of(context).cardTheme.margin ??
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: CupertinoSearchTextField(
                  autofocus: true,
                  placeholder: S.of(context).search_hint,
                  onSubmitted: submit,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(S.of(context).history),
                  PlatformTextButton(
                      alignment: Alignment.centerLeft,
                      child: Text(S.of(context).clear),
                      onPressed: () =>
                          SettingsProvider.getInstance().searchHistory = null),
                ],
              ),
            ),
            Expanded(
              child: Selector<SettingsProvider, List<String>>(
                  selector: (_, model) => model.searchHistory,
                  builder: (_, value, __) => ListView(
                        primary: false,
                        shrinkWrap: true,
                        //reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: value
                            .map((e) => PlatformTextButton(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 16),
                                  alignment: Alignment.centerLeft,
                                  child: Text(e),
                                  onPressed: () => submit(e),
                                ))
                            .toList(growable: false),
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
