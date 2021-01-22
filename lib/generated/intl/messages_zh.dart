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
        "current_connection": MessageLookupByLibrary.simpleMessage("当前连接"),
        "current_connection_failed":
            MessageLookupByLibrary.simpleMessage("获取WiFi名称失败，检查位置服务开启情况"),
        "dining_hall_crowdedness":
            MessageLookupByLibrary.simpleMessage("食堂排队消费状况"),
        "ecard_balance": MessageLookupByLibrary.simpleMessage("饭卡余额"),
        "fudan_daily": MessageLookupByLibrary.simpleMessage("平安复旦"),
        "fudan_daily_tick": MessageLookupByLibrary.simpleMessage("点击上报"),
        "fudan_daily_ticked":
            MessageLookupByLibrary.simpleMessage("你今天已经上报过了哦！"),
        "fudan_qr_code": MessageLookupByLibrary.simpleMessage("复活码"),
        "loading": MessageLookupByLibrary.simpleMessage("获取中..."),
        "welcome": m0
      };
}
