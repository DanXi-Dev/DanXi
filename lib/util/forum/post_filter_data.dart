import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';

Map<String, dynamic>? getPostFilterHoleMap(OTHole? hole) {
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
    'first': getPostFilterFloorMap(first),
    'content': firstContent,
    'firstContent': firstContent,
    'last': getPostFilterFloorMap(last),
    'lastContent': lastContent,
  };
}

Map<String, dynamic>? getPostFilterFloorMap(OTFloor? floor) {
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
            ?.map((m) => getPostFilterFloorMap(m))
            .toList(growable: false) ??
        const [],
  };
}
