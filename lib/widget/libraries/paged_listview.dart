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
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/state_key.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

const kDuration = Duration(milliseconds: 500);
const kCurve = Curves.easeInOut;

/// A ListView supporting paged loading and viewing.
class PagedListView<T> extends StatefulWidget {
  /// If [allDataReceiver] is null, [PagedListView] determines the content has ended
  /// when [dataReceiver] return an empty list.
  ///
  /// In rare cases, you may expect the situation that there are some pages without items
  /// but you're sure that there are more pages. If so, let [dataReceiver] return a
  /// list with single item [noneItem]. Then the list view will just skip this page and
  /// continue to the next one.
  ///
  /// [noneItem] only come into effect when it is NOT null.
  final T? noneItem;

  /// The [PagedListViewController] used to control its behaviour, e.g. refresh.
  final PagedListViewController<T>? pagedController;

  /// The data that will be used as preloaded data before loading.
  final List<T>? initialData;

  /// The builder to build every list item.
  final IndexedDataWidgetBuilder<T> builder;

  /// The builder to build loading indicator.
  final WidgetBuilder loadingBuilder;

  /// The builder to build end indicator.
  final WidgetBuilder endBuilder;

  /// The builder to build head widget.
  final WidgetBuilder? headBuilder;

  /// The builder to build empty widget.
  final WidgetBuilder? emptyBuilder;

  /// The builder to build full-screen error widget.
  /// It will be called only when a [FatalException] is thrown.
  /// [PagedListView] will simply clear all the data, reset the state,
  /// and show the widget returned by [fatalErrorBuilder].
  final PureValueWidgetBuilder<dynamic>? fatalErrorBuilder;

  /// The start number of page index, usually zero to say that the first page is Page 0.
  final int startPage;

  /// The method to load new data, usually from network.
  ///
  /// Note: You should not need to pack the future with [LazyFuture],
  /// since [PagedListView] will handle the situation.
  final DataReceiver<T>? dataReceiver;

  /// The scrollController of the ListView. If not set, it will be PrimaryScrollController.
  final ScrollController? scrollController;

  /// Should add a scrollbar or not. If true, [scrollController] may not be null.
  final bool withScrollbar;

  /// If not null, will use this data source instead. Using this will turn PagedListView into a regular ListView with customizations.
  final Future<List<T>?>? allDataReceiver;

  final EdgeInsets? padding;

  /// If non-null, items will be slidable.
  /// Sliding an item away will cause this function to be called.
  final void Function(BuildContext, int, T)? onDismissItem;

  final Future<bool?> Function(BuildContext, int, T)? onConfirmDismissItem;

  const PagedListView(
      {super.key,
      this.pagedController,
      this.initialData,
      required this.builder,
      required this.loadingBuilder,
      this.headBuilder,
      this.emptyBuilder,
      this.startPage = 0,
      required this.endBuilder,
      this.dataReceiver,
      this.scrollController,
      this.withScrollbar = false,
      this.allDataReceiver,
      this.noneItem,
      this.fatalErrorBuilder,
      this.padding,
      this.onDismissItem,
      this.onConfirmDismissItem})
      : assert((!withScrollbar) || (withScrollbar && scrollController != null)),
        assert(dataReceiver != null || allDataReceiver != null);

