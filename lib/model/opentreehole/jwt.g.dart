// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JWToken _$JWTokenFromJson(Map<String, dynamic> json) => JWToken(
      json['access'] as String?,
      json['refresh'] as String?,
    );

Map<String, dynamic> _$JWTokenToJson(JWToken instance) => <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
    };
