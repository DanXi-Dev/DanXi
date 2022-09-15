// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'configurations.dart';
import 'taggable.dart';

///
class FlutterTagging<T extends Taggable> extends StatefulWidget {
  /// Override the chip builder of this widget
  /// You may customize the widget as you like, but the [onDelete] callback must be called when the tag is about to be deleted.
  final Widget Function(T, VoidCallback)? customChipBuilder;

  /// Called every time the value changes.
  ///  i.e. when items are selected or removed.
  final VoidCallback? onChanged;

  /// The configuration of the [TextField] that the [FlutterTagging] widget displays.
  final TextFieldConfiguration textFieldConfiguration;

  /// Called with the search pattern to get the search suggestions.
  ///
  /// This callback must not be null. It is be called by the FlutterTagging widget
  /// and provided with the search pattern. It should return a [List]
  /// of suggestions either synchronously, or asynchronously (as the result of a
  /// [Future].
  /// Typically, the list of suggestions should not contain more than 4 or 5
  /// entries. These entries will then be provided to [itemBuilder] to display
  /// the suggestions.
  ///
  /// Example:
  /// ```dart
  /// findSuggestions: (pattern) async {
  ///   return await _getSuggestions(pattern);
  /// }
  /// ```
  final FutureOr<List<T>> Function(String) findSuggestions;

  /// The configuration of [Chip]s that are displayed for selected tags.
  final ChipConfiguration Function(T) configureChip;

  /// The configuration of suggestions displayed when [findSuggestions] finishes.
  final SuggestionConfiguration Function(T) configureSuggestion;

  /// The configuration of selected tags like their spacing, direction, etc.
  final WrapConfiguration wrapConfiguration;

  /// Defines an object for search pattern.
  ///
  /// If null, tag addition feature is disabled.
  final T Function(String)? additionCallback;

  /// Called when add to tag button is pressed.
  ///
  /// Api Calls to add the tag can be called here.
  final FutureOr<T> Function(T)? onAdded;

  /// Called when waiting for [findSuggestions] to return.
  final Widget Function(BuildContext)? loadingBuilder;

  /// Called when [findSuggestions] returns an empty list.
  final Widget Function(BuildContext)? emptyBuilder;

  /// Called when [findSuggestions] throws an exception.
  final Widget Function(BuildContext, Object?)? errorBuilder;

  /// Called to display animations when [findSuggestions] returns suggestions.
  ///
  /// It is provided with the suggestions box instance and the animation
  /// controller, and expected to return some animation that uses the controller
  /// to display the suggestion box.
  final Widget Function(BuildContext, Widget, AnimationController?)?
      transitionBuilder;

  /// The configuration of suggestion box.
  final SuggestionsBoxConfiguration suggestionsBoxConfiguration;

  /// The duration that [transitionBuilder] animation takes.
  ///
  /// This argument is best used with [transitionBuilder] and [animationStart]
  /// to fully control the animation.
  ///
  /// Defaults to 500 milliseconds.
  final Duration animationDuration;

  /// The value at which the [transitionBuilder] animation starts.
  ///
  /// This argument is best used with [transitionBuilder] and [animationDuration]
  /// to fully control the animation.
  ///
  /// Defaults to 0.25.
  final double animationStart;

  /// If set to true, no loading box will be shown while suggestions are
  /// being fetched. [loadingBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnLoading;

  /// If set to true, nothing will be shown if there are no results.
  /// [emptyBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnEmpty;

  /// If set to true, nothing will be shown if there is an error.
  /// [errorBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnError;

  /// The duration to wait after the user stops typing before calling
  /// [findSuggestions].
  ///
  /// This is useful, because, if not set, a request for suggestions will be
  /// sent for every character that the user types.
  ///
  /// This duration is set by default to 300 milliseconds.
  final Duration debounceDuration;

  /// If set to true, suggestions will be fetched immediately when the field is
  /// added to the view.
  ///
  /// But the suggestions box will only be shown when the field receives focus.
  /// To make the field receive focus immediately, you can set the `autofocus`
  /// property in the [textFieldConfiguration] to true.
  ///
  /// Defaults to false.
  final bool enableImmediateSuggestion;

  ///
  final List<T> initialItems;

  /// Creates a [FlutterTagging] widget.
  const FlutterTagging(
      {required this.initialItems,
      required this.findSuggestions,
      required this.configureChip,
      required this.configureSuggestion,
      this.onChanged,
      this.additionCallback,
      this.enableImmediateSuggestion = false,
      this.errorBuilder,
      this.loadingBuilder,
      this.emptyBuilder,
      this.wrapConfiguration = const WrapConfiguration(),
      this.textFieldConfiguration = const TextFieldConfiguration(),
      this.suggestionsBoxConfiguration = const SuggestionsBoxConfiguration(),
      this.transitionBuilder,
      this.debounceDuration = const Duration(milliseconds: 300),
      this.hideOnEmpty = false,
      this.hideOnError = false,
      this.hideOnLoading = false,
      this.animationDuration = const Duration(milliseconds: 500),
      this.animationStart = 0.25,
      this.onAdded,
      Key? key,
      this.customChipBuilder})
      : super(key: key);

  @override
  _FlutterTaggingState<T> createState() => _FlutterTaggingState<T>();
}

