// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTMessage _$OTMessageFromJson(Map<String, dynamic> json) => OTMessage(
      json['message_id'] as int?,
      json['message'] as String?,
      json['code'] as String?,
      json['time_created'] as String?,
      json['has_read'] as bool?,
      json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OTMessageToJson(OTMessage instance) => <String, dynamic>{
      'message_id': instance.message_id,
      'message': instance.message,
      'code': instance.code,
      'time_created': instance.time_created,
      'has_read': instance.has_read,
      'data': instance.data,
    };
