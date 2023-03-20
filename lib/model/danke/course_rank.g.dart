// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_rank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rank _$RankFromJson(Map<String, dynamic> json) => Rank(
      json['overall'] as int?,
      json['content'] as int?,
      json['workload'] as int?,
      json['assessment'] as int?,
    );

Map<String, dynamic> _$RankToJson(Rank instance) => <String, dynamic>{
      'overall': instance.overall,
      'content': instance.content,
      'workload': instance.workload,
      'assessment': instance.assessment,
    };
