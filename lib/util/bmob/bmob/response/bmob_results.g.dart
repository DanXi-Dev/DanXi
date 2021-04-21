// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobResults _$BmobResultsFromJson(Map<String, dynamic> json) {
  return BmobResults()
    ..results = json['results'] as List
    ..count = json['count'] as int;
}

Map<String, dynamic> _$BmobResultsToJson(BmobResults instance) =>
    <String, dynamic>{'results': instance.results, 'count': instance.count};
