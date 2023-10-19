import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/punishment.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

Future<bool> showAdminOperation(
    BuildContext context, List<OTFloor> floors) async {
  final dynamic result =
      await smartNavigatorPush(context, '/bbs/admin', arguments: {
    "floors": floors,
  });

  if (result == null) return false;

  try {} catch (e, st) {
    Noticing.showErrorDialog(context, e,
        trace: st, title: S.of(context).reply_failed);
    return false;
  }
  return true;
}

class AdminOperationPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const AdminOperationPage({Key? key, this.arguments}) : super(key: key);

  @override
  AdminOperationPageState createState() => AdminOperationPageState();
}

class AdminOperationPageState extends State<AdminOperationPage> {
  late List<OTFloor> _floors;
  // Don't show penalty menu if multi-floor
  late bool _isSingleFloor;
  late String _title;
  FileImage? _backgroundImage;
  List<String>? _punishments;
  late TextEditingController _reasonController;
  final ValueNotifier<bool> _punishUser = ValueNotifier(false);
  final ValueNotifier<int> _punishmentDays = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    _title =
        widget.arguments!['title'] ?? S.of(context).forum_post_enter_content;
    _floors = widget.arguments!['floors']!;
    _isSingleFloor = _floors.length == 1;

    super.didChangeDependencies();
  }

  Future<List<String>> getPunishmentHistory() async {
    _punishments ??= await OpenTreeHoleRepository.getInstance()
        .adminGetPunishmentHistory(_floors.first.floor_id!);

    return _punishments!;
  }

  @override
  Widget build(BuildContext context) {
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;

    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(_title),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: PlatformX.isMaterial(context)
                ? const Icon(Icons.send)
                : const Icon(CupertinoIcons.paperplane),
            onPressed: () async => _sendDocument(),
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
                  ExpansionTileX(
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    expandedAlignment: Alignment.topLeft,
                    childrenPadding: const EdgeInsets.symmetric(vertical: 4),
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: true,
                    title: const Row(
                      children: [
                        Icon(CupertinoIcons.text_alignleft),
                        SizedBox(width: 8),
                        Text("查看将删除的内容")
                      ],
                    ),
                    children: [
                      ..._floors.map((e) => OTFloorWidget(
                          floor: e,
                          showBottomBar: false,
                          hasBackgroundImage: _backgroundImage != null))
                    ],
                  ),
                  const Divider(),
                  PlatformTextField(
                    hintText: "输入删帖理由",
                    material: (_, __) => MaterialTextFieldData(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(gapPadding: 2.0))),
                    keyboardType: TextInputType.multiline,
                    maxLines: 1,
                    expands: false,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (text) {},
                    controller: _reasonController,
                  ),
                  const Divider(),
                  if (_isSingleFloor) ...[
                    Card(
                        child: Column(children: [
                      ValueListenableBuilder(
                          valueListenable: _punishUser,
                          builder: (context, value, child) =>
                              SwitchListTile.adaptive(
                                title: const Text("封禁用户"),
                                secondary: const Icon(CupertinoIcons.nosign),
                                value: _punishUser.value,
                                onChanged: (bool value) {
                                  _punishUser.value = value;
                                },
                              )),
                      ValueListenableBuilder(
                          valueListenable: _punishmentDays,
                          builder: (context, value, child) => SpinBoxTile(
                                secondary: const Icon(CupertinoIcons.calendar),
                                title: Text("封禁时长: ${_punishmentDays.value}"),
                                onChanged: (int delta) {
                                  _punishmentDays.value =
                                      (_punishmentDays.value + delta)
                                          // PS: I admit this is ugly
                                          .clamp(0, 0x7fffffff);
                                },
                              )),
                    ])),
                    const Divider(),
                    FutureWidget<List<String>>(
                      future: getPunishmentHistory(),
                      loadingBuilder: Center(
                        child: PlatformCircularProgressIndicator(),
                      ),
                      successBuilder: (BuildContext context,
                          AsyncSnapshot<List<String>> snapshot) {
                        return ExpansionTileX(
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            expandedAlignment: Alignment.topLeft,
                            childrenPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            tilePadding: EdgeInsets.zero,
                            initiallyExpanded: false,
                            title: Row(
                              children: [
                                const Icon(CupertinoIcons.person_badge_minus),
                                const SizedBox(width: 8),
                                Text("违规记录: ${snapshot.data!.length} 条")
                              ],
                            ),
                            children: [
                              ...snapshot.data!.map(
                                  (e) => Card(child: ListTile(title: Text(e))))
                            ]);
                      },
                      errorBuilder: () => Icon(
                        PlatformIcons(context).error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ]
                ],
              )))),
    );
  }

  Future<void> _sendDocument() async {
    Navigator.pop<OTPunishment>(context, null);
  }
}

/// Same to SwitchListTile, the widget itself doesn't maintain any state
/// The value is passed and modified via [onChanged] and [value]
class SpinBoxTile extends StatelessWidget {
  final int? value;
  final Widget? secondary;
  final Widget? title;
  // Parameter is
  final void Function(int) onChanged;

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
                  onPressed: () => onChanged(-1)),
              const Divider(),
              IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 15,
                  padding: EdgeInsets.zero,
                  onPressed: () => onChanged(1)),
            ],
          )),
    );
  }
}