  @override
  PagedListViewState<T> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>>
    with ListProvider<T> {
  /// The key for ListView.
  final GlobalKey _scrollKey = GlobalKey();

  /// Whether the ListView should load any more after reaching the bottom.
  bool _shouldLoad = true;

  int pageIndex = 1;
  bool _isRefreshing = false;
  bool _isEnded = false;
  bool _hasHeadWidget = false;
  bool _hasError = false;

  /// Whether the ListView should clear old data after refreshing.
  bool _dataClearQueued = false;

  final List<T> _data = [];
  GlobalKey<dynamic> headKey = GlobalKey();
  List<StateKey<T>> valueKeys = [];
  Future<List<T>?>? _futureData;

  Function()? _loadCompleteCallback;

  ScrollController? get currentController =>
      widget.scrollController ?? PrimaryScrollController.of(context);

  ListController currentListController = ListController();

  @override
  Widget build(BuildContext context) {
    bool scrollToEnd(ScrollNotification scrollInfo) {
      if (scrollInfo.metrics.extentAfter < 500 &&
          !_isRefreshing &&
          !_isEnded &&
          !_hasError &&
          _shouldLoad) {
        pageIndex++;
        _isRefreshing = true;
        setState(() {
          _futureData = LazyFuture.pack(widget.dataReceiver!(pageIndex));
        });
      }
      return false;
    }

    if (widget.withScrollbar) {
      return NotificationListener<ScrollNotification>(
        onNotification: scrollToEnd,
        child: WithScrollbar(
          controller: widget.scrollController,
          child: _buildListBody(),
        ),
      );
    } else {
      return NotificationListener<ScrollNotification>(
        onNotification: scrollToEnd,
        child: _buildListBody(),
      );
    }
  }

  Widget _buildListBody() {
    return FutureWidget<List<T>?>(
        future: _futureData,
        successBuilder: (_, AsyncSnapshot<List<T>?> snapshot) {
          if (_dataClearQueued) _clearData();
          // Handle load complete callbacks
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (_loadCompleteCallback != null) {
              _loadCompleteCallback!();
              _loadCompleteCallback = null;
            }
          });
          _isRefreshing = false;
          _hasError = false;

          // Process with [noneItem]
          if (snapshot.data!.length == 1 &&
              widget.noneItem != null &&
              snapshot.data!.single == widget.noneItem) {
            return _buildListView();
          }

          // Process with probably duplicated data
          if (snapshot.data!.isEmpty ||
              _data.isEmpty ||
              snapshot.data!.last != _data.last) {
            _data.addAll(snapshot.data!);
            // Update value keys
            valueKeys.addAll(List.generate(snapshot.data!.length,
                (index) => StateKey(snapshot.data![index])));
          }
          if (snapshot.data!.isEmpty) _isEnded = true;
          return _buildListView();
        },
        errorBuilder: (BuildContext context, AsyncSnapshot<List<T>?> snapshot) {
          if (_dataClearQueued) _clearData();
          _hasError = true;
          _isRefreshing = false;
          if (snapshot.error != null &&
              snapshot.error is FatalException &&
              widget.fatalErrorBuilder != null) {
            // We cannot clear the error here
            _clearData(clearError: false);
            pageIndex = widget.startPage;
            return widget.fatalErrorBuilder!.call(context, snapshot.error);
          } else {
            return _buildListView(snapshot: snapshot);
          }
        },
        loadingBuilder: (BuildContext context) {
          _hasError = false;
          return _buildListView();
        });
  }

  Widget _defaultErrorBuilder(AsyncSnapshot<List<T>?>? snapshot) {
    String error;
    if (snapshot == null) {
      error = "Unknown Error";
    } else {
      if (snapshot.error is LoginExpiredError) {
        SettingsProvider.getInstance().deleteAllForumData();
      }
      if (snapshot.error is NotLoginError) {
        error = (snapshot.error as NotLoginError).errorMessage;
      } else {
        error = ErrorPageWidget.generateUserFriendlyDescription(
            S.of(context), snapshot.error);
      }
    }

    return Card(
      child: GestureDetector(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(S.of(context).failed,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(error,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).textTheme.bodySmall!.color))
            ]),
          ),
          onTap: () {
            setState(() {
              _futureData = _setFuture(useInitialData: false);
            });
          }),
    );
  }

  /// The head builder wrapped with [GlobalKey].
  Widget _headBuilderWithKey(BuildContext context) => KeyedSubtree(
        key: headKey,
        child: widget.headBuilder!(context),
      );

  Widget _buildListView({AsyncSnapshot<List<T>?>? snapshot}) {
    // Show an empty indicator if there's no data at all.
    if (!_isRefreshing && _isEnded && _data.isEmpty) {
      // Tell the listView not to try to load anymore.
      _shouldLoad = false;
      return SuperListView(
        //clipBehavior: Clip.none,
        padding: widget.padding,
        key: _scrollKey,
        controller: widget.scrollController,
        listController: currentListController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (_hasHeadWidget) _headBuilderWithKey(context),
          if (!_hasError && widget.emptyBuilder != null)
            widget.emptyBuilder!(context),
        ],
      );
    }

    return SuperListView.builder(
      key: _scrollKey,
      padding: widget.padding,
      controller: widget.scrollController,
      listController: currentListController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _calculateRealWidgetCount(),
      itemBuilder: (context, index) => _getListItemAt(index, snapshot),
    );
  }

  _getListItemAt(int index, AsyncSnapshot<List<T>?>? snapshot) {
    if (_hasHeadWidget) {
      if (index == 0) {
        return _headBuilderWithKey(context);
      }
      index--;
    }
    if (index < _data.length) {
      Widget item = WithStateKey(
        childKey: valueKeys[index],
        child: widget.builder(context, this, index, _data[index]),
      );
      if (widget.onDismissItem != null) {
        item = Dismissible(
          key: valueKeys[index],
          background: ColoredBox(color: Theme.of(context).colorScheme.error),
          confirmDismiss: (direction) =>
              widget.onConfirmDismissItem?.call(context, index, _data[index]) ??
              Future.value(null),
          onDismissed: (direction) {
            widget.onDismissItem!.call(context, index, _data[index]);
            _data.removeAt(index);
            valueKeys.removeAt(index);
          },
          child: item,
        );
      }
      return item;
    } else if (index == _data.length) {
      if (_hasError) {
        return _defaultErrorBuilder(snapshot);
      } else if (_isRefreshing) {
        return widget.loadingBuilder(context);
      } else if (_isEnded) {
        return widget.endBuilder(context);
      }
    }
    return const SizedBox();
  }

  bool get isEnded => _isEnded;

  /// Move things into a separate function to control reload more easily
  ///
  /// [useInitialData] is used to determine whether to use the initial data.
  ///
  /// Warn: if [useInitialData] is true, the initial data will be used for next loading,
  /// let alone the current [pageIndex]!
  Future<List<T>?> _setFuture({useInitialData = true}) {
    if (widget.allDataReceiver == null) {
      _shouldLoad = true;
      _isRefreshing = _isEnded = false;
      if (widget.initialData != null &&
          widget.initialData?.isNotEmpty == true &&
          useInitialData) {
        _isRefreshing = true;
        return Future.value(widget.initialData!);
      } else {
        _isRefreshing = true;
        return LazyFuture.pack(widget.dataReceiver!(pageIndex));
      }
    } else {
      _shouldLoad = false;
      _isRefreshing = true;
      _isEnded = true;
      return widget.allDataReceiver!;
    }
  }

  // [queueDataClear] indicates where to replace the data when load completed (aka queued), or to cleat it immediately
  void initialize({useInitialData = true, queueDataClear = false}) {
    _hasHeadWidget = widget.headBuilder != null;
    if (queueDataClear) {
      _dataClearQueued = true;
    } else {
      _clearData();
    }
    pageIndex = widget.startPage;
    _futureData = _setFuture(useInitialData: useInitialData);
  }

  /// Clear all the data saved.
  /// We don't want to clear the error if this function is called from an error handler,
  /// so we add separate control for whether to clear [_hasError]
  void _clearData({bool clearError = true}) {
    _data.clear();
    valueKeys.clear();
    _dataClearQueued = false;
    if (clearError) {
      _hasError = false;
    }
  }

  @override
  void didUpdateWidget(PagedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (widget.allDataReceiver != oldWidget.allDataReceiver) {
    //   notifyUpdate(true, true);
    // }
  }

  Future<void> notifyUpdate(bool useInitialData, bool queueDataClear) async {
    initialize(useInitialData: useInitialData, queueDataClear: queueDataClear);
    refreshSelf();
    await _futureData;
  }

  /// Replace all data, either loaded with [initialData] or [dataReceiver], with the provided data
  /// Will no longer load content on scroll after called.
  ///
  /// Note: [_futureData] will be discarded after called. Call [notifyUpdate] to rebuild it and go back
  /// to normal mode.
  replaceAllDataWith(List<T> data) {
    setState(() {
      // @w568w (2022-1-25): NEVER USE A REFERENCE-ONLY COPY OF LIST.
      // `_data = data;` makes me struggle with a weird bug
      // that [data] get wrongly cleared by [_clearData] for half a day.
      _data.clear();
      _data.addAll(data);

      _isEnded = true;
      _isRefreshing = false;
      _shouldLoad = false;
      // Replace value keys
      valueKeys.clear();
      valueKeys =
          List.generate(_data.length, (index) => StateKey(_data[index]));
      // Make [_futureData] silent
      _futureData = Future.value(<T>[]);
    });
  }

  replaceDataInRangeWith(Iterable<T> data, int start) {
    setState(() {
      _data.setAll(start, data);
    });
  }

  replaceDatumWith(T data, int index) {
    setState(() {
      _data[index] = data;
    });
  }

  // Scroll to end, assumes that the item is already loaded
  Future<void> scrollToItem(T item,
          [Duration duration = kDuration, Curve curve = kCurve]) =>
      scrollToIndex(valueKeys.indexWhere((element) => element.value == item),
          duration, curve);

  Future<void> scrollToIndex(int index,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    // Flutter issue: https://github.com/flutter/flutter/issues/129768
    // We have to wait for flutter to build the items below
    if (kDuration.inMicroseconds == 0) {
      currentListController.jumpToItem(
          index: index, scrollController: currentController!, alignment: 0);
    } else {
      currentListController.animateToItem(
          index: index,
          scrollController: currentController!,
          alignment: 0,
          duration: (_) => duration,
          curve: (_) => curve);
    }
  }

  int _calculateRealWidgetCount() {
    return _data.length +
        (_isRefreshing ? 1 : 0) +
        (_isEnded ? 1 : 0) +
        (_hasError ? 1 : 0) +
        (_hasHeadWidget ? 1 : 0);
  }

  // Scroll to end, assumes that the list has already ended
  Future<void> scrollToEnd(
      [Duration duration = kDuration, Curve curve = kCurve]) {
    return scrollToIndex(_calculateRealWidgetCount() - 1, duration, curve);
  }

  Future<void> scrollDelta(double pixels,
          [Duration duration = kDuration, Curve curve = kCurve]) =>
      currentController!.animateTo(currentController!.offset + pixels,
          duration: duration, curve: curve);

  // Schedule a callback after load completed
  void scheduleLoadedCallback(Function() callback, {bool rebuild = false}) {
    if (rebuild) {
      setState(() {
        _loadCompleteCallback = callback;
      });
    } else {
      _loadCompleteCallback = callback;
    }
  }

  ScrollController? getScrollController() => currentController;

  @override
  void initState() {
    super.initState();
    widget.pagedController?.setListener(this);
    initialize();
  }

  @override
  T getElementAt(int index) => _data[index];

  @override
  T getElementFirstWhere(bool Function(dynamic) test,
          {dynamic Function()? orElse}) =>
      _data.firstWhere(test, orElse: orElse as T Function()?);

  @override
  int indexOf(T element, [int start = 0]) => _data.indexOf(element, start);

  @override
  int length() {
    return _data.length;
  }
}

