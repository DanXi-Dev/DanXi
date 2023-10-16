// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseReview _$CourseReviewFromJson(Map<String, dynamic> json) => CourseReview(
      reviewId: json['id'] as int?,
      reviewerId: json['reviewer_id'] as int?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      timeCreated: json['timeCreated'] as String?,
      timeUpdated: json['timeUpdated'] as String?,
      rank: json['rank'] == null
          ? null
          : CourseGrade.fromJson(json['rank'] as Map<String, dynamic>),
      vote: json['vote'] as int?,
      isMe: json['is_me'] as bool?,
      modified: json['modified'] as int?,
      deleted: json['deleted'] as bool?,
      extra: json['extra'] == null
          ? null
          : ReviewExtra.fromJson(json['extra'] as Map<String, dynamic>),
    )
      ..remark = json['remark'] as int?
      ..course = json['course'] == null
          ? null
          : Course.fromJson(json['course'] as Map<String, dynamic>)
      ..groupId = json['group_id'] as int?;

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
      'group_id': instance.groupId,
    };
