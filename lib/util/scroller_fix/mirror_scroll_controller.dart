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

import 'package:dan_xi/page/home_page.dart';
import 'package:flutter/material.dart';

/// A scroll controller to imitate the scroll state of [originController],
/// but it allows multiple [attach] and [detach].
///
/// Why:
/// It is used in the situation that there are more than one [ListView]s on a
/// page which shows one of these [ListView]s at one time (i.e. a page with tab pages, like [HomePage]),
/// and in the different subpage you hope only the exact [ListView] on that subpage responds to
/// primary scroll control actions (e.g. double tap on the title bar on iOS).
/// When tab pages get initialized, all of its [ListView]s will try to attach themselves to
/// the same [PrimaryScrollController], which is not permitted. (See [ScrollController.position])
/// And this class is to solve such a problem, working as a decoration of [PrimaryScrollController].
///
/// Furthermore:
/// It is useless in most cases. If you find yourself in a situation that this class is necessary,
/// you should consider wrapping the layout of subpages with [Scaffold] or its subclasses, so every subpage has
/// its own [PrimaryScrollController] and conflict described above is easily prevented. It is my bad design that makes the
/// project fall into such a situation.
///
/// See also:
///   * [PrimaryScrollController]
///   * [PlatformSubpage]
///   * [PageWithPrimaryScrollController]
@Deprecated("You should not use this controller at the moment.")
class MirrorScrollController extends ScrollController {
  final ScrollController? originController;
  ScrollPosition? _oldPosition;
  String? debugTag;
  final BuildContext context;
  final List<AttachInterceptor> _interceptors = [];

  MirrorScrollController(this.originController, this.context, {this.debugTag})
      : assert(originController is! MirrorScrollController) {
    debugTag = debugTag ?? hashCode.toString();
  }

  @override
  double get initialScrollOffset => originController!.initialScrollOffset;

  @override
  void attach(ScrollPosition position) {
    // debugPrint("tryAttach: $debugTag");
    bool noClients = !hasClients;
    bool intercepted = _interceptors.every((element) => element.call());
    if (noClients && intercepted) {
      // detachPosition();
      // debugPrint("attach!!: $debugTag");
      originController!.attach(position);
    } else {
      // debugPrint(
      //     "$debugTag Attach failed, judgement(Should be true): noClients: $noClients, intercepted: $intercepted");
    }
    _oldPosition = position;
  }

  void addInterceptor(AttachInterceptor attachInterceptor) {
    _interceptors.add(attachInterceptor);
  }

  void removeInterceptor(AttachInterceptor attachInterceptor) {
    _interceptors.remove(attachInterceptor);
  }

  @override
  Iterable<ScrollPosition> get positions => originController!.positions;

  @override
  bool get hasClients => originController!.hasClients;

  @override
  ScrollPosition get position => originController!.position;

  @override
  double get offset => originController!.offset;

  @override
  Future<Function?> animateTo(double offset,
          {required Duration duration, required Curve curve}) =>
      originController!
          .animateTo(offset, duration: duration, curve: curve)
          .then((value) => value as Function?);

  @override
  void jumpTo(double value) => originController!.jumpTo(value);

  @override
  void detach(ScrollPosition position) {
    // debugPrint("tryDetach: $debugTag");
    if (positions.contains(position)) {
      originController!.detach(position);
      // debugPrint("detached!!: $debugTag");
    }
  }

  void detachPosition() {
    // debugPrint("detachAll: $debugTag");
    if (!hasClients) return;
    var tempPos = positions.toList();
    for (var element in tempPos) {
      if (positions.contains(element)) {
        try {
          originController!.detach(element);
          // We should catch errors from [ChangeNotifier._debugAssertNotDisposed] and omit them, since they will
          // be always thrown after offline notification from [_HomePageState._loadStartDate] in debug profile.
          //
          // Here, we simply ignore everything thrown.
        } catch (ignored) {}
      }
    }
  }

  void reattachPosition() {
    if (_oldPosition != null &&
        !originController!.positions.contains(_oldPosition)) {
      try {
        originController!.attach(_oldPosition!);
        // We should catch errors from [ChangeNotifier._debugAssertNotDisposed] and omit them, since they will
        // be always thrown after offline notification from [_HomePageState._loadStartDate] in debug profile.
        //
        // Here, we simply ignore everything thrown.
      } catch (ignored) {}
      // debugPrint("reattached!: $debugTag");
    }
  }

  @override
  void dispose() {
    originController!.dispose();
    super.dispose();
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      originController!.createScrollPosition(physics, context, oldPosition);

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    originController!.debugFillDescription(description);
  }
}

typedef AttachInterceptor = bool Function();
