// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTUserPermission _$OTUserPermissionFromJson(Map<String, dynamic> json) {
  return OTUserPermission(
    json['silent'] == null
        ? null
        : OTUserPermissionSilentConfig.fromJson(
            json['silent'] as Map<String, dynamic>),
    json['admin'] as String?,
  );
}

Map<String, dynamic> _$OTUserPermissionToJson(OTUserPermission instance) =>
    <String, dynamic>{
      'silent': instance.silent,
      'admin': instance.admin,
    };
