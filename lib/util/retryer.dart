/*
 *     Copyright (C) 2021  w568w
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

//Retry when errors occur. Useful with unstable net connection
class Retrier {
  static E runWithRetry<E>(E function(), {int retryTimes = 3}) {
    Exception error;
    for (int i = 0; i < retryTimes; i++) {
      try {
        return function();
      } catch (e) {
        error = e;
      }
    }
    throw error;
  }

  static Future<E> runAsyncWithRetry<E>(Future<E> function(),
      {int retryTimes = 3}) async {
    Function errorCatcher;
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
}
