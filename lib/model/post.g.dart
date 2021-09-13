// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BBSPost _$BBSPostFromJson(Map<String, dynamic> json) => BBSPost(
      json['id'] as int,
      Reply.fromJson(json['first_post'] as Map<String, dynamic>),
      json['count'] as int,
      (json['tag'] as List<dynamic>)
          .map((e) => PostTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      Map<String, String>.from(json['mapping'] as Map),
      json['is_folded'] as bool,
      json['date_created'] as String,
      json['date_updated'] as String,
      (json['posts'] as List<dynamic>)
          .map((e) => Reply.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..last_post = Reply.fromJson(json['last_post'] as Map<String, dynamic>);

Map<String, dynamic> _$BBSPostToJson(BBSPost instance) => <String, dynamic>{
      'id': instance.id,
      'first_post': instance.first_post,
      'count': instance.count,
      'tag': instance.tag,
      'mapping': instance.mapping,
      'date_created': instance.date_created,
      'date_updated': instance.date_updated,
      'is_folded': instance.is_folded,
      'last_post': instance.last_post,
      'posts': instance.posts,
    };
