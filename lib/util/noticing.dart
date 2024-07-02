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
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Simple helper class to show a notice,
/// like [SnackBar] on Material or a [CupertinoAlertDialog] on Cupertino.
class Noticing {
  static showMaterialNotice(BuildContext context, String message,
      {String? confirmText,
      String? title,
      bool useSnackBar = true,
      bool? centerContent}) {
    if (PlatformX.isCupertino(context)) return;
    showNotice(context, message,
        centerContent: centerContent,
        title: title,
        confirmText: confirmText,
        useSnackBar: useSnackBar);
  }

  static showNotice(BuildContext context, String message,
      {String? confirmText,
      String? title,
      bool useSnackBar = true,
      bool? centerContent,
      List<CustomDialogActionItem> customActions = const []}) async {
    centerContent ??= !PlatformX.isMaterial(context);
    if (PlatformX.isMaterial(context) && useSnackBar) {
      // Override Linkify's default text style.
      final bool isThemeDark = Theme.of(context).brightness == Brightness.dark;
      final Brightness invertBrightness =
          isThemeDark ? Brightness.light : Brightness.dark;
      final TextStyle? contentTextStyle =
          Theme.of(context).snackBarTheme.contentTextStyle ??
              ThemeData(brightness: invertBrightness).textTheme.titleMedium;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: LinkifyX(
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
                        child: LinkifyX(
                        textAlign:
                            centerContent ? TextAlign.center : TextAlign.start,
                        text: message,
                        onOpen: (element) =>
                            BrowserUtil.openUrl(element.url, context),
                      ))
                    : LinkifyX(
                        textAlign:
                            centerContent ? TextAlign.center : TextAlign.start,
                        text: message,
                        onOpen: (element) =>
                            BrowserUtil.openUrl(element.url, context),
                      ),
                actions: customActions
                        .map((e) => PlatformDialogAction(
                            onPressed: e.onPressed,
                            child: PlatformText(e.text)))
                        .toList() +
                    [
                      PlatformDialogAction(
                          child:
                              PlatformText(confirmText ?? S.of(context).i_see),
                          onPressed: () => Navigator.pop(context)),
                    ],
              ));
    }
  }

  static showErrorDialog(BuildContext context, dynamic error,
      {StackTrace? trace,
      String? title,
      bool useSnackBar = false,
      bool? centerContent}) async {
    title ??= S.of(context).fatal_error;
    centerContent ??= !PlatformX.isMaterial(context);
    final message = ErrorPageWidget.generateUserFriendlyDescription(
        S.of(context), error,
        stackTrace: trace);
    return await showPlatformDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlertDialog(
              title: title == null ? null : Text(title),
              content: centerContent!
                  ? Center(
                      child: LinkifyX(
                      textAlign:
                          centerContent ? TextAlign.center : TextAlign.start,
                      text: message,
                      onOpen: (element) =>
                          BrowserUtil.openUrl(element.url, context),
                    ))
                  : LinkifyX(
                      textAlign:
                          centerContent ? TextAlign.center : TextAlign.start,
                      text: message,
                      onOpen: (element) =>
                          BrowserUtil.openUrl(element.url, context),
                    ),
              actions: <Widget>[
                PlatformDialogAction(
                    child: PlatformText(S.of(context).error_detail),
                    onPressed: () {
                      Noticing.showModalNotice(context,
                          message: ErrorPageWidget.generateErrorDetails(
                              error, trace),
                          title: S.of(context).error_detail,
                          selectable: true);
                    }),
                PlatformDialogAction(
                    child: PlatformText(S.of(context).i_see),
                    onPressed: () => Navigator.pop(context)),
              ],
            ));
  }

  static Future<String?> showInputDialog(BuildContext context, String title,
      {String? confirmText,
      bool isConfirmDestructive = false,
      int? maxLines,
      String? initialText,
      String? hintText}) async {
    TextEditingController controller = TextEditingController(text: initialText);
    String? value = await showPlatformDialog<String?>(
      context: context,
      builder: (BuildContext context) => PlatformAlertDialog(
        title: Text(title),
        content: PlatformTextField(
          controller: controller,
          maxLines: maxLines,
          hintText: hintText,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: <Widget>[
          PlatformDialogAction(
              child: PlatformText(S.of(context).cancel),
              onPressed: () {
                Navigator.pop(context, null);
              }),
          PlatformDialogAction(
              cupertino: (context, platform) => CupertinoDialogActionData(
                  isDestructiveAction: isConfirmDestructive,
                  isDefaultAction: true),
              material: (context, platform) => MaterialDialogActionData(
                  style: isConfirmDestructive
                      ? ButtonStyle(
                          foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.red))
                      : null),
              child: PlatformText(confirmText ?? S.of(context).i_see),
              onPressed: () => Navigator.pop(context, controller.text)),
        ],
      ),
    );
    // We won't dispose the controller, as it is only used in an anonymous function
    //  rather than a [StatefulWidget]. So, it is unnecessary to release the resource.
    //  (and at the time, [TextEditingController.dispose] only does debug and assertion work.)
    // controller.dispose();
    return value;
  }

  static Future<bool?> showConfirmationDialog(
      BuildContext context, String message,
      {String? confirmText,
      String? cancelText,
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
                      child: LinkifyX(
                      textAlign:
                          centerContent ? TextAlign.center : TextAlign.start,
                      text: message,
                      onOpen: (element) =>
                          BrowserUtil.openUrl(element.url, context),
                    ))
                  : LinkifyX(
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
                    child: PlatformText(cancelText ?? S.of(context).cancel),
                    onPressed: () => Navigator.pop(context, false)),
                PlatformDialogAction(
                    cupertino: (context, platform) => CupertinoDialogActionData(
                        isDestructiveAction: isConfirmDestructive),
                    material: (context, platform) => MaterialDialogActionData(
                        style: isConfirmDestructive
                            ? ButtonStyle(
                                foregroundColor:
                                    WidgetStateProperty.all<Color>(Colors.red))
                            : null),
                    child: PlatformText(confirmText ?? S.of(context).i_see),
                    onPressed: () => Navigator.pop(context, true)),
              ],
            ));
  }

  static showModalNotice(BuildContext context,
      {String title = "", String message = "", bool selectable = false}) async {
    if (!title.endsWith('\n') && !message.startsWith('\n')) title += '\n';
    Widget content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
          child: ListTile(
              title: Text(title),
              subtitle: selectable
                  ? SelectableLinkifyX(text: message)
                  : LinkifyX(text: message))),
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
}

class CustomDialogActionItem {
  final String text;
  final VoidCallback onPressed;

  CustomDialogActionItem(this.text, this.onPressed);
}
