// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseSearchResults _$CourseSearchResultsFromJson(Map<String, dynamic> json) =>
    CourseSearchResults(
      json['page'] as int?,
      json['page_size'] as int?,
      json['extra'] as String?,
      (json['items'] as List<dynamic>?)
          ?.map((e) => CourseGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CourseSearchResultsToJson(
        CourseSearchResults instance) =>
    <String, dynamic>{
      'page': instance.page,
      'page_size': instance.pageSize,
      'extra': instance.extra,
      'items': instance.items,
    };
