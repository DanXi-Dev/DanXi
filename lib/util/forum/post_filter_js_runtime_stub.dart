import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';

class PostFilterJsRuntime {
  static const bool isSupported = false;

  bool evaluateHole(String expression, OTHole hole) => false;

  bool evaluateFloor(String expression, OTFloor floor, {OTHole? hole}) => false;

  void dispose() {}
}
