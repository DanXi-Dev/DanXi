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
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/state_key.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/material.dart';

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

  /// Use the PagedListViewController to control its behaviour, e.g. refreshing
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
  final DataReceiver<T> dataReceiver;

  /// The scrollController of the ListView. If not set, it will be PrimaryScrollController.
  final ScrollController? scrollController;

  /// Should add a scrollbar or not. If true, [scrollController] may not be null.
  final bool withScrollbar;

  /// If not null, will use this data source instead. Using this will turn PagedListView into a regular ListView with customizations.
  final Future<List<T>>? allDataReceiver;

  /// Whether this should scroll to end upon loading complete
  /// Will be executed only once
  final bool? shouldScrollToEnd;

  const PagedListView(
      {Key? key,
      this.pagedController,
      this.initialData,
      required this.builder,
      required this.loadingBuilder,
      this.headBuilder,
      this.emptyBuilder,
      this.startPage = 0,
      required this.endBuilder,
      required this.dataReceiver,
      this.scrollController,
      this.withScrollbar = false,
      this.allDataReceiver,
      this.shouldScrollToEnd,
      this.noneItem,
      this.fatalErrorBuilder})
      : assert((!withScrollbar) || (withScrollbar && scrollController != null)),
        super(key: key);

  @override
  _PagedListViewState<T> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>>
    with ListProvider<T> {
  /// The key for ListView.
  final GlobalKey _scrollKey = GlobalKey();

  /// Whether the ListView should load anymore after reaching the bottom.
  bool _shouldLoad = true;
  int pageIndex = 1;
  bool _isRefreshing = false;
  bool _isEnded = false;
  bool _hasHeadWidget = false;
  bool _scrollToEndQueued = false;
  bool _hasError = false;

  /// Whether the ListView should clear old data after refreshing.
  bool _dataClearQueued = false;

  List<T> _data = [];
  List<StateKey<T>> valueKeys = [];
  Future<List<T>?>? _futureData;

  ScrollController? get currentController =>
      widget.scrollController ?? PrimaryScrollController.of(context);

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
          _futureData = LazyFuture.pack(widget.dataReceiver(pageIndex));
        });
      }
      return false;
    }

    if (widget.withScrollbar) {
      return NotificationListener<ScrollNotification>(
        child: WithScrollbar(
          child: _buildListBody(),
          controller: widget.scrollController,
        ),
        onNotification: scrollToEnd,
      );
    } else {
      return NotificationListener<ScrollNotification>(
        child: _buildListBody(),
        onNotification: scrollToEnd,
      );
    }
  }

  _buildListBody() {
    return FutureWidget<List<T>?>(
        future: _futureData,
        successBuilder: (_, AsyncSnapshot<List<T>?> snapshot) {
          if (_dataClearQueued) _clearData();
          // Handle Scroll To End Requests
          WidgetsBinding.instance!.addPostFrameCallback((_) async {
            if (_scrollToEndQueued) {
              while (currentController!.position.pixels <
                  currentController!.position.maxScrollExtent) {
                currentController!
                    .jumpTo(currentController!.position.maxScrollExtent);

                // TODO: Evil hack to wait for new contents to load
                await Future.delayed(const Duration(milliseconds: 100));
              }
              if (_isEnded) _scrollToEndQueued = false;
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
            _clearData();
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
        SettingsProvider.getInstance().deleteAllFduholeData();
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
                  style: Theme.of(context).textTheme.subtitle1),
              const SizedBox(height: 4),
              Text(error,
                  style: Theme.of(context).textTheme.bodyText2!.copyWith(
                      color: Theme.of(context).textTheme.caption!.color))
            ]),
          ),
          onTap: () {
            setState(() {
              _futureData = _setFuture();
            });
          }),
    );
  }

  Widget _buildListView({AsyncSnapshot<List<T>?>? snapshot}) {
    // Show an empty indicator if there's no data at all.
    if (!_isRefreshing && _isEnded && _data.isEmpty) {
      // Tell the listView not to try to load anymore.
      _shouldLoad = false;
      return ListView(
        //clipBehavior: Clip.none,
        key: _scrollKey,
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (_hasHeadWidget) widget.headBuilder!(context),
          if (!_hasError && widget.emptyBuilder != null)
            widget.emptyBuilder!(context),
        ],
      );
    }

    final realWidgetCount = _data.length +
        (_isRefreshing ? 1 : 0) +
        (_isEnded ? 1 : 0) +
        (_hasError ? 1 : 0) +
        (_hasHeadWidget ? 1 : 0);
    return ListView.builder(
      key: _scrollKey,
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: realWidgetCount,
      itemBuilder: (context, index) => _getListItemAt(index, snapshot),
    );
  }

  _getListItemAt(int index, AsyncSnapshot<List<T>?>? snapshot) {
    if (_hasHeadWidget) {
      if (index == 0) {
        return widget.headBuilder!(context);
      }
      index--;
    }
    if (index < _data.length) {
      return WithStateKey(
        childKey: valueKeys[index],
        child: widget.builder(context, this, index, _data[index]),
      );
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

  // Move things into a separate function to control reload more easily
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
        return LazyFuture.pack(widget.dataReceiver(pageIndex));
      }
    } else {
      _shouldLoad = false;
      _isRefreshing = false;
      _isEnded = true;
      return LazyFuture.pack(widget.allDataReceiver!.then((value) => value));
    }
  }

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
  void _clearData() {
    _data.clear();
    valueKeys.clear();
    _hasError = false;
    _dataClearQueued = false;
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
  replaceDataWith(List<T> data) {
    setState(() {
      _data = data;
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

  queueScrollToEnd() {
    _scrollToEndQueued = true;
  }

  scrollToItem(T item, [Duration duration = kDuration, Curve curve = kCurve]) =>
      scrollToIndex(valueKeys.indexWhere((element) => element.value == item),
          duration, curve);

  scrollToIndex(int index,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    final double itemTop =
        valueKeys.getRange(0, index).fold<double>(0.0, (value, element) {
      final RenderBox box =
          element.currentContext.findRenderObject() as RenderBox;
      return value + box.size.height;
    });
    if (kDuration.inMicroseconds == 0) {
      currentController!.jumpTo(itemTop);
    } else {
      await currentController!
          .animateTo(itemTop, duration: duration, curve: curve);
    }
  }

  Future<void> scrollDelta(double pixels,
          [Duration duration = kDuration, Curve curve = kCurve]) =>
      currentController!.animateTo(currentController!.offset + pixels,
          duration: duration, curve: curve);

  ScrollController? getScrollController() => currentController;

  @override
  void initState() {
    super.initState();
    widget.pagedController?.setListener(this);
    initialize();

    // This ensures that scroll to end is not called upon rebuild.
    if (widget.shouldScrollToEnd == true) {
      _scrollToEndQueued = true;
    }
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
  late _PagedListViewState<T> _state;

  PagedListViewController();

  @protected
  setListener(_PagedListViewState<T> state) {
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
    } catch (ignored) {
      return false;
    }
    return true;
  }

  Future<void> scrollToIndex(int index,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    await _state.scrollToIndex(index, duration, curve);
  }

  Future<void> scrollDelta(double pixels,
      [Duration duration = kDuration, Curve curve = kCurve]) async {
    await _state.scrollDelta(pixels, duration, curve);
  }

  ScrollController? getScrollController() => _state.getScrollController();

  queueScrollToEnd() {
    _state.queueScrollToEnd();
  }

  /// Replace all data, either loaded with [initialData] or [dataReceiver], with the provided data
  /// Will no longer load content on scroll after this is called.
  replaceDataWith(List<T> data) {
    _state.replaceDataWith(data);
  }

  replaceDataInRangeWith(Iterable<T> data, int start) {
    _state.replaceDataInRangeWith(data, start);
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
