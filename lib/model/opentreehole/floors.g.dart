// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floors.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTFloors _$OTFloorsFromJson(Map<String, dynamic> json) {
  return OTFloors(
    json['first_floor'] == null
        ? null
        : OTFloor.fromJson(json['first_floor'] as Map<String, dynamic>),
    json['last_floor'] == null
        ? null
        : OTFloor.fromJson(json['last_floor'] as Map<String, dynamic>),
    (json['prefetch'] as List<dynamic>?)
        ?.map((e) => OTFloor.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$OTFloorsToJson(OTFloors instance) => <String, dynamic>{
      'first_floor': instance.first_floor,
      'last_floor': instance.last_floor,
      'prefetch': instance.prefetch,
    };
