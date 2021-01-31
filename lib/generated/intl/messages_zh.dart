// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static m0(name) => "欢迎你，${name}!";

  final messages = _notInlinedMessages(_notInlinedMessages);

  static _notInlinedMessages(_) => <String, Function>{
        "app_name": MessageLookupByLibrary.simpleMessage("旦兮 α"),
        "cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "change_account": MessageLookupByLibrary.simpleMessage("切换账号"),
        "choose_area": MessageLookupByLibrary.simpleMessage("请选择校区~"),
        "current_connection": MessageLookupByLibrary.simpleMessage("当前连接"),
        "current_connection_failed":
            MessageLookupByLibrary.simpleMessage("获取 WiFi 名称失败，检查位置服务开启情况"),
        "current_connection_no_wifi":
            MessageLookupByLibrary.simpleMessage("没有链接到 WiFi"),
        "dashboard": MessageLookupByLibrary.simpleMessage("仪表盘"),
        "dining_hall_crowdedness":
            MessageLookupByLibrary.simpleMessage("食堂排队消费状况"),
        "ecard_balance": MessageLookupByLibrary.simpleMessage("饭卡余额"),
        "ecard_balance_log": MessageLookupByLibrary.simpleMessage("饭卡消费记录"),
        "failed": MessageLookupByLibrary.simpleMessage("获取失败，点击重试"),
        "fatal_error": MessageLookupByLibrary.simpleMessage("错误"),
        "forum": MessageLookupByLibrary.simpleMessage("旦唧"),
        "fudan_daily": MessageLookupByLibrary.simpleMessage("平安复旦"),
        "fudan_daily_tick": MessageLookupByLibrary.simpleMessage("点击上报"),
        "fudan_daily_ticked":
            MessageLookupByLibrary.simpleMessage("你今天已经上报过了哦！"),
        "fudan_qr_code": MessageLookupByLibrary.simpleMessage("复活码"),
        "i_see": MessageLookupByLibrary.simpleMessage("我知道了"),
        "last_15_days": MessageLookupByLibrary.simpleMessage("过去 15 天"),
        "last_30_days": MessageLookupByLibrary.simpleMessage("过去 30 天"),
        "last_7_days": MessageLookupByLibrary.simpleMessage("过去 7 天"),
        "loading": MessageLookupByLibrary.simpleMessage("获取中..."),
        "loading_qr_code": MessageLookupByLibrary.simpleMessage(
            "加载复活码中...\n(由于复旦校园服务器较差，可能需要5~10秒)"),
        "login": MessageLookupByLibrary.simpleMessage("登录"),
        "login_uis": MessageLookupByLibrary.simpleMessage("登录 Fudan UIS"),
        "login_uis_pwd": MessageLookupByLibrary.simpleMessage("UIS 密码"),
        "login_uis_uid": MessageLookupByLibrary.simpleMessage("UIS 账号"),
        "logining": MessageLookupByLibrary.simpleMessage("尝试登录中..."),
        "out_of_dining_time":
            MessageLookupByLibrary.simpleMessage("现在不是食堂用餐时间哦~"),
        "tick_failed": MessageLookupByLibrary.simpleMessage("打卡失败，请检查网络连接~"),
        "tick_issue_1": MessageLookupByLibrary.simpleMessage(
            "打卡失败，旦兮无法获取上次打卡记录。\n出现此错误，很可能是由于您第一次使用 旦兮，且昨天忘记打卡所致。\n您需要使用小程序手动完成第一次打卡，从下一次打卡开始，旦兮 即可妥善处理此情况。"),
        "ticking": MessageLookupByLibrary.simpleMessage("打卡中..."),
        "welcome": m0
      };
}
