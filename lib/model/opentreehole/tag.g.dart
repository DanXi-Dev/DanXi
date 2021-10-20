// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTTag _$OTTagFromJson(Map<String, dynamic> json) {
  return OTTag(
    json['tag_id'] as int?,
    json['temperature'] as int?,
    json['name'] as String?,
  );
}

Map<String, dynamic> _$OTTagToJson(OTTag instance) => <String, dynamic>{
      'tag_id': instance.tag_id,
      'temperature': instance.temperature,
      'name': instance.name,
    };
