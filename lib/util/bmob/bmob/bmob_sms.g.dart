// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmob_sms.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobSms _$BmobSmsFromJson(Map<String, dynamic> json) {
  return BmobSms()
    ..mobilePhoneNumber = json['mobilePhoneNumber'] as String
    ..template = json['template'] as String;
}

Map<String, dynamic> _$BmobSmsToJson(BmobSms instance) => <String, dynamic>{
      'mobilePhoneNumber': instance.mobilePhoneNumber,
      'template': instance.template
    };
