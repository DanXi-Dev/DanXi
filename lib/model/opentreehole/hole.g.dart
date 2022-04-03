// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hole.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTHole _$OTHoleFromJson(Map<String, dynamic> json) => OTHole(
      json['id'] as int?,
      json['division_id'] as int?,
      json['time_created'] as String?,
      json['time_updated'] as String?,
      (json['tags'] as List<dynamic>?)
          ?.map((e) => OTTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['view'] as int?,
      json['reply'] as int?,
      json['floors'] == null
          ? null
          : OTFloors.fromJson(json['floors'] as Map<String, dynamic>),
    )..hidden = json['hidden'] as bool?;

Map<String, dynamic> _$OTHoleToJson(OTHole instance) =>
    <String, dynamic>{
      'id': instance.id,
      'division_id': instance.division_id,
      'time_updated': instance.time_updated,
      'time_created': instance.time_created,
      'tags': instance.tags,
      'view': instance.view,
      'reply': instance.reply,
      'floors': instance.floors,
      'hidden': instance.hidden,
    };
