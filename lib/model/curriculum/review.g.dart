// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      json['id'] as int?,
      json['title'] as String?,
      json['content'] as String?,
      json['time_created'] as String?,
      json['rank'] as String?,
      json['remark'] as int?,
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'time_created': instance.time_created,
      'rank': instance.rank,
      'remark': instance.remark,
    };
