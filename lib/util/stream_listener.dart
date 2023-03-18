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

class StateStreamListener<T> extends StreamListener<T, int> {}

/// A [StreamSubscription] that will update the [_subscription] when [_unitCode] changes.
///
/// Usually used in a [State.initState] to prevent the subscription being called after it's invalid.
///
/// Example:
///
/// ```dart
/// class _OneState extends State<One>{
///   static StateStreamListener _subscription = StateStreamListener();
///
///   @override
///   void initState() {
///     super.initState();
///     _subscription.bindOnlyInvalid(
//         Constant.eventBus
///             .on<Event>()
///             .listen((_) => refreshSelf()),
///         hashCode);
///   }
///
///   @override
///   void dispose() {
///     super.dispose();
///     _subscription.cancel();
///   }
/// }
/// ```

class StreamListener<T, S> {
  StreamSubscription<T>? _subscription;
  S? _unitCode;

  bool bindOnlyInvalid(
      StreamSubscription<T> streamSubscription, S newUnitCode) {
    if (isInvalid(newUnitCode)) {
      // Try cancelling the old subscription.
      if (_subscription != null) {
        cancel();
      }
      _subscription = streamSubscription;
      _unitCode = newUnitCode;
      return true;
    } else {
      return false;
    }
  }

  /// Notes: When calling it, you needn't determine if [_subscription] is null!
  Future<void>? cancel() async => _subscription
      ?.cancel()
      .catchError((ignored) {})
      .whenComplete(() => _subscription = null);

  bool isInvalid(S newUnitCode) {
    return _subscription == null || _unitCode != newUnitCode;
  }

  StreamListener();
}
