import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'core/manager.dart';

part 'widget/container.dart';

part 'widget/progress.dart';

part 'widget/theme.dart';

part 'core/future.dart';

enum ProgressOrientation { horizontal, vertical }

LinkedHashMap<_ProgressDialogState, BuildContext> _contextMap = LinkedHashMap();

const _opacityDuration = Duration(milliseconds: 250);
const _defaultLoadingText = "请稍候";

/// show progress dialog with [msg],
ProgressFuture showProgressDialog({
  BuildContext? context,
  Widget? loading,
  String? loadingText,
  TextStyle? textStyle,
  Color? backgroundColor,
  double? radius,
  VoidCallback? onDismiss,
  TextDirection? textDirection,
  ProgressOrientation? orientation,
}) {
  context ??= _contextMap.values.first;
  _ProgressTheme? theme = _ProgressTheme.of(context);
  theme ??= _ProgressTheme.origin;
  textStyle ??= Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16.0);
  backgroundColor ??= theme.backgroundColor;
  radius ??= theme.radius;
  textDirection ??= theme.textDirection;
  orientation ??= theme.orientation;
  loading ??= theme.loading;
  loadingText ??= theme.loadingText ?? _defaultLoadingText;

  Widget widget = PlatformWidget(
    material: (context, platform) =>
        loading ??
        Container(
          margin: const EdgeInsets.all(50.0),
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(radius!)),
          child: ClipRect(
            child: orientation == ProgressOrientation.vertical
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 40.0,
                        height: 40.0,
                        margin: EdgeInsets.only(bottom: 8.0),
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(strokeWidth: 3.0),
                      ),
                      Text(loadingText!,
                          style: textStyle!.copyWith(color: Colors.white), textAlign: TextAlign.center),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 36.0,
                        height: 36.0,
                        margin: EdgeInsets.only(right: 8.0),
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(strokeWidth: 3.0),
                      ),
                      Text(loadingText!,
                          style: textStyle!.copyWith(color: Colors.white), textAlign: TextAlign.center),
                    ],
                  ),
          ),
        ),
    cupertino: (context, platform) =>
        loading ??
        CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Container(
            margin: const EdgeInsets.all(20.0),
            child: ClipRect(
              child: orientation == ProgressOrientation.vertical
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 40.0,
                          height: 40.0,
                          padding: EdgeInsets.all(4.0),
                          child: CupertinoActivityIndicator(),
                        ),
                        Text(loadingText!,
                            style: textStyle, textAlign: TextAlign.center),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 36.0,
                          height: 36.0,
                          padding: EdgeInsets.all(4.0),
                          child: CupertinoActivityIndicator(),
                        ),
                        Text(loadingText!,
                            style: textStyle, textAlign: TextAlign.center),
                      ],
                    ),
            ),
          ),
        ),
  );

  return showProgressDialogWidget(
    widget,
    context: context,
    onDismiss: onDismiss,
    textDirection: textDirection,
  );
}

/// show [widget] with progress dialog
ProgressFuture showProgressDialogWidget(
  Widget widget, {
  BuildContext? context,
  VoidCallback? onDismiss,
  TextDirection? textDirection,
  bool? handleTouch,
}) {
  context ??= _contextMap.values.first;
  OverlayEntry entry;
  ProgressFuture future;

  var direction = textDirection ?? _ProgressTheme.of(context)!.textDirection;

  GlobalKey<_ProgressContainerState> key = GlobalKey();

  widget = Align(
    child: widget,
    alignment: Alignment.center,
  );

  entry = OverlayEntry(builder: (ctx) {
    return IgnorePointer(
      ignoring: true,
      child: _ProgressContainer(
        key: key,
        child: Directionality(textDirection: direction, child: widget),
      ),
    );
  });

  // only one progress dialog at a time is showing
  ProgressManager().dismissAll();

  future = ProgressFuture._(entry, onDismiss, key);

  Overlay.of(context).insert(entry);
  ProgressManager().addFuture(future);
  return future;
}

/// use the method to dismiss all progress dialog.
void dismissProgressDialog({bool showAnim = true}) {
  ProgressManager().dismissAll(showAnim: showAnim);
}
