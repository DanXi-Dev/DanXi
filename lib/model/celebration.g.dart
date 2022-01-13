// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'celebration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Celebration _$CelebrationFromJson(Map<String, dynamic> json) => Celebration(
      json['type'] as int,
      json['date'] as String,
      (json['celebrationWords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CelebrationToJson(Celebration instance) =>
    <String, dynamic>{
      'type': instance.type,
      'date': instance.date,
      'celebrationWords': instance.celebrationWords,
    };
