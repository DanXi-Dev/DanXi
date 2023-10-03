// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseGroup _$CourseGroupFromJson(Map<String, dynamic> json) => CourseGroup(
      json['id'] as int?,
      json['name'] as String?,
      json['code'] as String?,
      json['department'] as String?,
      json['week_hour'] as int?,
      (json['credits'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      (json['course_list'] as List<dynamic>?)
          ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..courseCount = json['course_count'] as int?
      ..reviewCount = json['review_count'] as int?;

Map<String, dynamic> _$CourseGroupToJson(CourseGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'department': instance.department,
      'week_hour': instance.weekHour,
      'credits': instance.credits,
      'course_list': instance.courseList,
      'course_count': instance.courseCount,
      'review_count': instance.reviewCount,
    };
