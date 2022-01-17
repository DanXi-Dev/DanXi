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

import 'package:flutter/widgets.dart';

class MirrorScrollController extends ScrollController {
  final ScrollController originController;
  ScrollPosition _oldPosition;
  String debugTag;

  MirrorScrollController(this.originController, {this.debugTag})
      : assert(originController is! MirrorScrollController) {
    debugTag = debugTag ?? hashCode.toString();
  }

  @override
  double get initialScrollOffset => originController.initialScrollOffset;

  @override
  void attach(ScrollPosition position) {
    debugPrint("tryAttach: $debugTag");
    if (!hasClients) {
      debugPrint("attach!!: $debugTag");
      originController.attach(position);
    }
    _oldPosition = position;
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
    debugPrint("detach: $debugTag");
    originController.detach(position);
  }

  void detachPosition() {
    if (!hasClients) return;
    var tempPos = positions.toList();
    tempPos.forEach((element) {
      if (positions.contains(element)) detach(element);
    });
  }

  void reattachPosition() {
    if (_oldPosition != null &&
        !originController.positions.contains(_oldPosition)) {
      originController.attach(_oldPosition);
      debugPrint("reattached!: $debugTag");
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
