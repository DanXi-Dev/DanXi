// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobError _$BmobErrorFromJson(Map<String, dynamic> json) {
  return BmobError(json['code'] as int, json['error'] as String);
}

Map<String, dynamic> _$BmobErrorToJson(BmobError instance) =>
    <String, dynamic>{'code': instance.code, 'error': instance.error};
