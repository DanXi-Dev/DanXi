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
  ///
  /// Note: 2022/1/18 Must specify [retryTimes], or won't retry.
  static E runWithRetry<E>(E Function() function, {int retryTimes = 0}) {
    dynamic error;
    StackTrace? stack;
    for (int i = 0; i <= retryTimes; i++) {
      try {
        return function();
      } catch (e, st) {
        error = e;
        stack = st;
      }
    }
    Error.throwWithStackTrace(error, stack!);
  }

  /// Try to run [function] for [retryTimes] times asynchronously.
  /// Return the results of [function] if it executes successfully. Otherwise, throw an error that [function] threw.
  ///
  /// Note: 2022/1/18 Must specify [retryTimes], or won't retry.
  static Future<E> runAsyncWithRetry<E>(Future<E> Function() function,
      {int retryTimes = 0}) async {
    late Function errorCatcher;
    errorCatcher = (e, stack) async {
      if (retryTimes > 0) {
        retryTimes--;
        return await function().catchError(errorCatcher);
      } else {
        Error.throwWithStackTrace(e, stack);
      }
    };
    return await function().catchError(errorCatcher);
  }

  /// Try to run [function] for [retryTimes] times asynchronously.
  /// If [function] throws an error, run [tryFix] to fix the problem. Then run the function again.
  /// If [isFatalError] is provided, check if the error is fatal. If it is, stop retrying and throw the error immediately.
  /// If [isFatalRetryError] is provided, check if the error is fatal for retry. If it is, stop retrying and throw the error immediately.
  ///     Otherwise, any error thrown by [tryFix] will be ignored.
  ///
  /// Return the results of [function] if it executes successfully. Otherwise, throw an error that [function] threw.
  ///
  /// Note: 2022/1/18 Must specify [retryTimes], or will only retry once.
  static Future<E> tryAsyncWithFix<E>(
      Future<E> Function() function, Future<void> Function(dynamic) tryFix,
      {int retryTimes = 1, bool Function(dynamic error)? isFatalError, bool Function(dynamic error)? isFatalRetryError}) async {
    late Function errorCatcher;
    errorCatcher = (e, stack) async {
      if (isFatalError != null && isFatalError(e)) {
        Error.throwWithStackTrace(e, stack);
      }
      if (retryTimes > 0) {
        retryTimes--;
        try {
          await tryFix(e);
        } catch (e) {
          if (isFatalRetryError != null && isFatalRetryError(e)) {
            Error.throwWithStackTrace(e, stack);
          }
        }
        return await function().catchError(errorCatcher);
      } else {
        Error.throwWithStackTrace(e, stack);
      }
    };
    return await function().catchError(errorCatcher);
  }
}
