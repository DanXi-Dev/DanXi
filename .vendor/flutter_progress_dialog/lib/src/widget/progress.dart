part of '../progress_dialog.dart';

class ProgressDialog extends StatefulWidget {
  final Widget child;
  final Widget? loading;
  final String? loadingText;
  final TextStyle? textStyle;
  final Color backgroundColor;
  final double radius;
  final TextDirection? textDirection;
  final ProgressOrientation? orientation;

  const ProgressDialog({
    Key? key,
    required this.child,
    this.loading,
    this.loadingText,
    this.textStyle,
    this.radius = 10.0,
    Color? backgroundColor,
    this.textDirection,
    this.orientation,
  })  : this.backgroundColor = backgroundColor ?? const Color(0xDD000000),
        super(key: key);

  @override
  _ProgressDialogState createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  @override
  void dispose() {
    _contextMap.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var overlay = Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (ctx) {
            _contextMap[this] = ctx;
            return widget.child;
          },
        ),
      ],
    );

    TextDirection direction = widget.textDirection ?? TextDirection.ltr;

    Widget w = Directionality(
      child: Stack(children: <Widget>[
        overlay,
        Positioned(
          left: 0.0,
          right: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.0)),
          ),
        )
      ]),
      textDirection: direction,
    );

    return _ProgressTheme(
      child: w,
      backgroundColor: widget.backgroundColor,
      radius: widget.radius,
      loading: widget.loading,
      loadingText: widget.loadingText,
      textDirection: direction,
      orientation: widget.orientation,
    );
  }
}

class ProgressVisibleObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    dismissProgressDialog();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    dismissProgressDialog();
  }
}
