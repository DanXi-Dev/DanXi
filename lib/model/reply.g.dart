// GENERATED CODE - DO NOT MODIFY BY HAND

// @dart=2.9

part of 'reply.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reply _$ReplyFromJson(Map<String, dynamic> json) {
  return Reply(
    json['id'] as int,
    json['content'] as String,
    json['username'] as String,
    json['reply_to'] as int,
    json['date_created'] as String,
    json['discussion'] as int,
    json['is_me'] as bool,
  );
}

Map<String, dynamic> _$ReplyToJson(Reply instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'username': instance.username,
      'reply_to': instance.reply_to,
      'date_created': instance.date_created,
      'discussion': instance.discussion,
      'is_me': instance.is_me,
    };