class PagedListViewController<T> implements ListProvider<T> {
  late PagedListViewState<T> _state;

  PagedListViewController();

  @protected
  setListener(PagedListViewState<T> state) {
    _state = state;
  }

  bool get isEnded => _state.isEnded;

  Future<void> notifyUpdate({useInitialData = true, queueDataClear = true}) =>
      _state.notifyUpdate(useInitialData, queueDataClear);

  /// Returns whether the scroll was successful or not
  /// May fail due to RenderObject not cached
  /// in which case, try scrolling up/down to find the item
  Future<bool> scrollToItem(T item,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    try {
      await _state.scrollToItem(item, duration, curve);
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);
      return false;
    }
    return true;
  }

  Future<void> scrollToEnd(
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    await _state.scrollToEnd(duration, curve);
  }

  void scheduleLoadedCallback(Function() callback, {bool rebuild = false}) =>
      _state.scheduleLoadedCallback(callback, rebuild: rebuild);

  Future<void> scrollToIndex(int index,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    await _state.scrollToIndex(index, duration, curve);
  }

  Future<void> scrollDelta(double pixels,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    await _state.scrollDelta(pixels, duration, curve);
  }

  ScrollController? getScrollController() => _state.getScrollController();

  /// Replace all data, either loaded with [initialData] or [dataReceiver], with the provided data
  /// Will no longer load content on scroll after this is called.
  void replaceAllDataWith(List<T> data) {
    _state.replaceAllDataWith(data);
  }

  replaceDataInRangeWith(Iterable<T> data, int start) {
    _state.replaceDataInRangeWith(data, start);
  }

  replaceDatumWith(T oldData, T newData) {
    _state.replaceDatumWith(newData, _state._data.indexOf(oldData));
  }

  replaceInitialData(Iterable<T> data) {
    try {
      _state.replaceDataInRangeWith(data, 0);
    } catch (_) {
      _state.widget.initialData?.setRange(0, data.length, data);
    }
  }

  @override
  T getElementAt(int index) => _state.getElementAt(index);

  @override
  T getElementFirstWhere(bool Function(dynamic) test,
          {dynamic Function()? orElse}) =>
      _state.getElementFirstWhere(test, orElse: orElse);

  @override
  int indexOf(T element, [int start = 0]) => _state.indexOf(element, start);

  @override
  int length() => _state.length();
}

// HydrogenC: Naming isn't clear enough, should be something like `ListViewFailureException`
class FatalException implements Exception {}

mixin ListProvider<T> {
  T getElementAt(int index);

  T getElementFirstWhere(bool Function(dynamic) test,
      {dynamic Function()? orElse});

  int indexOf(T element, [int start = 0]);

  int length();
}

/// Build a widget with index & data. You must apply the key to the root widget of item.
typedef IndexedDataWidgetBuilder<T> = Widget Function(
    BuildContext context, ListProvider<T> dataProvider, int index, T data);

/// Build a widget with a value.
typedef PureValueWidgetBuilder<T> = Widget Function(
    BuildContext context, T value);

/// Retrieve data function
typedef DataReceiver<T> = Future<List<T>?> Function(int pageIndex);

/// Notify refreshing callback
typedef RefreshListener = void Function();
