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
import 'package:dan_xi/model/forum/message.dart';
import 'package:dan_xi/page/subpage_forum.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/watermark.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing notifications.
class OTMessagesPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const OTMessagesPage({super.key, this.arguments});

  @override
  OTMessagesPageState createState() => OTMessagesPageState();
}

class OTMessagesPageState extends State<OTMessagesPage> {
  final PagedListViewController<OTMessage> _listViewController =
      PagedListViewController();

  final TimeBasedLoadAdaptLayer<OTMessage> adaptLayer =
      TimeBasedLoadAdaptLayer(Constant.POST_COUNT_PER_PAGE, 1);

  final GlobalKey<RefreshIndicatorState> indicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool showUnreadOnly = false;

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTMessage>?> _loadContent(int page) {
    return adaptLayer.generateReceiver(_listViewController, (lastElement) {
      DateTime? time;
      if (lastElement != null) {
        time = DateTime.parse(lastElement.time_created!);
      } else {
        time = DateTime.now();
      }
      return ForumRepository.getInstance()
          .loadMessages(startTime: time, unreadOnly: showUnreadOnly)
          .then((value) {
        // Automatically clear all messages after loading, assuming that the user has already read them.
        unawaited(ForumRepository.getInstance().clearMessages());
        return value;
      });
    }).call(page);
  }

  /// Rebuild everything and refresh itself.
  Future<void> refreshSelf() async {
    await _listViewController.notifyUpdate(
        useInitialData: false, queueDataClear: true);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text(S.of(context).messages),
        ),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Text(
              showUnreadOnly
                  ? S.of(context).show_all
                  : S.of(context).show_unread,
              softWrap: true,
              textScaler: MediaQuery.textScalerOf(context),
            ),
            onPressed: () async {
              setState(() {
                showUnreadOnly = !showUnreadOnly;
              });
              await indicatorKey.currentState?.show();
            },
          ),
        ],
      ),
      body: Builder(
        // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
        builder: (context) => RefreshIndicator(
          key: indicatorKey,
          edgeOffset: MediaQuery.of(context).padding.top,
          color: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await refreshSelf();
          },
          child: PagedListView<OTMessage>(
            startPage: 1,
            pagedController: _listViewController,
            withScrollbar: true,
            scrollController: PrimaryScrollController.of(context),
            dataReceiver: _loadContent,
            builder: (_, __, ___, message) => OTMessageItem(message: message),
            loadingBuilder: (BuildContext context) => Container(
              padding: const EdgeInsets.all(8),
              child: Center(child: PlatformCircularProgressIndicator()),
            ),
            endBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(S.of(context).end_reached),
              ),
            ),
            emptyBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(S.of(context).no_data),
              ),
            ),
          ),
        ),
      ),
    ).withWatermarkRegion();
  }
}
