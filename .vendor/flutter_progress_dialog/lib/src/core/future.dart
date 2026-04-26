part of '../progress_dialog.dart';

/// use the [dismiss] to dismiss ProgressDialog.
class ProgressFuture {
  final OverlayEntry _entry;
  final VoidCallback? _onDismiss;
  bool _isShow = true;
  final GlobalKey<_ProgressContainerState> _containerKey;

  ProgressFuture._(
    this._entry,
    this._onDismiss,
    this._containerKey,
  );

  void dismiss({bool showAnim = true}) {
    if (!_isShow) {
      return;
    }
    _isShow = false;
    _onDismiss?.call();
    ProgressManager().removeFuture(this);

    if (showAnim) {
      _containerKey.currentState!.showDismissAnim();
      Future.delayed(_opacityDuration, () {
        _entry.remove();
      });
    } else {
      _entry.remove();
    }
  }
}
