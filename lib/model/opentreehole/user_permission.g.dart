// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTUserPermission _$OTUserPermissionFromJson(Map<String, dynamic> json) =>
    OTUserPermission(
      (json['silent'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as String),
      ),
      json['admin'] as String?,
    );

Map<String, dynamic> _$OTUserPermissionToJson(OTUserPermission instance) =>
    <String, dynamic>{
      'silent': instance.silent?.map((k, e) => MapEntry(k.toString(), e)),
      'admin': instance.admin,
    };
