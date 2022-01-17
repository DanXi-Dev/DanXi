// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostTag _$PostTagFromJson(Map<String, dynamic> json) {
  return PostTag(
    json['name'] as String,
    json['color'] as String,
    json['count'] as int,
  );
}

Map<String, dynamic> _$PostTagToJson(PostTag instance) => <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'count': instance.count,
    };
