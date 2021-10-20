// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'division.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTDivision _$OTDivisionFromJson(Map<String, dynamic> json) {
  return OTDivision(
    json['division_id'] as int?,
    json['name'] as String?,
    json['description'] as String?,
    (json['pinned'] as List<dynamic>?)
        ?.map((e) => OTHole.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$OTDivisionToJson(OTDivision instance) =>
    <String, dynamic>{
      'division_id': instance.division_id,
      'name': instance.name,
      'description': instance.description,
      'pinned': instance.pinned,
    };
