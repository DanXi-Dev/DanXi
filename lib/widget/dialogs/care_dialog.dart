import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/widget/forum/post_render.dart';
import 'package:dan_xi/widget/forum/render/render_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../generated/l10n.dart';

class CareDialog extends StatefulWidget {
  const CareDialog({super.key});

  @override
  State<CareDialog> createState() => _CareDialogState();
}

class _CareDialogState extends State<CareDialog> {
  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).danxi_care),
      content: SingleChildScrollView(
          child: PostRenderWidget(
        content: S.of(context).danxi_care_message,
        render: kMarkdownRender,
        onTapLink: (url) => BrowserUtil.openUrl(url!, null),
        hasBackgroundImage: false,
      )),
      actions: [
        PlatformDialogAction(
          child: Text(S.of(context).i_see),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }
}
