// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_grade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseGrade _$CourseGradeFromJson(Map<String, dynamic> json) => CourseGrade(
      json['overall'] as int?,
      json['content'] as int?,
      json['workload'] as int?,
      json['assessment'] as int?,
    );

Map<String, dynamic> _$CourseGradeToJson(CourseGrade instance) =>
    <String, dynamic>{
      'overall': instance._overall,
      'content': instance._content,
      'workload': instance._workload,
      'assessment': instance._assessment,
    };
