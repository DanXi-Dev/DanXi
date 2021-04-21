// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_relation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobRelation _$BmobRelationFromJson(Map<String, dynamic> json) {
  return BmobRelation()
    ..op = json['__op'] as String
    ..objects = (json['objects'] as List)
        ?.map((e) => e as Map<String, dynamic>)
        ?.toList();
}

Map<String, dynamic> _$BmobRelationToJson(BmobRelation instance) =>
    <String, dynamic>{'__op': instance.op, 'objects': instance.objects};
