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
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Simple helper class to show a notice,
/// like [SnackBar] on Material or a [CupertinoAlertDialog] on Cupertino.
class Noticing {
  static showNotice(BuildContext context, String message,
      {String? confirmText,
      String? title,
      bool useSnackBar = true,
      bool? centerContent}) async {
    centerContent ??= !PlatformX.isMaterial(context);
    if (PlatformX.isMaterial(context) && useSnackBar) {
      // Override Linkify's default text style.
      final bool isThemeDark = Theme.of(context).brightness == Brightness.dark;
      final Brightness invertBrightness =
          isThemeDark ? Brightness.light : Brightness.dark;
      final TextStyle? contentTextStyle =
          Theme.of(context).snackBarTheme.contentTextStyle ??
              ThemeData(brightness: invertBrightness).textTheme.subtitle1;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Linkify(
        style: contentTextStyle,
        text: message,
        onOpen: (element) => BrowserUtil.openUrl(element.url, context),
      )));
    } else {
      await showPlatformDialog(
          context: context,
          builder: (BuildContext context) => PlatformAlertDialog(
                title: title == null ? null : Text(title),
                content: centerContent!
                    ? Center(
                        child: Linkify(
                        textAlign:
                            centerContent ? TextAlign.center : TextAlign.start,
                        text: message,
                        onOpen: (element) =>
                            BrowserUtil.openUrl(element.url, context),
                      ))
                    : Linkify(
                        textAlign:
                            centerContent ? TextAlign.center : TextAlign.start,
                        text: message,
                        onOpen: (element) =>
                            BrowserUtil.openUrl(element.url, context),
                      ),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(confirmText ?? S.of(context).i_see),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
  }

  static showModalError(BuildContext context, dynamic error,
      {StackTrace? trace,
      String? title,
      bool useSnackBar = false,
      bool? centerContent}) {
    title ??= S.of(context).fatal_error;
    return Noticing.showNotice(
        context,
        ErrorPageWidget.generateUserFriendlyDescription(S.of(context), error,
            stackTrace: trace),
        title: title,
        useSnackBar: useSnackBar,
        centerContent: centerContent);
  }

  static Future<String?> showInputDialog(BuildContext context, String title,
      {String? confirmText,
      bool isConfirmDestructive = false,
      int? maxLines,
      String? hintText}) async {
    TextEditingController controller = TextEditingController();
    return await showPlatformDialog<String?>(
      context: context,
      builder: (BuildContext context) => PlatformAlertDialog(
        title: Text(title),
        content: PlatformTextField(
          controller: controller,
          maxLines: maxLines,
          hintText: hintText,
          onSubmitted: (value) {
            Navigator.pop(context, value);
            controller.dispose();
          },
        ),
        actions: <Widget>[
          PlatformDialogAction(
              child: PlatformText(S.of(context).cancel),
              onPressed: () {
                Navigator.pop(context, null);
                controller.dispose();
              }),
          PlatformDialogAction(
              cupertino: (context, platform) => CupertinoDialogActionData(
                  isDestructiveAction: isConfirmDestructive,
                  isDefaultAction: true),
              material: (context, platform) => MaterialDialogActionData(
                  style: isConfirmDestructive
                      ? ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.red))
                      : null),
              child: PlatformText(confirmText ?? S.of(context).i_see),
              onPressed: () {
                Navigator.pop(context, controller.text);
                controller
                    .dispose(); // TODO: dispose() is called before state is destroyed. how to resolve this?
              }),
        ],
      ),
    );
  }

  static Future<bool?> showConfirmationDialog(
      BuildContext context, String message,
      {String? confirmText,
      String? title,
      bool isConfirmDestructive = false,
      bool? centerContent}) async {
    centerContent ??= !PlatformX.isMaterial(context);
    return await showPlatformDialog<bool>(
        context: context,
        builder: (BuildContext context) => PlatformAlertDialog(
              title: title == null ? null : Text(title),
              content: centerContent!
                  ? Center(
                      child: Linkify(
                      textAlign:
                          centerContent ? TextAlign.center : TextAlign.start,
                      text: message,
                      onOpen: (element) =>
                          BrowserUtil.openUrl(element.url, context),
                    ))
                  : Linkify(
                      textAlign:
                          centerContent ? TextAlign.center : TextAlign.start,
                      text: message,
                      onOpen: (element) =>
                          BrowserUtil.openUrl(element.url, context),
                    ),
              actions: <Widget>[
                PlatformDialogAction(
                    cupertino: (context, platform) =>
                        CupertinoDialogActionData(isDefaultAction: true),
                    child: PlatformText(S.of(context).cancel),
                    onPressed: () => Navigator.pop(context, false)),
                PlatformDialogAction(
                    cupertino: (context, platform) => CupertinoDialogActionData(
                        isDestructiveAction: isConfirmDestructive),
                    child: PlatformText(confirmText ?? S.of(context).i_see),
                    onPressed: () => Navigator.pop(context, true)),
              ],
            ));
  }

  static showModalNotice(BuildContext context,
      {String title = "", String message = ""}) async {
    if (!title.endsWith('\n') && !message.startsWith('\n')) title += '\n';
    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
          child: ListTile(
              title: Text(title),
              subtitle: Linkify(
                text: message,
              ))),
    );
    Widget body;
    if (PlatformX.isCupertino(context)) {
      body = SafeArea(
        child: Card(
          child: content,
        ),
      );
    } else {
      body = SafeArea(
        child: content,
      );
    }
    showPlatformModalSheet(
      context: context,
      builder: (BuildContext context) => body,
    );
  }

  static showScreenshotWarning(BuildContext context) =>
      Noticing.showNotice(context, S.of(context).screenshot_warning,
          title: S.of(context).screenshot_warning_title, useSnackBar: false);
}
