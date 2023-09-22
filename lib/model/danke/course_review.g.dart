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
      json['courseGrade'] == null
          ? null
          : CourseGrade.fromJson(json['courseGrade'] as Map<String, dynamic>),
      json['like'] as int?,
      json['liked'] as int?,
      json['isMe'] as bool?,
      json['modified'] as int?,
      json['deleted'] as bool?,
      json['reviewExtra'] == null
          ? null
          : ReviewExtra.fromJson(json['reviewExtra'] as Map<String, dynamic>),
    )..course = json['course'] == null
        ? null
        : Course.fromJson(json['course'] as Map<String, dynamic>);

Map<String, dynamic> _$CourseReviewToJson(CourseReview instance) =>
    <String, dynamic>{
      'review_id': instance.reviewId,
      'reviewer_id': instance.reviewerId,
      'title': instance.title,
      'content': instance.content,
      'timeCreated': instance.timeCreated,
      'timeUpdated': instance.timeUpdated,
      'courseGrade': instance.courseGrade,
      'like': instance.like,
      'liked': instance.liked,
      'isMe': instance.isMe,
      'modified': instance.modified,
      'deleted': instance.deleted,
      'reviewExtra': instance.reviewExtra,
      'course': instance.course,
    };
