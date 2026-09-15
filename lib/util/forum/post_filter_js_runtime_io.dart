import 'dart:convert';

import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:flutter_js/flutter_js.dart';

class PostFilterJsRuntime {
  static const bool isSupported = true;

  late final JavascriptRuntime _runtime = getJavascriptRuntime(xhr: false);

  bool evaluateHole(String expression, OTHole hole) {
    final holeMap = _buildPostFilterHoleMap(hole)!;
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
    final floorMap = _buildPostFilterFloorMap(floor)!;
    final holeMap = _buildPostFilterHoleMap(hole);
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

  static Map<String, dynamic>? _buildPostFilterHoleMap(OTHole? hole) {
    if (hole == null) {
      return null;
    }
    final first = hole.floors?.first_floor;
    final firstContent = first?.filteredContent ?? '';
    final last = hole.floors?.last_floor;
    final lastContent = last?.filteredContent ?? '';
    return {
      'id': hole.hole_id,
      'holeId': hole.hole_id,
      'divisionId': hole.division_id,
      'tags':
          hole.tags
              ?.map((tag) => tag.name)
              .whereType<String>()
              .toList(growable: false) ??
          const [],
      'view': hole.view ?? 0,
      'reply': hole.reply ?? 0,
      'favoriteCount': hole.favorite_count ?? 0,
      'subscriptionCount': hole.subscription_count ?? 0,
      'timeCreated': hole.time_created,
      'created': hole.time_created,
      'timeUpdated': hole.time_updated,
      'updated': hole.time_updated,
      'first': _buildPostFilterFloorMap(first),
      'content': firstContent,
      'firstContent': firstContent,
      'last': _buildPostFilterFloorMap(last),
      'lastContent': lastContent,
    };
  }

  static Map<String, dynamic>? _buildPostFilterFloorMap(OTFloor? floor) {
    if (floor == null) {
      return null;
    }
    return {
      'id': floor.floor_id,
      'floorId': floor.floor_id,
      'holeId': floor.hole_id,
      'content': floor.filteredContent ?? '',
      'anonyname': floor.anonyname,
      'name': floor.anonyname,
      'specialTag': floor.special_tag,
      'timeCreated': floor.time_created,
      'created': floor.time_created,
      'timeUpdated': floor.time_updated,
      'updated': floor.time_updated,
      'deleted': floor.deleted ?? false,
      'modified': floor.modified ?? false,
      'isMe': floor.is_me ?? false,
      'liked': floor.liked ?? false,
      'disliked': floor.disliked ?? false,
      'like': floor.like ?? 0,
      'dislike': floor.dislike ?? 0,
      'mention':
          floor.mention
              ?.map((m) => _buildPostFilterFloorMap(m))
              .toList(growable: false) ??
          const [],
    };
  }

  static final _identifierRegex = RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$');

  static String _postGlobalDeclarations(Map<String, dynamic> post) {
    return post.keys
        .where(_identifierRegex.hasMatch)
        .map((key) => 'const $key = post[${jsonEncode(key)}];')
        .join('\n');
  }

  void dispose() {
    _runtime.dispose();
  }
}
