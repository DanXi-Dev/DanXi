// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseReview _$CourseReviewFromJson(Map<String, dynamic> json) => CourseReview(
      json['review_id'] as int?,
      json['reviewer_id'] as int?,
      json['title'] as String?,
      json['content'] as String?,
      json['timeCreated'] as String?,
      json['timeUpdated'] as String?,
      json['course_grade'] == null
          ? null
          : Grade.fromJson(json['course_grade'] as Map<String, dynamic>),
      json['like'] as int?,
      json['liked'] as int?,
      json['is_me'] as bool?,
      json['modified'] as int?,
      json['deleted'] as bool?,
      json['review_extra'] == null
          ? null
          : ReviewExtra.fromJson(json['review_extra'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseReviewToJson(CourseReview instance) =>
    <String, dynamic>{
      'review_id': instance.review_id,
      'reviewer_id': instance.reviewer_id,
      'title': instance.title,
      'content': instance.content,
      'timeCreated': instance.timeCreated,
      'timeUpdated': instance.timeUpdated,
      'course_grade': instance.course_grade,
      'like': instance.like,
      'liked': instance.liked,
      'is_me': instance.is_me,
      'modified': instance.modified,
      'deleted': instance.deleted,
      'review_extra': instance.review_extra,
    };
