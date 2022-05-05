// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
      json['content'] as String?,
    )
      ..createdAt = json['createdAt'] as String?
      ..updatedAt = json['updatedAt'] as String?
      ..objectId = json['objectId'] as String?
      ..maxVersion = json['maxVersion'] as int?;

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'objectId': instance.objectId,
      'content': instance.content,
      'maxVersion': instance.maxVersion,
    };
