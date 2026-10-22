part of '../progress_dialog.dart';

class _ProgressTheme extends InheritedWidget {
  final Color? backgroundColor;
  final double? radius;
  final TextDirection textDirection;
  final ProgressOrientation? orientation;
  final String? loadingText;
  final Widget? loading;

  const _ProgressTheme({
    this.backgroundColor,
    this.radius,
    this.orientation,
    this.loading,
    this.loadingText,
    TextDirection? textDirection,
    required Widget child,
  })  : textDirection = textDirection ?? TextDirection.ltr,
        super(child: child);

  static const origin = _ProgressTheme(
    child: const SizedBox(),
    backgroundColor: const Color(0xDD000000),
    radius: 10.0,
    orientation: ProgressOrientation.horizontal,
    textDirection: TextDirection.ltr,
    loading: null,
    loadingText: "Loading...",
  );

  static _ProgressTheme? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ProgressTheme>();

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}
