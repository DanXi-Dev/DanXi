// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTUserConfig _$OTUserConfigFromJson(Map<String, dynamic> json) => OTUserConfig(
      (json['notify'] as List<dynamic>?)?.map((e) => e as String).toList(),
      json['show_folded'] as String?,
    );

Map<String, dynamic> _$OTUserConfigToJson(OTUserConfig instance) =>
    <String, dynamic>{
      'notify': instance.notify,
      'show_folded': instance.show_folded,
    };
