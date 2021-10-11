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

/// Helper class to retry when errors occur.
///
/// Useful when net connection is unstable.
class Retrier {
  /// Try to run [function] for [retryTimes] times synchronously.
  /// Return the results of [function] if it executes successfully. Otherwise, throw an error that [function] threw.
  static E runWithRetry<E>(E function(), {int retryTimes = 3}) {
    Exception? error;
    for (int i = 0; i < retryTimes; i++) {
      try {
        return function();
      } catch (e) {
        error = e as Exception;
      }
    }
    throw error!;
  }

  /// Try to run [function] for [retryTimes] times asynchronously.
  /// Return the results of [function] if it executes successfully. Otherwise, throw an error that [function] threw.
  static Future<E> runAsyncWithRetry<E>(Future<E> function(),
      {int retryTimes = 1}) async {
    late Function errorCatcher;
    errorCatcher = (e) async {
      if (retryTimes > 0) {
        retryTimes--;
        return await function().catchError(errorCatcher);
      } else {
        throw e;
      }
    };
    return await function().catchError(errorCatcher);
  }

  /// Try to run [function] for [retryTimes] times asynchronously.
  ///
  /// If [function] throws an error, run [tryFix] to fix the problem. Then run the function again.
  ///
  /// Notes: Any errors thrown by [tryFix] will be ignored.
  ///
  /// Return the results of [function] if it executes successfully. Otherwise, throw an error that [function] threw.
  static Future<E> tryAsyncWithFix<E>(
      Future<E> function(), Future<void> tryFix(exception),
      {int retryTimes = 2}) async {
    late Function errorCatcher;
    errorCatcher = (e, stack) async {
      // debugPrintStack(stackTrace: stack);
      if (retryTimes > 0) {
        retryTimes--;
        await tryFix(e).catchError((error, stackTrace) {
          // debugPrint("Error when trying fix ${function.runtimeType.toString()}:");
          // debugPrint(error.toString());
          // debugPrint(stackTrace.toString());
        });
        return await function().catchError(errorCatcher);
      } else {
        throw e;
      }
    };
    return await function().catchError(errorCatcher);
  }

  /// Try to run [function] asynchronously, and forever.
  /// Return the results of [function] if it executes successfully. Otherwise, it will be stuck in an infinite loop.
  static Future<E> runAsyncWithRetryForever<E>(Future<E> function()) async {
    late Function errorCatcher;
    errorCatcher = (e) async => await function().catchError(errorCatcher);
    return await function().catchError(errorCatcher);
  }
}
