import '../response/bmob_handled.dart';

import 'bmob_object.dart';
import '../bmob_dio.dart';
import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../response/bmob_registered.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bmob.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_user.g.dart';

@JsonSerializable()
class BmobUser extends BmobObject {
  String username;
  String password;
  String email;
  bool emailVerified;
  String mobilePhoneNumber;
  bool mobilePhoneNumberVerified;
  String sessionToken;

  BmobUser();

  //此处与类名一致，由指令自动生成代码
  factory BmobUser.fromJson(Map<String, dynamic> json) =>
      _$BmobUserFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobUserToJson(this);

  ///用户账号密码注册
  Future<BmobRegistered> register() async {
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();
    //去除由服务器生成的字段值
    map.remove("objectId");
    map.remove("createdAt");
    map.remove("updatedAt");
    map.remove("sessionToken");
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    //Map转String
    String params = json.encode(data);
    //发送请求
    Map responseData =
        await BmobDio.getInstance().post(Bmob.BMOB_API_USERS, data: params);
    BmobRegistered bmobRegistered = BmobRegistered.fromJson(responseData);
    BmobDio.getInstance().setSessionToken(bmobRegistered.sessionToken);
    return bmobRegistered;
  }

  ///账号密码登录
  Future<BmobUser> login() async {
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();
    //去除由服务器生成的字段值
    map.remove("objectId");
    map.remove("createdAt");
    map.remove("updatedAt");
    map.remove("sessionToken");
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    //Map转String
    //发送请求
    Map result = await BmobDio.getInstance()
        .get(Bmob.BMOB_API_LOGIN + getUrlParams(data));
    BmobUser bmobUser = BmobUser.fromJson(result);
    // obtain shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
//    prefs.setString("user", result.toString());
    prefs.setString("user", json.encode(bmobUser));

    BmobDio.getInstance().setSessionToken(bmobUser.sessionToken);
    return bmobUser;
  }

  ///手机短信验证码登录
  Future<BmobUser> loginBySms(String smsCode) async {
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();
    data["smsCode"] = smsCode;
    //去除由服务器生成的字段值
    map.remove("objectId");
    map.remove("createdAt");
    map.remove("updatedAt");
    map.remove("sessionToken");
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    //Map转String
    //发送请求
    Map result = await BmobDio.getInstance()
        .post(Bmob.BMOB_API_USERS, data: getParamsJsonFromParamsMap(data));
    BmobUser bmobUser = BmobUser.fromJson(result);
    BmobDio.getInstance().setSessionToken(bmobUser.sessionToken);
    return bmobUser;
  }

  ///发送邮箱重置密码的请求
  Future<BmobHandled> requestPasswordResetByEmail() async {
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();
    //去除由服务器生成的字段值
    map.remove("objectId");
    map.remove("createdAt");
    map.remove("updatedAt");
    map.remove("sessionToken");
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    //Map转String
    //发送请求
    Map result = await BmobDio.getInstance().post(
        Bmob.BMOB_API_REQUEST_PASSWORD_RESET,
        data: getParamsJsonFromParamsMap(data));
    BmobHandled bmobHandled = BmobHandled.fromJson(result);
    return bmobHandled;
  }

  ///短信重置密码
  Future<BmobHandled> requestPasswordResetBySmsCode(String smsCode) async {
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();
    //去除由服务器生成的字段值
    map.remove("objectId");
    map.remove("createdAt");
    map.remove("updatedAt");
    map.remove("sessionToken");
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    //Map转String
    //发送请求
    Map result = await BmobDio.getInstance().put(
        Bmob.BMOB_API_REQUEST_PASSWORD_BY_SMS_CODE +
            Bmob.BMOB_API_SLASH +
            smsCode,
        data: getParamsJsonFromParamsMap(data));
    BmobHandled bmobHandled = BmobHandled.fromJson(result);
    return bmobHandled;
  }

  ///发送验证邮箱
  static Future<BmobHandled> requestEmailVerify(String email) async {
    Map<String, dynamic> data = new Map();

    data["email"] = email;

    //Map转String
    //发送请求
    Map result = await BmobDio.getInstance()
        .post(Bmob.BMOB_API_REQUEST_REQUEST_EMAIL_VERIFY, data: data);
    BmobHandled bmobHandled = BmobHandled.fromJson(result);
    return bmobHandled;
  }

  ///旧密码重置密码
  Future<BmobHandled> updateUserPassword(
      String oldPassword, String newPassword) async {
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();

    data["oldPassword"] = oldPassword;
    data["newPassword"] = newPassword;
    //去除由服务器生成的字段值
    map.remove("objectId");
    map.remove("createdAt");
    map.remove("updatedAt");
    map.remove("sessionToken");
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    //Map转String
    //发送请求
    Map result = await BmobDio.getInstance().put(
        Bmob.BMOB_API_REQUEST_UPDATE_USER_PASSWORD + objectId,
        data: getParamsJsonFromParamsMap(data));
    BmobHandled bmobHandled = BmobHandled.fromJson(result);
    return bmobHandled;
  }

  ///获取在url中的请求参数
  String getUrlParams(Map data) {
    String urlParams = "";
    int index = 0;
    data.forEach((key, value) {
      if (index == 0) {
        urlParams = '$urlParams?$key=$value';
      } else {
        urlParams = '$urlParams&$key=$value';
      }
      index++;
    });
    return urlParams;
  }

  @override
  Map getParams() {
    // TODO: implement getJson
    Map<String, dynamic> map = toJson();
    Map<String, dynamic> data = new Map();
    //去除空值
    map.forEach((key, value) {
      if (value != null) {
        data[key] = value;
      }
    });
    return map;
  }
}
