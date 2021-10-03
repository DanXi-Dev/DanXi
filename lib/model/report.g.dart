// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) {
  return Report(
    json['id'] as int,
    json['reason'] as String,
    json['post'] as int,
    json['date_created'] as String,
    json['dealed'] as bool,
    json['content'] as String,
    json['discussion'] as int,
  );
}

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
      'id': instance.id,
      'reason': instance.reason,
      'content': instance.content,
      'discussion': instance.discussion,
      'post': instance.post,
      'date_created': instance.date_created,
      'dealed': instance.dealed,
    };
