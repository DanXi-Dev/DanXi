// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTHistory _$OTHistoryFromJson(Map<String, dynamic> json) => OTHistory(
      json['content'] as String?,
      json['altered_by'] as int?,
      json['altered_time'] as String?,
    );

Map<String, dynamic> _$OTHistoryToJson(OTHistory instance) => <String, dynamic>{
      'content': instance.content,
      'altered_by': instance.altered_by,
      'altered_time': instance.altered_time,
    };
