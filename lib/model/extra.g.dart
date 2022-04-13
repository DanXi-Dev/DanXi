// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extra.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Extra _$ExtraFromJson(Map<String, dynamic> json) => Extra(
      json['timetable'] == null
          ? null
          : TimeTableExtra.fromJson(json['timetable'] as Map<String, dynamic>),
      json['userAgent'] as String?,
      (json['stopWords'] as List<dynamic>?)?.map((e) => e as String?).toList(),
      (json['banners'] as List<dynamic>?)
          ?.map((e) => e == null
              ? null
              : BannerExtra.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExtraToJson(Extra instance) => <String, dynamic>{
      'timetable': instance.timetable,
      'userAgent': instance.userAgent,
      'stopWords': instance.stopWords,
      'banners': instance.banners,
    };

TimeTableExtra _$TimeTableExtraFromJson(Map<String, dynamic> json) =>
    TimeTableExtra(
      (json['fdu_ug'] as List<dynamic>?)
          ?.map(
              (e) => TimeTableStartTimeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TimeTableExtraToJson(TimeTableExtra instance) =>
    <String, dynamic>{
      'fdu_ug': instance.fdu_ug,
    };

TimeTableStartTimeItem _$TimeTableStartTimeItemFromJson(
        Map<String, dynamic> json) =>
    TimeTableStartTimeItem(
      json['id'] as String?,
      json['startDate'] as String?,
    );

Map<String, dynamic> _$TimeTableStartTimeItemToJson(
        TimeTableStartTimeItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startDate': instance.startDate,
    };

BannerExtra _$BannerExtraFromJson(Map<String, dynamic> json) => BannerExtra(
      json['title'] as String,
      json['actionName'] as String,
      json['action'] as String,
    );

Map<String, dynamic> _$BannerExtraToJson(BannerExtra instance) =>
    <String, dynamic>{
      'title': instance.title,
      'actionName': instance.actionName,
      'action': instance.action,
    };
