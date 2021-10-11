// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'fduhole_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FduholeProfile _$FduholeProfileFromJson(Map<String, dynamic> json) {
  return FduholeProfile(
    json['id'] as int,
    json['user'] == null
        ? null
        : FduholeUser.fromJson(json['user'] as Map<String, dynamic>),
    (json['favored_discussion'] as List)
        ?.map((e) =>
            e == null ? null : BBSPost.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['encrypted_email'] as String,
  );
}

Map<String, dynamic> _$FduholeProfileToJson(FduholeProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'favored_discussion': instance.favored_discussion,
      'encrypted_email': instance.encrypted_email,
    };
