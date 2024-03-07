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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/fdu/qr_code_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A dialog to show Fudan QR code.
///
/// Also contains methods to send qr code to Apple Watch.
class QRHelper {
  static Future<void> showQRCode(
      BuildContext context, PersonInfo? personInfo) async {
    //Set screen brightness for displaying QR Code
    //ScreenProxy.keepOn(true);
    ScreenProxy.setBrightness(1.0);

    await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => QRDialog(personInfo: personInfo));
    ScreenProxy.resetBrightness();
    //ScreenProxy.keepOn(false);
  }
}

class QRDialog extends StatefulWidget {
  final PersonInfo? personInfo;

  const QRDialog({super.key, this.personInfo});

  @override
  QRDialogState createState() => QRDialogState();
}

class QRDialogState extends State<QRDialog> {
  bool termsNotAgreed = false;

  @override
  Widget build(BuildContext context) => PlatformAlertDialog(
        title: Text(S.of(context).fudan_qr_code),
        content: SizedBox(
            width: double.maxFinite,
            height: 200.0,
            child: Center(
              child: FutureWidget<String?>(
                future: LazyFuture.pack(QRCodeRepository.getInstance()
                    .getQRCode(widget.personInfo)),
                successBuilder: (_, snapshot) {
                  return QrImageView(
                      data: snapshot.data!,
                      size: 200.0,
                      // foregroundColor: Colors.black,
                      backgroundColor: Colors.white);
                },
                loadingBuilder: Text(S.of(context).loading_qr_code),
                errorBuilder:
                    (BuildContext context, AsyncSnapshot<String?> snapShot) {
                  if (snapShot.error is TermsNotAgreed) {
                    termsNotAgreed = true;
                    return Text(S.of(context).qr_code_terms_not_agreed);
                  } else {
                    return ErrorPageWidget.buildWidget(context, snapShot.error,
                        stackTrace: snapShot.stackTrace,
                        onTap: () => refreshSelf());
                  }
                },
              ),
            )),
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
