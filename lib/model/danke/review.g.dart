// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      json['id'] as int?,
      json['reviewerId'] as int?,
      json['title'] as String?,
      json['content'] as String?,
      json['timeCreated'] as String?,
      json['timeUpdated'] as String?,
      json['rank'] == null
          ? null
          : Rank.fromJson(json['rank'] as Map<String, dynamic>),
      json['remark'] as int?,
      json['vote'] as int?,
      json['isMe'] as bool?,
      json['extra'] == null
          ? null
          : ReviewExtra.fromJson(json['extra'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'reviewerId': instance.reviewerId,
      'title': instance.title,
      'content': instance.content,
      'timeCreated': instance.timeCreated,
      'timeUpdated': instance.timeUpdated,
      'rank': instance.rank,
      'remark': instance.remark,
      'vote': instance.vote,
      'isMe': instance.isMe,
      'extra': instance.extra,
    };
