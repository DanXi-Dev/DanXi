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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/qr_code_repository.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

    showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => QRDialog(
              personInfo: personInfo,
            ));
  }

  //watchOS Support
  static const channel = const MethodChannel('watchQRValue');

  static Future<void> sendQRtoWatch(PersonInfo personInfo) async {
    String? qr = await QRCodeRepository.getInstance().getQRCode(personInfo);

    channel.invokeMethod("sendStringToNative", qr.toString());
  }
}

class QRDialog extends StatefulWidget {
  final PersonInfo? personInfo;

  const QRDialog({Key? key, this.personInfo}) : super(key: key);

  @override
  _QRDialogState createState() => _QRDialogState();
}

class _QRDialogState extends State<QRDialog> {
  ConnectionStatus _status = ConnectionStatus.NONE;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(S.of(context)!.fudan_qr_code),
        content: GestureDetector(
            onTap: () {
              if (_status == ConnectionStatus.FAILED) {
                _status = ConnectionStatus.NONE;
                refreshSelf();
              }
            },
            child: Container(
                width: double.maxFinite,
                height: 200.0,
                child: Center(
                    child: FutureBuilder<String?>(
                        future: QRCodeRepository.getInstance()
                            .getQRCode(widget.personInfo),
                        builder: (BuildContext context,
                            AsyncSnapshot<String?> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.none:
                            case ConnectionState.waiting:
                            case ConnectionState.active:
                              return Text(S.of(context).loading_qr_code);
                            case ConnectionState.done:
                              if (snapshot.hasError) {
                                _status = ConnectionStatus.FAILED;
                                return Text(S.of(context).fail_to_acquire_qr);
                              } else {
                                _status = ConnectionStatus.DONE;
                                return QrImage(
                                  data: snapshot.data!,
                                  size: 200.0,
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                );
                              }
                          }
                        })))),
        actions: <Widget>[
          TextButton(
              child: PlatformText(S.of(context)!.i_see),
              onPressed: () async {
                ScreenProxy.resetBrightness();
                //ScreenProxy.keepOn(false);
                Navigator.pop(context);
              }),
        ],
      );
}
