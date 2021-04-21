// GENERATED CODE - DO NOT MODIFY BY HAND

part of change;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Change _$ChangeFromJson(Map<String, dynamic> json) {
  return Change()
    ..appKey = json['appKey'] as String
    ..tableName = json['tableName'] as String
    ..objectId = json['objectId'] as String
    ..action = json['action'] as String
    ..data = json['data'] as Map<String, dynamic>;
}

Map<String, dynamic> _$ChangeToJson(Change instance) => <String, dynamic>{
      'appKey': instance.appKey,
      'tableName': instance.tableName,
      'objectId': instance.objectId,
      'action': instance.action,
      'data': instance.data
    };
