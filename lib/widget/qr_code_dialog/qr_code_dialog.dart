/*
 *     Copyright (C) 2021  w568w
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

import 'dart:ui';

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

class QR {
  static void showQRCode(
      BuildContext context, PersonInfo personInfo, double brightness) {
    //Set screen brightness for displaying QR Code
    ScreenProxy.keepOn(true);
    ScreenProxy.setBrightness(1.0);

    //Get current theme (light/dark)
    bool darkModeOn =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => QRDialog(
              personInfo: personInfo,
              originBrightness: brightness,
            ));
  }

  //watchOS Support
  static const channel = const MethodChannel('watchQRValue');

  static Future<void> sendQRtoWatch(PersonInfo personInfo) async {
    String qr = await QRCodeRepository.getInstance().getQRCode(personInfo);

    channel.invokeMethod("sendStringToNative", qr.toString());
  }
}

class QRDialog extends StatefulWidget {
  final PersonInfo personInfo;
  final double originBrightness;

  const QRDialog({Key key, this.personInfo, this.originBrightness})
      : super(key: key);

  @override
  _QRDialogState createState() => _QRDialogState();
}

class _QRDialogState extends State<QRDialog> {
  ConnectionStatus _status = ConnectionStatus.NONE;

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).fudan_qr_code),
      content: GestureDetector(
          onTap: () {
            if (_status == ConnectionStatus.FAILED) {
              _status = ConnectionStatus.NONE;
              print("refreshing...");
              refreshSelf();
            }
          },
          child: Container(
              width: double.maxFinite,
              height: 200.0,
              child: Center(
                  child: FutureBuilder<String>(
                      future: QRCodeRepository.getInstance()
                          .getQRCode(widget.personInfo),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        print(
                            "building... ${snapshot.hasData},${snapshot.hasError},${_status}");
                        if (snapshot.hasData) {
                          _status = ConnectionStatus.DONE;
                          return QrImage(
                            data: snapshot.data,
                            size: 200.0,
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                          );
                        } else if (snapshot.hasError &&
                            _status == ConnectionStatus.CONNECTING) {
                          _status = ConnectionStatus.FAILED;
                          return Text(S.of(context).failed);
                        } else {
                          _status = ConnectionStatus.CONNECTING;
                          return Text(S.of(context).loading_qr_code);
                        }
                      })))),
      actions: <Widget>[
        PlatformDialogAction(
            child: PlatformText(S.of(context).i_see),
            onPressed: () {
              ScreenProxy.setBrightness(widget.originBrightness);
              ScreenProxy.keepOn(false);
              Navigator.pop(context);
            }),
      ],
    );
  }
}
