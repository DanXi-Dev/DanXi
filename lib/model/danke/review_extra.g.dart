// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_extra.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewExtra _$ReviewExtraFromJson(Map<String, dynamic> json) => ReviewExtra(
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => ReviewerAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ReviewExtraToJson(ReviewExtra instance) =>
    <String, dynamic>{
      'achievements': instance.achievements,
    };
