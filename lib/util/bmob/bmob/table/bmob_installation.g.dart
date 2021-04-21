// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_installation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobInstallation _$BmobInstallationFromJson(Map<String, dynamic> json) {
  return BmobInstallation()
    ..createdAt = json['createdAt'] as String
    ..updatedAt = json['updatedAt'] as String
    ..objectId = json['objectId'] as String
    ..ACL = json['ACL'] as Map<String, dynamic>
    ..deviceType = json['deviceType'] as String
    ..installationId = json['installationId'] as String
    ..timeZone = json['timeZone'] as String
    ..deviceToken = json['deviceToken'] as String;
}

Map<String, dynamic> _$BmobInstallationToJson(BmobInstallation instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'objectId': instance.objectId,
      'ACL': instance.ACL,
      'deviceType': instance.deviceType,
      'installationId': instance.installationId,
      'timeZone': instance.timeZone,
      'deviceToken': instance.deviceToken
    };
