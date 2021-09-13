// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardCard _$DashboardCardFromJson(Map<String, dynamic> json) =>
    DashboardCard(
      json['internalString'] as String,
      json['title'] as String,
      json['link'] as String,
      json['enabled'] as bool,
    );

Map<String, dynamic> _$DashboardCardToJson(DashboardCard instance) =>
    <String, dynamic>{
      'internalString': instance.internalString,
      'title': instance.title,
      'link': instance.link,
      'enabled': instance.enabled,
    };
