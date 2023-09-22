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
      json['weekHour'] as int?,
      (json['credit'] as num?)?.toDouble(),
      (json['course_list'] as List<dynamic>?)
          ?.map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseGroupToJson(CourseGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'department': instance.department,
      'weekHour': instance.weekHour,
      'credit': instance.credit,
      'course_list': instance.courseList,
    };
