import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../../generated/l10n.dart';

class CareDialog extends StatefulWidget {
  const CareDialog({Key? key}) : super(key: key);

  @override
  State<CareDialog> createState() => _CareDialogState();
}

class _CareDialogState extends State<CareDialog> {
  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).danxi_care),
      content: Text(S.of(context).danxi_care_message),
      actions: [
        PlatformDialogAction(
          child: const Text("OK"),
          onPressed: ()=>{Navigator.of(context).pop()},
        )
      ],
    );
  }
}
