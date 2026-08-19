part of '../progress_dialog.dart';

class _ProgressContainer extends StatefulWidget {
  final Widget? child;

  const _ProgressContainer({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  _ProgressContainerState createState() => _ProgressContainerState();
}

class _ProgressContainerState extends State<_ProgressContainer>
    with WidgetsBindingObserver {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 30), () {
      if (!mounted) {
        return;
      }
      setState(() {
        opacity = 1.0;
      });
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget w = AnimatedOpacity(
      duration: _opacityDuration,
      child: widget.child,
      opacity: opacity,
    );

    var mediaQueryData = MediaQueryData.fromView(View.of(context));
    Widget container = w;

    var edgeInsets = EdgeInsets.only(bottom: mediaQueryData.viewInsets.bottom);
    container = AnimatedPadding(
      duration: _opacityDuration,
      padding: edgeInsets,
      child: container,
    );
    return container;
  }

  void showDismissAnim() {
    setState(() {
      opacity = 0.0;
    });
  }
}
