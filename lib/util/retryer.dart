class Retryer {
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
