import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/forum/post_filter_js_runtime.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

enum PostFilterMode { regex, js }

class PostFilterState {
  bool _shown = false;
  final TextEditingController controller = TextEditingController();
  PostFilterMode _mode = PostFilterMode.regex;
  final Map<PostFilterMode, String> _patterns = {};
  final PostFilterJsRuntime jsRuntime = PostFilterJsRuntime();

  bool get shown => _shown;

  PostFilterMode get mode => _mode;

  set mode(PostFilterMode newMode) {
    _mode = newMode;
    controller.text = _patterns[newMode] ?? '';
  }

  String get pattern => _patterns[_mode] ?? '';

  void toggle() {
    _shown = !_shown;
  }

  void apply() {
    _patterns[_mode] = controller.text.trim();
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
  final PostFilterMode mode;
  final TextEditingController controller;
  final ValueChanged<PostFilterMode> onModeChanged;
  final VoidCallback onApply;

  const PostFilterBar({
    super.key,
    required this.mode,
    required this.controller,
    required this.onModeChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final patternEnabled =
        mode != PostFilterMode.js || PostFilterJsRuntime.isSupported;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: PlatformX.isMaterial(context) ? 2 : 0,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              ToggleButtons(
                constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
                isSelected: [
                  mode == PostFilterMode.regex,
                  mode == PostFilterMode.js,
                ],
                onPressed: (index) =>
                    onModeChanged(PostFilterMode.values[index]),
                children: const [Text('.*'), Text('JS')],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PlatformTextField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  autofocus: true,
                  controller: controller,
                  onSubmitted: (_) => onApply(),
                  enabled: patternEnabled,
                  hintText: mode == PostFilterMode.regex
                      ? S.of(context).filter
                      : PostFilterJsRuntime.isSupported
                      ? 'content.match(/regex/i)'
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
