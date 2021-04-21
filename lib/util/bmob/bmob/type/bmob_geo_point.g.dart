// GENERATED CODE - DO NOT MODIFY BY HAND

part of bmobgeopoint;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobGeoPoint _$BmobGeoPointFromJson(Map<String, dynamic> json) {
  return BmobGeoPoint()
    ..latitude = (json['latitude'] as num)?.toDouble()
    ..longitude = (json['longitude'] as num)?.toDouble()
    ..type = json['__type'] as String;
}

Map<String, dynamic> _$BmobGeoPointToJson(BmobGeoPoint instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      '__type': instance.type
    };
