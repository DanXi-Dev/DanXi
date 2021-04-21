// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_pointer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobPointer _$BmobPointerFromJson(Map<String, dynamic> json) {
  return BmobPointer()
    ..type = json['__type'] as String
    ..className = json['className'] as String
    ..objectId = json['objectId'] as String;
}

Map<String, dynamic> _$BmobPointerToJson(BmobPointer instance) =>
    <String, dynamic>{
      '__type': instance.type,
      'className': instance.className,
      'objectId': instance.objectId
    };
