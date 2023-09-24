// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseReview _$CourseReviewFromJson(Map<String, dynamic> json) => CourseReview(
      json['id'] as int?,
      json['reviewer_id'] as int?,
      json['title'] as String?,
      json['content'] as String?,
      json['timeCreated'] as String?,
      json['timeUpdated'] as String?,
      json['rank'] == null
          ? null
          : CourseGrade.fromJson(json['rank'] as Map<String, dynamic>),
      json['vote'] as int?,
      json['is_me'] as bool?,
      json['modified'] as int?,
      json['deleted'] as bool?,
      json['extra'] == null
          ? null
          : ReviewExtra.fromJson(json['extra'] as Map<String, dynamic>),
    )
      ..remark = json['remark'] as int?
      ..course = json['course'] == null
          ? null
          : Course.fromJson(json['course'] as Map<String, dynamic>);

Map<String, dynamic> _$CourseReviewToJson(CourseReview instance) =>
    <String, dynamic>{
      'id': instance.reviewId,
      'reviewer_id': instance.reviewerId,
      'title': instance.title,
      'content': instance.content,
      'timeCreated': instance.timeCreated,
      'timeUpdated': instance.timeUpdated,
      'rank': instance.rank,
      'remark': instance.remark,
      'vote': instance.vote,
      'is_me': instance.isMe,
      'modified': instance.modified,
      'deleted': instance.deleted,
      'extra': instance.extra,
      'course': instance.course,
    };
