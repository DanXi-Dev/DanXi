// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      json['subId'] as int?,
      json['teachers'] as String?,
      json['maxStudent'] as int?,
      json['year'] as int?,
      json['semester'] as int?,
      (json['rating'] as num?)?.toDouble(),
      (json['reviewList'] as List<dynamic>?)
          ?.map((e) => CourseReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'subId': instance.subId,
      'teachers': instance.teachers,
      'maxStudent': instance.maxStudent,
      'year': instance.year,
      'semester': instance.semester,
      'rating': instance.rating,
      'reviewList': instance.reviewList,
    };
