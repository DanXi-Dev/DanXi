import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/history.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_operation.g.dart';

class AdminOperationInfo {
  int floorId;
  bool isDelete;
  bool doPenalty;
  int penaltyDays;
  String reason;

  AdminOperationInfo(
      {required this.floorId,
      required this.isDelete,
      required this.doPenalty,
      required this.penaltyDays,
      required this.reason});
}

@riverpod
Future<List<String>> punishmentHistory(Ref ref, int floorId) async {
  return (await ForumRepository.getInstance()
      .adminGetPunishmentHistory(floorId))!;
}

@riverpod
Future<List<OTHistory>> modifyHistory(Ref ref, int floorId) async {
  return (await ForumRepository.getInstance().getHistory(floorId))!;
}

@riverpod
Future<List<(String, DateTime)>> userPunishmentStatus(
    Ref ref, int floorId) async {
  final divisions = ForumProvider.getInstance().divisionCache;

  final mapResult = (await ForumRepository.getInstance()
      .adminGetUserSilenceByFloorId(floorId))!;
  final result = <(String, DateTime)>[];
  for (final entry in mapResult.entries) {
    try {
      final division =
          divisions.firstWhere((d) => d.division_id.toString() == entry.key);
      result.add((division.name!, DateTime.parse(entry.value)));
    } catch (_) {
      result.add((entry.key, DateTime.parse(entry.value)));
    }
  }
  return result;
}

Future<bool> showAdminOperation(BuildContext context, OTFloor floor) async {
  final dynamic result = await smartNavigatorPush(context, '/bbs/admin',
      arguments: AdminOperationPageArguments(floor: floor));

  if (result == null) return false;

  try {
    final operation = result! as AdminOperationInfo;
    int? response;
    if (operation.isDelete) {
      response = await ForumRepository.getInstance().adminDeleteFloor(
          operation.floorId, operation.reason.isEmpty ? "" : operation.reason);
    } else {
      response = await ForumRepository.getInstance().adminFoldFloor(
          operation.reason.isEmpty ? [] : [operation.reason],
          operation.floorId);
    }

    if (response == null || response >= 300) {
      throw Exception(
          "Request for deleting post #${operation.floorId} failed! ");
    }

    if (operation.doPenalty && operation.penaltyDays > 0) {
      response = await ForumRepository.getInstance()
          .adminAddPenaltyDays(operation.floorId, operation.penaltyDays);
      if (response == null || response >= 300) {
        throw Exception("Request for adding penalty failed! ");
      }
    }
  } catch (e, st) {
    if (context.mounted) {
      Noticing.showErrorDialog(context, e,
          trace: st, title: S.of(context).reply_failed);
    }
    return false;
  }
  return true;
}

class AdminOperationPageArguments {
  final OTFloor floor;
  final String? title;

  AdminOperationPageArguments({required this.floor, this.title});
}

class AdminOperationPage extends HookConsumerWidget {
  final AdminOperationPageArguments arguments;

