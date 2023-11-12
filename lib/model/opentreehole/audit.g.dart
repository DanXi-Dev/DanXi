// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTAudit _$OTAuditFromJson(Map<String, dynamic> json) => OTAudit(
      json['content'] as String,
      json['hole_id'] as int,
      json['id'] as int,
      json['is_actual_sensitive'] as bool?,
      json['modified'] as int,
    );

Map<String, dynamic> _$OTAuditToJson(OTAudit instance) => <String, dynamic>{
      'content': instance.content,
      'hole_id': instance.hole_id,
      'id': instance.id,
      'is_actual_sensitive': instance.is_actual_sensitive,
      'modified': instance.modified,
    };
