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

import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/widgets.dart';

class MirrorScrollController extends ScrollController {
  final ScrollController originController;
  ScrollPosition _oldPosition;
  String debugTag;
  final BuildContext context;
  List<AttachInterceptor> _interceptors = [];
  bool _isMaterial;

  MirrorScrollController(this.originController, this.context, {this.debugTag})
      : assert(originController is! MirrorScrollController) {
    debugTag = debugTag ?? hashCode.toString();
    _isMaterial = PlatformX.isMaterial(context);
  }

  @override
  double get initialScrollOffset => originController.initialScrollOffset;

  @override
  void attach(ScrollPosition position) {
    // debugPrint("tryAttach: $debugTag");
    bool noClients = !hasClients;
    bool intercepted =
        _interceptors.every((element) => element?.call() ?? true);
    if (noClients && intercepted) {
      // detachPosition();
      // debugPrint("attach!!: $debugTag");
      originController.attach(position);
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
  Iterable<ScrollPosition> get positions => originController.positions;

  @override
  bool get hasClients => originController.hasClients;

  @override
  ScrollPosition get position => originController.position;

  @override
  double get offset => originController.offset;

  @override
  Future<Function> animateTo(double offset,
          {@required Duration duration, @required Curve curve}) =>
      originController.animateTo(offset, duration: duration, curve: curve);

  @override
  void jumpTo(double value) => originController.jumpTo(value);

  @override
  void detach(ScrollPosition position) {
    // debugPrint("tryDetach: $debugTag");
    if (positions.contains(position)) {
      originController.detach(position);
      // debugPrint("detached!!: $debugTag");
    }
  }

  void detachPosition() {
    // debugPrint("detachAll: $debugTag");
    if (!hasClients) return;
    var tempPos = positions.toList();
    tempPos.forEach((element) {
      if (positions.contains(element)) originController.detach(element);
    });
  }

  void reattachPosition() {
    if (_isMaterial &&
        _oldPosition != null &&
        !originController.positions.contains(_oldPosition)) {
      originController.attach(_oldPosition);
      // debugPrint("reattached!: $debugTag");
    }
  }

  @override
  void dispose() {
    originController.dispose();
    super.dispose();
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition oldPosition) =>
      originController.createScrollPosition(physics, context, oldPosition);

  @override
  void debugFillDescription(List<String> description) =>
      originController.debugFillDescription(description);
}

typedef AttachInterceptor = bool Function();
