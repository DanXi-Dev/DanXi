/*
 *     Copyright (C) 2025  DanXi-Dev
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
import 'package:dan_xi/provider/state_provider.dart' as sp;
import 'package:dan_xi/repository/fdu/ecard_repository.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dan_xi/widget/forum/tag_selector/selector.dart';
import 'package:dan_xi/widget/forum/tag_selector/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_detail.g.dart';

@riverpod
Future<List<CardRecord>> cardRecord(Ref ref, int logDays,
    {List<CardRecord>? cache}) async {
  if (logDays == 0 && cache != null) {
    return cache;
  }

  return await CardRepository.getInstance()
      .loadCardRecord(sp.StateProvider.personInfo.value, logDays);
}

class CardDetailPageArguments {
  final CardInfo cardInfo;

  CardDetailPageArguments(this.cardInfo);
}

class CardDetailPage extends HookConsumerWidget {
  final _tagDays = [0, 7, 15, 30];
  final CardDetailPageArguments arguments;

  CardDetailPage({super.key, required this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = [
      Tag(S.current.last_7_days, Icons.timelapse),
      Tag(S.current.last_15_days, Icons.timelapse),
      Tag(S.current.last_30_days, Icons.timelapse),
    ];
    final dayId = useState<int>(-1);
    final cardRecord = ref.watch(cardRecordProvider(_tagDays[dayId.value + 1],
        cache: arguments.cardInfo.records));

    Widget buildRecordWidget() {
      return switch (cardRecord) {
        AsyncData(:final value) => Expanded(
            child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: WithScrollbar(
                  controller: PrimaryScrollController.of(context),
                  child: ListView(
                    controller: PrimaryScrollController.of(context),
                    children: _getListWidgets(value),
                  ),
                ))),
        AsyncError(:final error, :final stackTrace) =>
          ErrorPageWidget.buildWidget(context, error,
              stackTrace: stackTrace,
              onTap: () =>
                  ref.refresh(cardRecordProvider(_tagDays[dayId.value + 1]))),
        _ => Center(child: PlatformCircularProgressIndicator()),
      };
    }

    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
          title: TopController(
        controller: PrimaryScrollController.of(context),
        child: Text(S.of(context).ecard_balance_log),
      )),
      body: Column(children: [
        TagContainer(
            fillRandomColor: false,
            fixedColor: Theme.of(context).colorScheme.secondary,
            fontSize: 16,
            enabled: !cardRecord.isLoading,
            singleChoice: true,
            defaultChoice: dayId.value,
            onChoice: (Tag tag, list) {
              dayId.value = tags.indexOf(tag);
            },
            tagList: tags),
        buildRecordWidget(),
      ]),
    );
  }

  List<Widget> _getListWidgets(List<CardRecord> records) {
    List<Widget> widgets = [];
    for (var element in records) {
      widgets.add(ListTile(
        // leading: Icon(Icons.monetization_on)
        title: Text(element.location),
        trailing: Text((element.type.contains("充值") ? "+" : "-") +
            Constant.yuanSymbol(element.payment)),
        subtitle: Text(DateFormat("yyyy-MM-dd HH:mm:ss").format(element.time)),
      ));
    }

    return widgets;
  }
}
