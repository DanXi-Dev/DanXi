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

import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

/// A ListView supporting paged loading and viewing.
class PagedListView<T> extends StatefulWidget {
  /// Use the PagedListViewController to control its behaviour, e.g. refreshing
  final PagedListViewController pagedController;

  /// The data that will be used as preloaded data before loading.
  final List<T> initialData;

  /// The builder to build every list item.
  final IndexedDataWidgetBuilder<T> builder;

  /// The builder to build loading indicator.
  final WidgetBuilder loadingBuilder;

  /// The builder to build error tips.
  final AsyncWidgetBuilder<List<T>> errorBuilder;

  /// The builder to build end indicator.
  final WidgetBuilder endBuilder;

  /// The start number of page index, usually zero to say that the first page is Page 0.
  final int startPage;

  /// The method to load new data, usually from network.
  final DataReceiver<T> dataReceiver;

  /// The scrollController of the ListView. If not set, it will be PrimaryScrollController.
  final ScrollController scrollController;

  /// Should add a scrollbar or not. If true, [scrollController] may not be null.
  final bool withScrollbar;

  const PagedListView(
      {Key key,
      this.pagedController,
      this.initialData = const [],
      @required this.builder,
      @required this.loadingBuilder,
      @required this.errorBuilder,
      this.startPage = 0,
      @required this.endBuilder,
      @required this.dataReceiver,
      this.scrollController,
      this.withScrollbar = false})
      : assert(withScrollbar != null),
        assert((!withScrollbar) || (withScrollbar && scrollController != null)),
        super(key: key);

  @override
  _PagedListViewState<T> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  int pageIndex;
  bool _isRefreshing = false;
  bool _isEnded = false;
  List<T> _data = [];

  Future<List<T>> _futureData;

  @override
  Widget build(BuildContext context) {
    NotificationListenerCallback<ScrollNotification> scrollToEnd =
        (ScrollNotification scrollInfo) {
      if (scrollInfo.metrics.extentAfter < 500 && !_isRefreshing && !_isEnded) {
        pageIndex++;
        _isRefreshing = true;
        setState(() {
          _futureData = widget.dataReceiver(pageIndex);
        });
      }
      return false;
    };
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
    return FutureWidget<List<T>>(
        future: _futureData,
        successBuilder: (_, snapshot) {
          _isRefreshing = false;

          if (snapshot.data.isEmpty ||
              _data.isEmpty ||
              snapshot.data.last != _data.last) _data.addAll(snapshot.data);
          if (snapshot.data.isEmpty) _isEnded = true;
          return _buildListView();
        },
        errorBuilder: widget.errorBuilder,
        loadingBuilder: _buildListView());
  }

  _buildListView() {
    return ListView.builder(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _data.length + (_isRefreshing ? 1 : 0) + (_isEnded ? 1 : 0),
      itemBuilder: (context, index) => _getListItemAt(index),
    );
  }

  _getListItemAt(int index) {
    if (index < _data.length) {
      return widget.builder(context, index, _data[index]);
    } else if (index == _data.length) {
      if (_isRefreshing) {
        return widget.loadingBuilder(context);
      } else if (_isEnded) {
        return widget.endBuilder(context);
      }
    }
    return Container();
  }

  initialize() {
    _isRefreshing = _isEnded = false;
    _data.clear();
    pageIndex = widget.startPage;
    _futureData = Future.value(widget.initialData);
  }

  @override
  void initState() {
    super.initState();
    widget.pagedController?.setListener(() {
      initialize();
      refreshSelf();
    });
    initialize();
  }
}

class PagedListViewController {
  RefreshListener callback;

  PagedListViewController();

  @protected
  setListener(RefreshListener callback) {
    this.callback = callback;
  }

  notifyUpdate() {
    callback?.call();
  }
}

/// Build a widget with index & data
typedef IndexedDataWidgetBuilder<T> = Widget Function(
    BuildContext context, int index, T data);

/// Retrieve data function
typedef DataReceiver<T> = Future<List<T>> Function(int pageIndex);

/// Notify refreshing callback
typedef RefreshListener = void Function();
