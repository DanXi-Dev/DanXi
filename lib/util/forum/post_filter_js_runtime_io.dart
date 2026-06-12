import 'dart:convert';

import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/util/forum/post_filter_data.dart';
import 'package:flutter_js/flutter_js.dart';

class PostFilterJsRuntime {
  static const bool isSupported = true;

  late final JavascriptRuntime _runtime = getJavascriptRuntime(xhr: false);

  bool evaluateHole(String expression, OTHole hole) {
    final holeMap = getPostFilterHoleMap(hole)!;
    final postDeclarations = _postGlobalDeclarations(holeMap);
    final script =
        '''(() => {
          "use strict";
          const hole = ${jsonEncode(holeMap)};
          const post = hole;
          $postDeclarations
          return Boolean($expression);
        })()''';
    final result = _runtime.evaluate(script);
    return !result.isError &&
        (result.rawResult == true || result.stringResult == 'true');
  }

  bool evaluateFloor(String expression, OTFloor floor, {OTHole? hole}) {
    final floorMap = getPostFilterFloorMap(floor)!;
    final holeMap = getPostFilterHoleMap(hole);
    final postDeclarations = _postGlobalDeclarations(floorMap);
    final script =
        '''(() => {
          "use strict";
          const floor = ${jsonEncode(floorMap)};
          const hole = ${jsonEncode(holeMap)};
          const post = floor;
          $postDeclarations
          return Boolean($expression);
        })()''';
    final result = _runtime.evaluate(script);
    return !result.isError &&
        (result.rawResult == true || result.stringResult == 'true');
  }

  final _identifierRegex = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');

  String _postGlobalDeclarations(Map<String, dynamic> post) {
    return post.keys
        .where(_identifierRegex.hasMatch)
        .map((key) => 'const $key = post[${jsonEncode(key)}];')
        .join('\n');
  }

  void dispose() {
    _runtime.dispose();
  }
}
