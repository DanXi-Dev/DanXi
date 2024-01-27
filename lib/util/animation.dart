/*
 *     Copyright (C) 2021  Odyso Project
 */

import 'package:flutter/material.dart';

class MySlideTransition extends AnimatedWidget {
  const MySlideTransition({
    super.key,
    required Animation<Offset> position,
    this.transformHitTests = true,
    required this.child,
  }) : super(listenable: position);

  Animation<Offset> get position => listenable as Animation<Offset>;
  final bool transformHitTests;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Offset offset = position.value;
    //当即将执行退场动画时
    if (position.status == AnimationStatus.reverse) {
      offset = Offset(-offset.dx, offset.dy);
    }
    return FractionalTranslation(
      translation: offset,
      transformHitTests: transformHitTests,
      child: child,
    );
  }
}
