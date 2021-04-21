// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_registered.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobRegistered _$BmobRegisteredFromJson(Map<String, dynamic> json) {
  return BmobRegistered()
    ..createdAt = json['createdAt'] as String
    ..objectId = json['objectId'] as String
    ..sessionToken = json['sessionToken'] as String;
}

Map<String, dynamic> _$BmobRegisteredToJson(BmobRegistered instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'objectId': instance.objectId,
      'sessionToken': instance.sessionToken
    };
