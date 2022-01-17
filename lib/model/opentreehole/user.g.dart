// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTUser _$OTUserFromJson(Map<String, dynamic> json) => OTUser(
      json['user_id'] as int?,
      json['nickname'] as String?,
      (json['favorites'] as List<dynamic>?)?.map((e) => e as int).toList(),
      json['is_admin'] as bool?,
      json['joined_time'] as String?,
      json['config'] == null
          ? null
          : OTUserConfig.fromJson(json['config'] as Map<String, dynamic>),
      json['permission'] == null
          ? null
          : OTUserPermission.fromJson(
              json['permission'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OTUserToJson(OTUser instance) => <String, dynamic>{
      'user_id': instance.user_id,
      'nickname': instance.nickname,
      'favorites': instance.favorites,
      'permission': instance.permission,
      'config': instance.config,
      'joined_time': instance.joined_time,
      'is_admin': instance.is_admin,
    };