  const AdminOperationPage({super.key, required this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floor = arguments.floor;
    final title = arguments.title ?? S.of(context).forum_post_enter_content;
    final backgroundImage =
        useState<FileImage?>(SettingsProvider.getInstance().backgroundImage);
    final reasonController = useTextEditingController();
    final punishUser = useState<bool>(false);
    final deletePost = useState<bool>(true);
    final punishmentDays = useState<int>(0);

    final punishmentHistoryAsync =
        ref.watch(punishmentHistoryProvider(floor.floor_id!));
    final modifyHistoryAsync =
        ref.watch(modifyHistoryProvider(floor.floor_id!));
    final userPunishmentStatusAsync =
        ref.watch(userPunishmentStatusProvider(floor.floor_id!));

    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(title),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: PlatformX.isMaterial(context)
                ? const Icon(Icons.send)
                : const Icon(CupertinoIcons.paperplane),
            onPressed: () async => _sendDocument(
              context: context,
              floor: floor,
              deletePost: deletePost.value,
              punishUser: punishUser.value,
              punishmentDays: punishmentDays.value,
              reasonText: reasonController.text,
            ),
          ),
        ],
      ),
      body: SafeArea(
          bottom: false,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    OTFloorWidget(
                        floor: floor,
                        showToolBars: false,
                        hasBackgroundImage: backgroundImage.value != null),
                    const Divider(),
                    _buildFoldedList(
                      context: context,
                      asyncValue: modifyHistoryAsync,
                      itemBuilder: (e) => OTFloorWidget(
                          hasBackgroundImage: false,
                          floor: floor.copyWith(
                              content: e.content,
                              time_created: e.time_updated,
                              deleted: false)),
                      text: "历史修改",
                      onRetry: () => ref
                          .invalidate(modifyHistoryProvider(floor.floor_id!)),
                    ),
                    const Divider(),
                    PlatformTextField(
                      hintText: "输入删帖/折叠理由",
                      material: (_, __) => MaterialTextFieldData(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(gapPadding: 2.0))),
                      keyboardType: TextInputType.multiline,
                      maxLines: 1,
                      expands: false,
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.top,
                      controller: reasonController,
                    ),
                    const Divider(),
                    Card(
                        child: Column(children: [
                      ListTile(
                        title: const Text("帖子操作"),
                        leading: const Icon(CupertinoIcons.hand_draw),
                        subtitle: Text(deletePost.value ? "删除" : "折叠"),
                        onTap: () => showPlatformModalSheet(
                            context: context,
                            builder: (BuildContext context) =>
                                PlatformContextMenu(
                                    actions: [
                                      PlatformContextMenuItem(
                                        menuContext: context,
                                        child: const Text("删除"),
                                        onPressed: () =>
                                            deletePost.value = true,
                                      ),
                                      PlatformContextMenuItem(
                                        menuContext: context,
                                        child: const Text("折叠"),
                                        onPressed: () =>
                                            deletePost.value = false,
                                      )
                                    ],
                                    cancelButton: CupertinoActionSheetAction(
                                        child: Text(S.of(context).cancel),
                                        onPressed: () =>
                                            Navigator.of(context).pop()))),
                      ),
                      SwitchListTile.adaptive(
                        title: const Text("封禁用户"),
                        secondary: const Icon(CupertinoIcons.nosign),
                        value: punishUser.value,
                        onChanged: (bool value) {
                          punishUser.value = value;
                          if (!punishUser.value) {
                            punishmentDays.value = 0;
                          } else if (punishmentDays.value == 0) {
                            punishmentDays.value = 1;
                          }
                        },
                      ),
                      SpinBoxTile(
                        secondary: const Icon(CupertinoIcons.calendar),
                        title: Text("封禁时长: ${punishmentDays.value} 天"),
                        onChanged: punishUser.value
                            ? (int delta) {
                                punishmentDays.value =
                                    (punishmentDays.value + delta)
                                        .clamp(1, 10000);
                              }
                            : null,
                      ),
                    ])),
                    const Divider(),
                    _buildFoldedList(
                      context: context,
                      asyncValue: punishmentHistoryAsync,
                      itemBuilder: (e) => Card(child: ListTile(title: Text(e))),
                      text: "违规记录",
                      onRetry: () => ref.invalidate(
                          punishmentHistoryProvider(floor.floor_id!)),
                    ),
                    _buildFoldedList(
                      context: context,
                      asyncValue: userPunishmentStatusAsync,
                      itemBuilder: (e) => Card(
                          child: ListTile(
                              title: Text("分区: ${e.$1}，封禁时间至: ${e.$2}"))),
                      text: "当前封禁状态",
                      onRetry: () => ref.invalidate(
                          punishmentHistoryProvider(floor.floor_id!)),
                    ),
                  ])))),
    );
  }

  Future<void> _sendDocument({
    required BuildContext context,
    required OTFloor floor,
    required bool deletePost,
    required bool punishUser,
    required int punishmentDays,
    required String reasonText,
  }) async {
    String confirmationText =
        "您将要${deletePost ? '删除' : '折叠'}帖子 #${floor.floor_id}, ";
    if (punishUser) {
      confirmationText += "\n并处以 $punishmentDays 天的封禁, ";
    }
    confirmationText += "\n确定吗? ";

    bool? confirmed = await Noticing.showConfirmationDialog(
        context, confirmationText,
        isConfirmDestructive: true);
    if (confirmed != true) {
      return;
    }

    final op = AdminOperationInfo(
        doPenalty: punishUser,
        floorId: floor.floor_id!,
        penaltyDays: punishmentDays,
        isDelete: deletePost,
        reason: reasonText);

    if (!context.mounted) return;
    Navigator.pop<AdminOperationInfo>(context, op);
  }

  Widget _buildFoldedList<T>({
    required BuildContext context,
    required AsyncValue<List<T>> asyncValue,
    required Widget Function(T) itemBuilder,
    required String text,
    required VoidCallback onRetry,
    bool initiallyExpanded = false,
  }) {
    return switch (asyncValue) {
      AsyncData(:final value) => ExpansionTileX(
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          childrenPadding: const EdgeInsets.symmetric(vertical: 4),
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: initiallyExpanded,
          title: Row(
            children: [
              const Icon(CupertinoIcons.person_badge_minus),
              const SizedBox(width: 8),
              Text("$text: ${value.length} 条")
            ],
          ),
          children: [...value.map(itemBuilder)],
        ),
      AsyncError(:final error) => ListTile(
          leading: Icon(
            PlatformIcons(context).error,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text("$text: 加载失败"),
          subtitle: Text(ErrorPageWidget.generateUserFriendlyDescription(
              S.of(context), error)),
          onTap: onRetry,
        ),
      _ => ListTile(
          leading: PlatformCircularProgressIndicator(),
          title: Text("$text: 加载中..."),
        ),
    };
  }
}

/// Same to SwitchListTile, the widget itself doesn't maintain any state
/// The value is passed and modified via [onChanged] and [value]
class SpinBoxTile extends StatelessWidget {
  final int? value;
  final Widget? secondary;
  final Widget? title;

  // Parameter is
  final void Function(int)? onChanged;

  const SpinBoxTile(
      {super.key,
      this.secondary,
      this.title,
      this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: secondary,
      title: title,
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      trailing: Card(
          color: Theme.of(context).secondaryHeaderColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: const Icon(Icons.remove),
                  iconSize: 15,
                  padding: EdgeInsets.zero,
                  onPressed: onChanged != null ? () => onChanged!(-1) : null),
              const Divider(),
              IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 15,
                  padding: EdgeInsets.zero,
                  onPressed: onChanged != null ? () => onChanged!(1) : null),
            ],
          )),
    );
  }
}
