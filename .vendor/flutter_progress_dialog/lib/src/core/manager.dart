import '../progress_dialog.dart';

class ProgressManager {
  ProgressManager._();

  static ProgressManager? _instance;

  factory ProgressManager() {
    _instance ??= ProgressManager._();
    return _instance!;
  }

  Set<ProgressFuture> futureSet = Set();

  void dismissAll({bool showAnim = false}) {
    futureSet.toList().forEach((v) {
      v.dismiss(showAnim: showAnim);
    });
  }

  void removeFuture(ProgressFuture future) {
    futureSet.remove(future);
  }

  void addFuture(ProgressFuture future) {
    futureSet.add(future);
  }
}
