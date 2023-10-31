import 'package:flutter/cupertino.dart';

class FakeCupertinoSearchTextField extends StatelessWidget {
  FakeCupertinoSearchTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.placeholder,
    this.placeholderStyle,
    this.decoration,
    this.backgroundColor,
    this.borderRadius,
    this.padding = const EdgeInsetsDirectional.fromSTEB(3.8, 8, 5, 8),
    this.itemColor = CupertinoColors.secondaryLabel,
    this.itemSize = 20.0,
    this.prefixInsets = const EdgeInsetsDirectional.fromSTEB(6, 0, 0, 4),
    this.prefixIcon = const Icon(CupertinoIcons.search),
    this.suffixInsets = const EdgeInsetsDirectional.fromSTEB(0, 0, 5, 2),
    this.suffixIcon = const Icon(CupertinoIcons.xmark_circle_fill),
    this.suffixMode = OverlayVisibilityMode.editing,
    this.onSuffixTap,
    this.restorationId,
    this.focusNode,
    this.autofocus = false,
    this.onTap,
    this.autocorrect = true,
    this.enabled,
  });

  /// Controls the text being edited.
  ///
  /// Similar to [CupertinoTextField], to provide a prefilled text entry, pass
  /// in a [TextEditingController] with an initial value to the [controller]
  /// parameter. Defaults to creating its own [TextEditingController].
  final TextEditingController? controller;

  /// Invoked upon user input.
  final ValueChanged<String>? onChanged;

  /// Invoked upon keyboard submission.
  final ValueChanged<String>? onSubmitted;

  /// Allows changing the style of the text.
  ///
  /// Defaults to the gray [CupertinoColors.secondaryLabel] iOS color.
  final TextStyle? style;

  /// A hint placeholder text that appears when the text entry is empty.
  ///
  /// Defaults to 'Search' localized in each supported language.
  String? placeholder;

  /// Sets the style of the placeholder of the text field.
  ///
  /// Defaults to the gray [CupertinoColors.secondaryLabel] iOS color.
  TextStyle? placeholderStyle;

  /// Sets the decoration for the text field.
  ///
  /// This property is automatically set using the [backgroundColor] and
  /// [borderRadius] properties, which both have default values. Therefore,
  /// [decoration] has a default value upon building the  It is designed
  /// to mimic the look of a `UISearchTextField`.
  BoxDecoration? decoration;

  /// Set the [decoration] property's background color.
  ///
  /// Can't be set along with the [decoration]. Defaults to the translucent
  /// [CupertinoColors.tertiarySystemFill] iOS color.
  final Color? backgroundColor;

  /// Sets the [decoration] property's border radius.
  ///
  /// Can't be set along with the [decoration]. Defaults to 9 px circular
  /// corner radius.
  // TODO(DanielEdrisian): Must make border radius continuous, see
  // https://github.com/flutter/flutter/issues/13914.
  final BorderRadius? borderRadius;

  /// Sets the padding insets for the text and placeholder.
  ///
  /// Cannot be null. Defaults to padding that replicates the
  /// `UISearchTextField` look. The inset values were determined using the
  /// comparison tool in https://github.com/flutter/platform_tests/.
  final EdgeInsetsGeometry padding;

  /// Sets the color for the suffix and prefix icons.
  ///
  /// Cannot be null. Defaults to [CupertinoColors.secondaryLabel].
  final Color itemColor;

  /// Sets the base icon size for the suffix and prefix icons.
  ///
  /// Cannot be null. The size of the icon is scaled using the accessibility
  /// font scale settings. Defaults to `20.0`.
  final double itemSize;

  /// Sets the padding insets for the suffix.
  ///
  /// Cannot be null. Defaults to padding that replicates the
  /// `UISearchTextField` suffix look. The inset values were determined using
  /// the comparison tool in https://github.com/flutter/platform_tests/.
  final EdgeInsetsGeometry prefixInsets;

  /// Sets a prefix
  ///
  /// Cannot be null. Defaults to an [Icon] widget with the [CupertinoIcons.search] icon.
  final Widget prefixIcon;

  /// Sets the padding insets for the prefix.
  ///
  /// Cannot be null. Defaults to padding that replicates the
  /// `UISearchTextField` prefix look. The inset values were determined using
  /// the comparison tool in https://github.com/flutter/platform_tests/.
  final EdgeInsetsGeometry suffixInsets;

  /// Sets the suffix widget's icon.
  ///
  /// Cannot be null. Defaults to the X-Mark [CupertinoIcons.xmark_circle_fill].
  /// "To change the functionality of the suffix icon, provide a custom
  /// onSuffixTap callback and specify an intuitive suffixIcon.
  final Icon suffixIcon;

  /// Dictates when the X-Mark (suffix) should be visible.
  ///
  /// Cannot be null. Defaults to only on when editing.
  final OverlayVisibilityMode suffixMode;

  /// Sets the X-Mark (suffix) action.
  ///
  /// Defaults to clearing the text. The suffix action is customizable
  /// so that users can override it with other functionality, that isn't
  /// necessarily clearing text.
  final VoidCallback? onSuffixTap;

  /// {@macro flutter.material.textfield.restorationId}
  final String? restorationId;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.material.textfield.onTap}
  final VoidCallback? onTap;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// Disables the text field when false.
  ///
  /// Text fields in disabled states have a light grey background and don't
  /// respond to touch events including the [prefixIcon] and [suffixIcon] button.
  final bool? enabled;

  /// Default value for the border radius. Radius value was determined using the
  /// comparison tool in https://github.com/flutter/platform_tests/.
  final BorderRadius _kDefaultBorderRadius =
      const BorderRadius.all(Radius.circular(9.0));

  @override
  Widget build(BuildContext context) {
    placeholder ??=
        CupertinoLocalizations.of(context).searchTextFieldPlaceholderLabel;

    placeholderStyle ??= const TextStyle(color: CupertinoColors.systemGrey);

    // The icon size will be scaled by a factor of the accessibility text scale,
    // to follow the behavior of `UISearchTextField`.
    final double scaledIconSize =
        MediaQuery.textScaleFactorOf(context) * itemSize;

    // If decoration was not provided, create a decoration with the provided
    // background color and border radius.
    decoration ??= BoxDecoration(
      color: backgroundColor ?? CupertinoColors.tertiarySystemFill,
      borderRadius: borderRadius ?? _kDefaultBorderRadius,
    );

    final IconThemeData iconThemeData = IconThemeData(
      color: CupertinoDynamicColor.resolve(itemColor, context),
      size: scaledIconSize,
    );

    final Widget prefix = Padding(
      padding: prefixInsets,
      child: IconTheme(
        data: iconThemeData,
        child: prefixIcon,
      ),
    );

    final Widget suffix = Padding(
      padding: suffixInsets,
      child: CupertinoButton(
        onPressed: onSuffixTap,
        minSize: 0,
        padding: EdgeInsets.zero,
        child: IconTheme(
          data: iconThemeData,
          child: suffixIcon,
        ),
      ),
    );

    return CupertinoTextField(
      decoration: decoration,
      style: style,
      prefix: prefix,
      suffix: suffix,
      onTap: onTap,
      enabled: enabled,
      suffixMode: suffixMode,
      placeholder: placeholder,
      placeholderStyle: placeholderStyle,
      padding: padding,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      autocorrect: autocorrect,
      textInputAction: TextInputAction.search,
      readOnly: true,
    );
  }
}
