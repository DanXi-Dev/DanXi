// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      id: json['id'] as int?,
      teachers: json['teachers'] as String?,
      maxStudent: json['max_student'] as int?,
      year: json['year'] as int?,
      semester: json['semester'] as int?,
      credit: (json['credit'] as num?)?.toDouble(),
      reviewList: (json['review_list'] as List<dynamic>?)
          ?.map((e) => CourseReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..name = json['name'] as String?
      ..code = json['code'] as String?
      ..codeId = json['code_id'] as String?
      ..department = json['department'] as String?
      ..weekHour = json['week_hour'] as int?
      ..courseGroupId = json['coursegroup_id'] as int?;

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'code_id': instance.codeId,
      'credit': instance.credit,
      'department': instance.department,
      'teachers': instance.teachers,
      'max_student': instance.maxStudent,
      'week_hour': instance.weekHour,
      'year': instance.year,
      'semester': instance.semester,
      'coursegroup_id': instance.courseGroupId,
      'review_list': instance.reviewList,
    };
