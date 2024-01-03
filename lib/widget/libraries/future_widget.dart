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

import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/smart_widget.dart';
import 'package:flutter/material.dart';

/// [FutureWidget] is a variation of [FutureBuilder],
/// which will build different widgets depending on different states: See [ConnectionState.values].
class FutureWidget<T> extends StatefulWidget {
  const FutureWidget(
      {super.key,
      this.initialData,
      required this.future,
      required this.successBuilder,
      required this.errorBuilder,
      required this.loadingBuilder,
      this.nullable = false});
  final dynamic errorBuilder;
  final dynamic loadingBuilder;
  final Future<T>? future;
  final AsyncWidgetBuilder<T> successBuilder;
  final T? initialData;

  /// Decide how the widget respond to the situation that snapshot.data is null
  /// but snapshot.error is null, too.
  ///
  /// If [nullable] is true, [successBuilder] will be called;
  /// If [nullable] is false, [errorBuilder] will be called;
  final bool nullable;

  @override
  State<FutureWidget<T>> createState() => _FutureWidgetState<T>();
}

/// State for [FutureWidget].
class _FutureWidgetState<T> extends State<FutureWidget<T>> {
  /// An object that identifies the currently active callbacks. Used to avoid
  /// calling setState from stale callbacks, e.g. after disposal of this state,
  /// or after widget reconfiguration to a new Future.
  Object? _activeCallbackIdentity;
  AsyncSnapshot<T>? _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(
            ConnectionState.none, widget.initialData as T);
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot!.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_snapshot!.connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
      case ConnectionState.active:
        return SmartWidget.toWidget<T>(widget.loadingBuilder, context,
            snapshot: _snapshot);
      case ConnectionState.done:
        if (_snapshot!.hasError || (!_snapshot!.hasData && !widget.nullable)) {
          return SmartWidget.toWidget<T>(widget.errorBuilder, context,
              snapshot: _snapshot);
        } else {
          return SmartWidget.toWidget<T>(widget.successBuilder, context,
              snapshot: _snapshot);
        }
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.future != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future!.then<void>((T data) {
        // Process the situation that [widget.future] is LazyFuture
        if (data == null && widget.future is LazyFuture<T>) {
          LazyFuture<T> lazyImpl = widget.future as LazyFuture<T>;
          if (lazyImpl.error != null) {
            _onError(callbackIdentity, lazyImpl.error, lazyImpl.stackTrace);
            return;
          }
        }

        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error, StackTrace stackTrace) {
        _onError(callbackIdentity, error, stackTrace);
      });
      _snapshot = _snapshot!.inState(ConnectionState.waiting);
    }
  }

  void _onError(Object callbackIdentity, Object error, StackTrace stackTrace) {
    if (_activeCallbackIdentity == callbackIdentity) {
      setState(() {
        _snapshot =
            AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
      });
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}
