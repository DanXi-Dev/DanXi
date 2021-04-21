// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_query.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobQuery<T> _$BmobQueryFromJson<T>(Map<String, dynamic> json) {
  return BmobQuery<T>()
    ..include = json['include'] as String
    ..limit = json['limit'] as int
    ..skip = json['skip'] as int
    ..order = json['order'] as String
    ..count = json['count'] as int
    ..where = json['where'] as Map<String, dynamic>
    ..having = json['having'] as Map<String, dynamic>
    ..groupby = json['groupby'] as String
    ..sum = json['sum'] as String
    ..average = json['average'] as String
    ..max = json['max'] as String
    ..min = json['min'] as String
    ..groupcount = json['groupcount'] as bool;
}

Map<String, dynamic> _$BmobQueryToJson<T>(BmobQuery<T> instance) =>
    <String, dynamic>{
      'include': instance.include,
      'limit': instance.limit,
      'skip': instance.skip,
      'order': instance.order,
      'count': instance.count,
      'where': instance.where,
      'having': instance.having,
      'groupby': instance.groupby,
      'sum': instance.sum,
      'average': instance.average,
      'max': instance.max,
      'min': instance.min,
      'groupcount': instance.groupcount
    };
