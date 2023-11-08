import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ReportInfo {
  int floorId;
  String reason;

  ReportInfo({required this.floorId, required this.reason});
}

Future<bool> reportPost(BuildContext context, int? floorId) async {
  final dynamic result =
      await smartNavigatorPush(context, '/bbs/report', arguments: {
    "floor_id": floorId,
  });

  if (result == null) return false;

  try {
    final report = result! as ReportInfo;
    await OpenTreeHoleRepository.getInstance()
        .reportPost(report.floorId, report.reason);
  } catch (error, st) {
    Noticing.showErrorDialog(context, error,
        trace: st, title: S.of(context).report_failed);
    return false;
  }
  return true;
}

var reasons = ["YP", "不知道", "闲的无聊", "不需要理由"];

/// An full-screen editor page.
///
/// Arguments:
/// [bool] tags: whether to show a tag selector, default false
/// [String] title: the page's title, default "Post"
///
/// Callback:
/// [PostEditorText] The editor text.
class BBSReportPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSReportPage({Key? key, this.arguments}) : super(key: key);

  @override
  BBSReportPageState createState() => BBSReportPageState();
}

class BBSReportPageState extends State<BBSReportPage> {
  final _controller = TextEditingController();

  static const String CUSTOM_REASON = "Custom";

  late int _floorId;
  late String _title;
  String? _reason;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _floorId = widget.arguments!['floor_id'];
    _title = widget.arguments!['title'] ?? "举报 #$_floorId";
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                const Text("请选择举报理由", style: TextStyle(fontSize: 24)),
                const Divider(),
                Card(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reasons.map((e) => RadioListTile<String>(
                        title: Text(e),
                        value: e,
                        groupValue: _reason,
                        onChanged: (String? value) {
                          setState(() {
                            _reason = value;
                            _reason = value ?? "";
                          });
                        })),
                    RadioListTile<String>(
                        title: const Text("其他原因"),
                        subtitle: Container(
                            padding: const EdgeInsets.only(bottom: 10),
                            height: 40,
                            child: PlatformTextField(
                              autofocus: false,
                              keyboardType: TextInputType.text,
                              controller: _controller,
                              // todo placeholder language
                              hintText: "请输入原因",
                              style: const TextStyle(fontSize: 14),
                              onChanged: (text) {
                                if (text.isNotEmpty) {
                                  setState(() {
                                    _reason = CUSTOM_REASON;
                                  });
                                }
                              },
                            )),
                        value: CUSTOM_REASON,
                        groupValue: _reason,
                        onChanged: (String? value) {
                          setState(() {
                            _reason = value;
                          });
                        })
                  ],
                ))
              ]))),
    );
  }

  Future<void> _sendDocument() async {
    final finalReason = _reason == CUSTOM_REASON ? _controller.text : _reason;
    if (finalReason == null || finalReason.isEmpty) return;

    final report = ReportInfo(floorId: _floorId, reason: finalReason);

    Navigator.pop<ReportInfo>(context, report);
  }
}
