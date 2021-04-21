// GENERATED CODE - DO NOT MODIFY BY HAND

part of message;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) {
  return Message()
    ..name = json['name'] as String
    ..args = (json['args'] as List)?.map((e) => e as String)?.toList();
}

Map<String, dynamic> _$MessageToJson(Message instance) =>
    <String, dynamic>{'name': instance.name, 'args': instance.args};
