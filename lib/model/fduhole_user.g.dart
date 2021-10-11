// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'fduhole_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FduholeUser _$FduholeUserFromJson(Map<String, dynamic> json) {
  return FduholeUser(
    json['username'] as String,
    json['is_active'] as bool,
    json['is_staff'] as bool,
    json['is_superuser'] as bool,
    (json['favored_discussion'] as List)
        ?.map((e) =>
            e == null ? null : BBSPost.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['encrypted_email'] as String,
  );
}

Map<String, dynamic> _$FduholeUserToJson(FduholeUser instance) =>
    <String, dynamic>{
      'username': instance.username,
      'is_active': instance.is_active,
      'is_staff': instance.is_staff,
      'is_superuser': instance.is_superuser,
      'favored_discussion': instance.favored_discussion,
      'encrypted_email': instance.encrypted_email,
    };
