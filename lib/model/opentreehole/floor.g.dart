// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTFloor _$OTFloorFromJson(Map<String, dynamic> json) {
  return OTFloor(
    json['floor_id'] as int?,
    json['hole_id'] as int?,
    json['content'] as String?,
    json['anonyname'] as String?,
    json['time_created'] as String?,
    json['time_updated'] as String?,
    json['deleted'] as bool?,
    (json['fold'] as List<dynamic>?)?.map((e) => e as String).toList(),
    json['like'] as int?,
    json['is_me'] as bool?,
    json['liked'] as bool?,
    (json['mention'] as List<dynamic>?)
        ?.map((e) => OTFloor.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$OTFloorToJson(OTFloor instance) => <String, dynamic>{
      'floor_id': instance.floor_id,
      'hole_id': instance.hole_id,
      'content': instance.content,
      'anonyname': instance.anonyname,
      'time_updated': instance.time_updated,
      'time_created': instance.time_created,
      'deleted': instance.deleted,
      'is_me': instance.is_me,
      'liked': instance.liked,
      'fold': instance.fold,
      'like': instance.like,
      'mention': instance.mention,
    };
