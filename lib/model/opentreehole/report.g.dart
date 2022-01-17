// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTReport _$OTReportFromJson(Map<String, dynamic> json) => OTReport(
      json['report_id'] as int?,
      json['reason'] as String?,
      json['content'] as String?,
      json['floor'] == null
          ? null
          : OTFloor.fromJson(json['floor'] as Map<String, dynamic>),
      json['hole_id'] as int?,
      json['time_created'] as String?,
      json['time_updated'] as String?,
      json['dealed'] as bool?,
      json['dealed_by'] as String?,
    );

Map<String, dynamic> _$OTReportToJson(OTReport instance) => <String, dynamic>{
      'report_id': instance.report_id,
      'reason': instance.reason,
      'content': instance.content,
      'floor': instance.floor,
      'hole_id': instance.hole_id,
      'time_created': instance.time_created,
      'time_updated': instance.time_updated,
      'dealed': instance.dealed,
      'dealed_by': instance.dealed_by,
    };
