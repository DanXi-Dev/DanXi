// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'punishment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTPunishment _$OTPunishmentFromJson(Map<String, dynamic> json) => OTPunishment(
      json['created_at'] as String?,
      json['deleted_at'] as String?,
      json['division_id'] as int?,
      json['duration'] as int?,
      json['end_time'] as String?,
      json['floor'] == null
          ? null
          : OTFloor.fromJson(json['floor'] as Map<String, dynamic>),
      json['floor_id'] as int?,
      json['id'] as int?,
      json['made_by'] as int?,
      json['reason'] as String?,
      json['start_time'] as String?,
      json['user_id'] as int?,
    );

Map<String, dynamic> _$OTPunishmentToJson(OTPunishment instance) =>
    <String, dynamic>{
      'created_at': instance.created_at,
      'deleted_at': instance.deleted_at,
      'division_id': instance.division_id,
      'duration': instance.duration,
      'end_time': instance.end_time,
      'floor': instance.floor,
      'floor_id': instance.floor_id,
      'id': instance.id,
      'made_by': instance.made_by,
      'reason': instance.reason,
      'start_time': instance.start_time,
      'user_id': instance.user_id,
    };
