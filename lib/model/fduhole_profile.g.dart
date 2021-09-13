// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fduhole_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FduholeProfile _$FduholeProfileFromJson(Map<String, dynamic> json) =>
    FduholeProfile(
      json['id'] as int,
      FduholeUser.fromJson(json['user'] as Map<String, dynamic>),
      (json['favored_discussion'] as List<dynamic>)
          .map((e) => BBSPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['encrypted_email'] as String,
    );

Map<String, dynamic> _$FduholeProfileToJson(FduholeProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'favored_discussion': instance.favored_discussion,
      'encrypted_email': instance.encrypted_email,
    };
