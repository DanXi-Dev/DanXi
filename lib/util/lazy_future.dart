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

import 'dart:async';

/// [LazyFuture] will NEVER throw an unhandled error when it is thrown by the async method but not caught.
/// Instead, [LazyFuture] will throw the error immediately after having an error handler
/// (i.e. .then() and .catchError()).
class LazyFuture<T> implements Future<T> {
  late Future<T> _thisFuture;
  dynamic _error;
  dynamic _stackTrace;

  dynamic get error => _error;

  LazyFuture.pack(Future<T> future) {
    _thisFuture = future.catchError((error, stackTrace) {
      _error = error;
      _stackTrace = stackTrace;
    });
  }

  @override
  Stream<T> asStream() => _thisFuture.asStream();

  @override
  Future<T> catchError(Function onErr, {bool Function(Object error)? test}) {
    return _error != null
        ? Future<T>.error(_error, _stackTrace).catchError(onErr, test: test)
        : _thisFuture.catchError(onErr, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue,
      {Function? onError}) {
    return _error != null
        ? Future<T>.error(_error, _stackTrace).then(onValue, onError: onError)
        : _thisFuture.then(onValue, onError: onError);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _thisFuture.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _thisFuture.whenComplete(action);

  dynamic get stackTrace => _stackTrace;
}
