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
import 'package:collection/collection.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../util/platform_universal.dart';
import 'exam_detail.dart';

/// A list page showing user's GPA scores and his/her ranking.
class GpaTablePage extends HookConsumerWidget {
  final Map<String, dynamic>? arguments;

  const GpaTablePage({super.key, this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No need to use `useMemoized` for these calculations being light enough.
    final fullGpaList = (arguments!['gpalist'] as List<GpaListItem>).sortedBy(
      (gpa) => int.tryParse(gpa.rank) ?? 0x7fffffff,
    );
    final userGpa = ExamList.getUserGpaItem(fullGpaList);
    final sameMajorGpaList = userGpa == null
        ? fullGpaList
        : fullGpaList
              .where((element) => element.major == userGpa.major)
              .toList();

    final inSameMajor = useState(false);

    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).your_gpa),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? inSameMajor.value
                        ? Icons.group_off
                        : Icons.group
                  : inSameMajor.value
                  ? CupertinoIcons.person_2
                  : CupertinoIcons.person_3,
            ),
            onPressed: () {
              inSameMajor.value = !inSameMajor.value;
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          controller: PrimaryScrollController.of(context),
          child: Table(
            children: _buildGpaRow(
              context,
              inSameMajor.value ? sameMajorGpaList : fullGpaList,
              userGpa,
            ),
          ),
        ),
      ),
    );
  }

  List<TableRow> _buildGpaRow(
    BuildContext context,
    List<GpaListItem> gpaList,
    GpaListItem? userGpa,
  ) {
    String? lastRank;
    int lastTiedIndex = 0;
    final sameMajorOrdinals = gpaList
        .mapIndexed((index, gpa) {
          if (gpa.rank != lastRank) {
            lastRank = gpa.rank;
            lastTiedIndex = index;
          }
          return lastTiedIndex + 1;
        })
        .toList(growable: false);
    List<TableRow> widgets = [
      TableRow(
        children:
            [
                  S.of(context).major,
                  S.of(context).gpa,
                  S.of(context).credits,
                  S.of(context).rank,
                  S.of(context).percentile,
                ]
                .map(
                  (headText) => Text(
                    headText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
                .toList(),
      ),
    ];

    for (final (index, element) in gpaList.indexed) {
      final ordinal = sameMajorOrdinals[index];
      TextStyle? textColorStyle = identical(element, userGpa)
          ? null
          : TextStyle(color: Theme.of(context).colorScheme.secondary);
      widgets.add(
        TableRow(
          children:
              [
                    element.major,
                    element.gpa,
                    element.credits,
                    element.rank,
                    // The fetched GPA lists are usually sorted.
                    "${(100 * ordinal / gpaList.length).toStringAsFixed(2)}%",
                  ]
                  .map(
                    (itemText) => Text(
                      itemText,
                      textAlign: TextAlign.center,
                      style: textColorStyle,
                    ),
                  )
                  .toList(),
        ),
      );
    }
    return widgets;
  }
}