class _FlutterTaggingState<T extends Taggable>
    extends State<FlutterTagging<T>> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  T? _additionItem;

  @override
  void initState() {
    super.initState();
    _textController =
        widget.textFieldConfiguration.controller ?? TextEditingController();
    _focusNode = widget.textFieldConfiguration.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TypeAheadField<T>(
          getImmediateSuggestions: widget.enableImmediateSuggestion,
          debounceDuration: widget.debounceDuration,
          hideOnEmpty: widget.hideOnEmpty,
          hideOnError: widget.hideOnError,
          hideOnLoading: widget.hideOnLoading,
          animationStart: widget.animationStart,
          animationDuration: widget.animationDuration,
          autoFlipDirection:
              widget.suggestionsBoxConfiguration.autoFlipDirection,
          direction: widget.suggestionsBoxConfiguration.direction,
          hideSuggestionsOnKeyboardHide:
              widget.suggestionsBoxConfiguration.hideSuggestionsOnKeyboardHide,
          keepSuggestionsOnLoading:
              widget.suggestionsBoxConfiguration.keepSuggestionsOnLoading,
          keepSuggestionsOnSuggestionSelected: widget
              .suggestionsBoxConfiguration.keepSuggestionsOnSuggestionSelected,
          suggestionsBoxController:
              widget.suggestionsBoxConfiguration.suggestionsBoxController,
          suggestionsBoxDecoration:
              widget.suggestionsBoxConfiguration.suggestionsBoxDecoration,
          suggestionsBoxVerticalOffset:
              widget.suggestionsBoxConfiguration.suggestionsBoxVerticalOffset,
          errorBuilder: widget.errorBuilder,
          transitionBuilder: widget.transitionBuilder,
          loadingBuilder: (context) =>
              widget.loadingBuilder?.call(context) ??
              const SizedBox(
                height: 3.0,
                child: LinearProgressIndicator(),
              ),
          noItemsFoundBuilder: widget.emptyBuilder,
          textFieldConfiguration: widget.textFieldConfiguration.copyWith(
            focusNode: _focusNode,
            controller: _textController,
            enabled: widget.textFieldConfiguration.enabled,
          ),
          suggestionsCallback: (query) async {
            final suggestions = await widget.findSuggestions(query);
            suggestions.removeWhere(widget.initialItems.contains);
            if (widget.additionCallback != null && query.isNotEmpty) {
              final additionItem = widget.additionCallback!(query);
              if (!suggestions.contains(additionItem) &&
                  !widget.initialItems.contains(additionItem)) {
                _additionItem = additionItem;
                suggestions.insert(0, additionItem);
              } else {
                _additionItem = null;
              }
            }
            return suggestions;
          },
          itemBuilder: (context, item) {
            final conf = widget.configureSuggestion(item);
            return ListTile(
              key: ObjectKey(item),
              title: conf.title,
              subtitle: conf.subtitle,
              leading: conf.leading,
              trailing: InkWell(
                splashColor: conf.splashColor ?? Theme.of(context).splashColor,
                borderRadius: conf.splashRadius,
                onTap: () async {
                  if (widget.onAdded != null) {
                    item = await widget.onAdded!(item);
                    widget.initialItems.add(item);
                  } else {
                    widget.initialItems.add(item);
                  }
                  setState(() {});
                  widget.onChanged?.call();
                  _textController.clear();
                  _focusNode.unfocus();
                },
                child: Builder(
                  builder: (context) {
                    if (conf.additionWidget != null && _additionItem == item) {
                      return conf.additionWidget!;
                    } else {
                      return const SizedBox(width: 0);
                    }
                  },
                ),
              ),
            );
          },
          onSuggestionSelected: (suggestion) {
            if (_additionItem != suggestion) {
              widget.initialItems.add(suggestion);
              setState(() {});
              widget.onChanged?.call();
              _textController.clear();
            }
          },
        ),
        Wrap(
          alignment: widget.wrapConfiguration.alignment,
          crossAxisAlignment: widget.wrapConfiguration.crossAxisAlignment,
          runAlignment: widget.wrapConfiguration.runAlignment,
          runSpacing: widget.wrapConfiguration.runSpacing,
          spacing: widget.wrapConfiguration.spacing,
          direction: widget.wrapConfiguration.direction,
          textDirection: widget.wrapConfiguration.textDirection,
          verticalDirection: widget.wrapConfiguration.verticalDirection,
          children: widget.initialItems.map<Widget>((item) {
            if (widget.customChipBuilder != null) {
              return widget.customChipBuilder!.call(item, () {
                widget.initialItems.remove(item);
                setState(() {});
                widget.onChanged?.call();
              });
            }
            final conf = widget.configureChip(item);
            return Padding(
              padding: conf.externalPadding,
              child: Chip(
                label: conf.label,
                shape: conf.shape,
                avatar: conf.avatar,
                backgroundColor: conf.backgroundColor,
                clipBehavior: conf.clipBehavior,
                deleteButtonTooltipMessage: conf.deleteButtonTooltipMessage,
                deleteIcon: conf.deleteIcon,
                deleteIconColor: conf.deleteIconColor,
                elevation: conf.elevation,
                labelPadding: conf.labelPadding,
                labelStyle: conf.labelStyle,
                materialTapTargetSize: conf.materialTapTargetSize,
                padding: conf.padding,
                shadowColor: conf.shadowColor,
                onDeleted: () {
                  widget.initialItems.remove(item);
                  setState(() {});
                  widget.onChanged?.call();
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
