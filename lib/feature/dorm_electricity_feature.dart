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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/fdu/data_center_repository.dart';
import 'package:dan_xi/repository/fdu/dorm_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dorm_electricity_feature.g.dart';

/// Every feature should extends [Feature]. You may find
/// `lib/feature/base_feature.dart` helpful.
///
/// Generally to implement a feature, you should do the following things:
/// - Set bool [clickable] to true if needed. Most features are clickable. Override
///   [onTap] if you want to do something when user taps the feature.
/// - Set bool [loadOnTap] to false if you want to load data immediately.
///   If you do so, [buildFeature] will not be called until user first tap the
///   feature.
/// - Set [icon] to an [Icon] if needed. Select one from [Icons] or [CupertinoIcons]
///   as you like.
/// - Set [mainTitle] to a [String] if needed. The main title of a feature is
///   usually the name of the feature, which remains unchanged.
/// - Set [subTitle] to a [String] if needed. You can display information here.
/// - Override [buildFeature].
/// - Refer to `lib/feature/base_feature.dart` for more details.
///
/// If the feature relates to a network request, you should do the following things:
/// - Create a repository in `lib/repository/` if needed. See `lib/repository/base_repository.dart`.
///   You may find the extensive comments in `lib/repository/fdu/dorm_repository.dart`
///   helpful.
/// - You can initialize a [ConnectionStatus] variable to [ConnectionStatus.NONE]
///   to indicate the connection status. Call [notifyUpdate] when the request is done.
class DormElectricityFeature extends Feature {
  /// The data instance. See `lib/repository/fdu/dorm_repository.dart`.
  ElectricityItem? _electricity;

  Future<void> _loadData() async {
    status = const ConnectionConnecting();
    try {
      // Await the repository to load data.
      _electricity =
          await FudanDormRepository.getInstance().loadElectricityInfo();
      status = const ConnectionDone();
    } catch (error, stackTrace) {
      status = ConnectionFailed(error, stackTrace);
    }
    // Remember to call [notifyUpdate] to update the widget.
    notifyUpdate();
  }

  /// Load data when the feature is created.
  ///
  /// Only load data once.
  /// If user needs to refresh the data, [refreshSelf] will be called on the whole
  /// page, not just on [FeatureContainer]. The feature will be recreated then.
  ///
  /// If the feature is [loadOnTap], [buildFeature] will be called when user taps.
  /// Otherwise, [buildFeature] will be called when the feature is created.
  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    if (status is ConnectionNone) {
      _electricity = null;
      _loadData();
    }
  }

  /// the Main title of the feature, usually to be the name of the feature. We
  /// use [S] to support i18n.
  @override
  String get mainTitle => S.of(context!).dorm_electricity;

  /// The subtitle of the feature. We usually display the data here.
  @override
  String get subTitle {
    switch (status) {
      case ConnectionNone():
      case ConnectionConnecting():
        return S.of(context!).loading;
      case ConnectionDone():
        return S.of(context!).dorm_electricity_subtitle(
            _electricity!.available, _electricity!.used);
      case ConnectionFailed():
      case ConnectionFatalError():
        return S.of(context!).failed;
    }
  }

  /// The tertiary title of the feature. We usually display the loading progress
  /// here. Some features have a button here to navigate to a new page or do
  /// something else. See [WelcomeFeature] and [NextCourseFeature].
  @override
  Widget? get trailing {
    if (status is ConnectionConnecting) {
      return const FeatureProgressIndicator();
    }
    return null;
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.bolt)
      : const Icon(CupertinoIcons.bolt);

  void refreshData() {
    status = const ConnectionNone();
    notifyUpdate();
  }

  /// Be careful that [onTap] will not be called if the feature does not have
  /// it's first tap when [loadOnTap] is true.
  ///
  /// If you want to do something when user taps the feature, override this method.
  /// A typical example is to show a modal dialog, navigate to a new page via
  /// [smartNavigatorPush] or reload the data when it failed.
  @override
  void onTap() {
    if (status is ConnectionDone) {
      final content =
          DormElectricityModalSheet(currentElectricity: _electricity!);
      final Widget body;
      if (PlatformX.isCupertino(context!)) {
        body = SafeArea(child: Card(child: content));
      } else {
        body = SafeArea(child: content);
      }
      showPlatformModalSheet(context: context!, builder: (_) => body);
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}

// keepAlive: make the data persistent even if the sheet is closed.
@Riverpod(keepAlive: true)
Future<List<ElectricityHistoryItem>> electricityHistory(
    Ref ref, int offset, int size) async {
  return await DataCenterRepository.getInstance()
      .getElectricityHistory(offset, size);
}

class DormElectricityModalSheet extends HookConsumerWidget {
  final ElectricityItem currentElectricity;

  const DormElectricityModalSheet(
      {super.key, required this.currentElectricity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(electricityHistoryProvider(0, 30));

    final Widget chart;
    switch (history) {
      case AsyncData(:final value):
        if (value.isEmpty) {
          chart = Text(S.of(context).no_data);
        } else {
          final ascendingValue = value.reversed.toList();
          final spots = ascendingValue
              .mapIndexed((index, e) =>
                  FlSpot(index.toDouble(), double.parse(e.amount)))
              .toList();
          chart = LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= ascendingValue.length) {
                        return const SizedBox.shrink();
                      }
                      final date = ascendingValue[index].date;
                      final parsedDate = DateTime.tryParse(date);
                      final formatter = DateFormat("MM/dd");
                      final formattedDate =
                          parsedDate.apply(formatter.format) ?? "??/??";
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(formattedDate,
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text("kWh"),
                  sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (_, meta) {
                        return Text(
                          meta.formattedValue,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.end,
                        );
                      }),
                ),
                // remove right and top titles
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (_, __) => const SizedBox.shrink())),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, horizontalInterval: 5),
              lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    Theme.of(context).colorScheme.primaryContainer,
              )),
              minY: 0,
            ),
          );
        }
      case AsyncError(:final error, :final stackTrace):
        chart = ErrorPageWidget.buildWidget(context, error,
            stackTrace: stackTrace,
            onTap: () => ref.invalidate(electricityHistoryProvider(0, 30)));
      case _:
        chart = Center(child: PlatformCircularProgressIndicator());
    }

    var detailText =
        "${currentElectricity.dormName}\n${S.of(context).dorm_electricity_subtitle(currentElectricity.available, currentElectricity.used)}";
    if (currentElectricity.updateTime.isNotEmpty) {
      detailText +=
          "\n${S.of(context).last_updated(currentElectricity.updateTime)}";
    }

    const refreshIcon = Icon(Icons.refresh);
    final rotatingAnimation =
        useAnimationController(duration: const Duration(seconds: 1))..repeat();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(S.of(context).dorm_electricity),
          subtitle: Text(detailText),
        ),
        ListTile(
            title: Text(S.of(context).dorm_electricity_history),
            trailing: PlatformIconButton(
              icon: history.isLoading
                  ? AnimatedBuilder(
                      animation: rotatingAnimation,
                      builder: (context, child) => Transform.rotate(
                          angle: rotatingAnimation.value * 2 * pi,
                          child: child),
                      child: refreshIcon,
                    )
                  : refreshIcon,
              onPressed: history.isLoading
                  ? null
                  : () => ref.invalidate(electricityHistoryProvider(0, 30)),
            )),
        ConstrainedBox(
            constraints: BoxConstraints.loose(Size.fromHeight(200)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: chart,
            ))
      ],
    );
  }
}
