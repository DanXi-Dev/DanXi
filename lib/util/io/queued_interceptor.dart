/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'dart:collection';

import 'package:dan_xi/model/pair.dart';
import 'package:dio/dio.dart';

/// The number of how many requests we allow to be executed simultaneously.
const _kQueueLengthLimit = 4;

/// A [QueuedInterceptor] can limit the number of concurrent requests.
class LimitedQueuedInterceptor extends QueuedInterceptor {
  static final LimitedQueuedInterceptor _instance =
      LimitedQueuedInterceptor._();

  /// The completer of requests executing at the moment.
  final Queue<Completer<void>> _requestWorkingQueue = Queue<Completer<void>>();

  /// The requests waiting to be executed.
  final Queue<Pair<RequestOptions, RequestInterceptorHandler>>
      _requestWaitingQueue =
      Queue<Pair<RequestOptions, RequestInterceptorHandler>>();

  LimitedQueuedInterceptor._();

  factory LimitedQueuedInterceptor.getInstance() => _instance;

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // Notify a completer in queue to complete itself.
    //
    // Note: We do NOT care the match between [RequestOptions] and [Completer<void>],
    // so we just arbitrarily pop up the first completer here.
    // The queue is only used to indicate how many requests are being executed now.
    _requestWorkingQueue.removeFirst().complete();
    print(
        "-> New error, working queue length = ${_requestWorkingQueue.length}");
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Notify a completer in queue to complete itself.
    _requestWorkingQueue.removeFirst().complete();
    print(
        "-> New response, working queue length = ${_requestWorkingQueue.length}");
    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // If there are fewer requests than [_kQueueLengthLimit], we just request at once.
    if (_requestWorkingQueue.length < _kQueueLengthLimit) {
      _requestWorkingQueue.add(Completer());
      print(
          "<- New request directly goes, working queue length = ${_requestWorkingQueue.length}");
      handler.next(options);
      return;
    }
    // Else, we add it to the [_requestWaitingQueue] and wait for any request to complete.
    print(
        "!! New request has to wait now, because working queue length = ${_requestWorkingQueue.length}");
    _requestWaitingQueue.add(Pair(options, handler));

    Future.any(_requestWorkingQueue.map((e) => e.future)).then((_) {
      // Launch the request when we have free rocket pod.
      Pair<RequestOptions, RequestInterceptorHandler> requestHandlerPair =
          _requestWaitingQueue.removeFirst();
      _requestWorkingQueue.add(Completer());
      print(
          "<! New request finally gets its turn, working queue length = ${_requestWorkingQueue.length}");
      requestHandlerPair.second.next(requestHandlerPair.first);
    });
  }
}
