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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/fdu/qr_code_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'qr_code_dialog.g.dart';

/// A dialog to show Fudan QR code.
class QRHelper {
  static Future<void> showQRCode(BuildContext context) async {
    try {
      ScreenProxy.setBrightness(1.0);
      await showPlatformDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => QRDialog());
    } finally {
      ScreenProxy.resetBrightness();
    }
  }
}

@riverpod
Future<String> qrCode(Ref ref) async {
  return await QRCodeRepository.getInstance().getQRCode();
}

class QRDialog extends HookConsumerWidget {
  const QRDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool termsNotAgreed = false;
    final qrCode = ref.watch(qrCodeProvider);

    Widget body;

    switch (qrCode) {
      case AsyncData(:final value):
        body = QrImageView(
            data: value, size: 200.0, backgroundColor: Colors.white);
      case AsyncLoading():
        body = Text(S.of(context).loading_qr_code);
      case AsyncError(:final error, :final stackTrace):
        if (error is TermsNotAgreed) {
          termsNotAgreed = true;
          body = Text(S.of(context).qr_code_terms_not_agreed);
        } else {
          body = ErrorPageWidget.buildWidget(context, error,
              stackTrace: stackTrace, onTap: () => ref.refresh(qrCodeProvider));
        }
      case _:
        body = const SizedBox.shrink();
    }

    return PlatformAlertDialog(
      title: Text(S.of(context).fudan_qr_code),
      content: SizedBox(
          width: double.maxFinite, height: 200.0, child: Center(child: body)),
      actions: <Widget>[
        TextButton(
            child: PlatformText(S.of(context).i_see),
            onPressed: () async {
              Navigator.pop(context);
              if (termsNotAgreed) {
                BrowserUtil.openUrl(
                    QRCodeRepository.QR_URL, context, null, true);
              }
            }),
      ],
    );
  }
}
