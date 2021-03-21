// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BBSPost _$BBSPostFromJson(Map<String, dynamic> json) {
  return BBSPost(
    json['author'] as String,
    json['content'] as String,
    json['replyPost'] as String,
    json['replyTo'] as String,
  )
    ..createdAt = json['createdAt'] as String
    ..updatedAt = json['updatedAt'] as String
    ..objectId = json['objectId'] as String
    ..ACL = json['ACL'] as Map<String, dynamic>;
}

Map<String, dynamic> _$BBSPostToJson(BBSPost instance) => <String, dynamic>{
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'objectId': instance.objectId,
      'ACL': instance.ACL,
      'author': instance.author,
      'content': instance.content,
      'replyPost': instance.replyPost,
      'replyTo': instance.replyTo,
    };
