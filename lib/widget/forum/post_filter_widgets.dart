import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/util/forum/post_filter_js_runtime.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PostFilterState {
  bool _shown = false;
  final TextEditingController controller = TextEditingController();
  String _pattern = '';
  final PostFilterJsRuntime jsRuntime = PostFilterJsRuntime();

  bool get shown => _shown;

  String get pattern => _pattern;

  bool holeMatches(OTHole hole) {
    return _matches(() => jsRuntime.evaluateHole(pattern, hole));
  }

  bool floorMatches(OTFloor floor, {OTHole? hole}) {
    return _matches(() => jsRuntime.evaluateFloor(pattern, floor, hole: hole));
  }

  bool _matches(bool Function() evaluateJs) {
    return shown && pattern.isNotEmpty && evaluateJs();
  }

  void toggle() {
    _shown = !_shown;
  }

  void apply() {
    _pattern = controller.text.trim();
  }

  void dispose() {
    controller.dispose();
    jsRuntime.dispose();
  }
}

IconData getPostFilterIcon(BuildContext context, bool showPostFilter) =>
    PlatformX.isMaterial(context)
    ? (showPostFilter ? Icons.filter_alt_off : Icons.filter_alt)
    : (showPostFilter
          ? CupertinoIcons.line_horizontal_3
          : CupertinoIcons.slider_horizontal_3);

class PostFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;
  final bool topSafeArea;

  const PostFilterBar({
    super.key,
    required this.controller,
    required this.onApply,
    this.topSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final patternEnabled = PostFilterJsRuntime.isSupported;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: PlatformX.isMaterial(context) ? 2 : 0,
      child: SafeArea(
        top: topSafeArea,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: PlatformTextField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  controller: controller,
                  onSubmitted: (_) => onApply(),
                  enabled: patternEnabled,
                  hintText: PostFilterJsRuntime.isSupported
                      // TODO: Use i18n text.
                      ? 'JS expression'
                      // TODO: Use i18n text.
                      : 'PostFilterJsRuntime.isSupported: false',
                ),
              ),
              if (patternEnabled)
                PlatformIconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    PlatformX.isMaterial(context)
                        ? Icons.check
                        : CupertinoIcons.check_mark,
                  ),
                  onPressed: onApply,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WithPostFilterBar extends StatelessWidget {
  final PostFilterState filter;
  final Widget child;
  final VoidCallback onApply;
  final bool topSafeArea;

  const WithPostFilterBar({
    super.key,
    required this.filter,
    required this.child,
    required this.onApply,
    required this.topSafeArea,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (filter.shown)
          PostFilterBar(
            controller: filter.controller,
            onApply: onApply,
            topSafeArea: topSafeArea,
          ),
        Expanded(
          child: filter.shown && topSafeArea
              ? MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}
