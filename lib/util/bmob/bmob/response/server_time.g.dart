// GENERATED CODE - DO NOT MODIFY BY HAND

part of servertime;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerTime _$ServerTimeFromJson(Map<String, dynamic> json) {
  return ServerTime()
    ..timestamp = json['timestamp'] as int
    ..datetime = json['datetime'] as String;
}

Map<String, dynamic> _$ServerTimeToJson(ServerTime instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'datetime': instance.datetime
    };
