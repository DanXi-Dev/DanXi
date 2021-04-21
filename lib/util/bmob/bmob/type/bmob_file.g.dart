// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobFile _$BmobFileFromJson(Map<String, dynamic> json) {
  return BmobFile()
    ..type = json['__type'] as String
    ..cdn = json['cdn'] as String
    ..url = json['url'] as String
    ..filename = json['filename'] as String;
}

Map<String, dynamic> _$BmobFileToJson(BmobFile instance) => <String, dynamic>{
      '__type': instance.type,
      'cdn': instance.cdn,
      'url': instance.url,
      'filename': instance.filename
    };
