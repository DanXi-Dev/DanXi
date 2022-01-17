import 'dart:async';

import 'package:json_annotation/json_annotation.dart';

import 'bmob.dart';
import 'bmob_dio.dart';
import 'response/bmob_handled.dart';
import 'response/bmob_sent.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_sms.g.dart';

@JsonSerializable()
class BmobSms {
  String? mobilePhoneNumber;
  String? template;

  BmobSms();

  ///查询单条数据
  Future<BmobSent> sendSms() async {
    Map responseData = await (BmobDio.getInstance()!
            .post(Bmob.BMOB_API_SEND_SMS_CODE, data: getParams())
        as FutureOr<Map<dynamic, dynamic>>);
    BmobSent sent = BmobSent.fromJson(responseData as Map<String, dynamic>);
    return sent;
  }

  ///查询多条数据
  Future<BmobHandled> verifySmsCode(smsCode) async {
    Map params = getParams();
    params.remove("template");
    Map responseData = await (BmobDio.getInstance()!
            .post(Bmob.BMOB_API_VERIFY_SMS_CODE + smsCode, data: params)
        as FutureOr<Map<dynamic, dynamic>>);
    BmobHandled bmobHandled =
        BmobHandled.fromJson(responseData as Map<String, dynamic>);
    return bmobHandled;
  }

  //此处与类名一致，由指令自动生成代码
  factory BmobSms.fromJson(Map<String, dynamic> json) =>
      _$BmobSmsFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobSmsToJson(this);

  ///获取请求参数
  Map getParams() {
    Map map = toJson();
    Map params = toJson();
    map.forEach((k, v) {
      if (v == null) {
        params.remove(k);
      }
    });
    return params;
  }
}
