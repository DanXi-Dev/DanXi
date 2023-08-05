// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      json['course_id'] as int?,
      json['course_name'] as String?,
      json['course_code'] as String?,
      json['code_id'] as String?,
      (json['credit'] as num?)?.toDouble(),
      json['department'] as String?,
      json['teachers'] as String?,
      json['max_student'] as int?,
      json['week_hour'] as int?,
      json['year'] as String?,
      json['semester'] as int?,
      (json['review_list'] as List<dynamic>?)
          ?.map((e) => CourseReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'course_id': instance.course_id,
      'course_name': instance.course_name,
      'course_code': instance.course_code,
      'code_id': instance.code_id,
      'credit': instance.credit,
      'department': instance.department,
      'teachers': instance.teachers,
      'max_student': instance.max_student,
      'week_hour': instance.week_hour,
      'year': instance.year,
      'semester': instance.semester,
      'review_list': instance.review_list,
    };
