// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTHistory _$OTHistoryFromJson(Map<String, dynamic> json) => OTHistory(
      json['content'] as String?,
      json['user_id'] as int?,
      json['time_updated'] as String?,
    );

Map<String, dynamic> _$OTHistoryToJson(OTHistory instance) => <String, dynamic>{
      'content': instance.content,
      'user_id': instance.user_id,
      'time_updated': instance.time_updated,
    };
