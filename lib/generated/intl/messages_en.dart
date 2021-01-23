// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static m0(name) => "Welcome, ${name}!";

  final messages = _notInlinedMessages(_notInlinedMessages);

  static _notInlinedMessages(_) => <String, Function>{
        "app_name": MessageLookupByLibrary.simpleMessage("DanXi"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "change_account":
            MessageLookupByLibrary.simpleMessage("Change account"),
        "choose_area":
            MessageLookupByLibrary.simpleMessage("Choose your location"),
        "current_connection":
            MessageLookupByLibrary.simpleMessage("Connectivity"),
        "current_connection_failed": MessageLookupByLibrary.simpleMessage(
            "Failed to obtain WiFi information"),
        "current_connection_no_wifi":
            MessageLookupByLibrary.simpleMessage("Not connect to any WiFi"),
        "dining_hall_crowdedness":
            MessageLookupByLibrary.simpleMessage("Dining hall crowdedness"),
        "ecard_balance": MessageLookupByLibrary.simpleMessage("Ecard balance"),
        "ecard_balance_log":
            MessageLookupByLibrary.simpleMessage("Ecard balance detail"),
        "failed":
            MessageLookupByLibrary.simpleMessage("Load failed, click to retry"),
        "fudan_daily": MessageLookupByLibrary.simpleMessage("Fudan daily"),
        "fudan_daily_tick":
            MessageLookupByLibrary.simpleMessage("Click to report"),
        "fudan_daily_ticked":
            MessageLookupByLibrary.simpleMessage("You have reported today!"),
        "fudan_qr_code": MessageLookupByLibrary.simpleMessage("ECard Code"),
        "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "login_uis": MessageLookupByLibrary.simpleMessage("Login Fudan UIS"),
        "login_uis_pwd": MessageLookupByLibrary.simpleMessage("UIS Password"),
        "login_uis_uid": MessageLookupByLibrary.simpleMessage("UIS ID"),
        "logining": MessageLookupByLibrary.simpleMessage("Logging in..."),
        "out_of_dining_time": MessageLookupByLibrary.simpleMessage(
            "It\'s not time for a meal at the moment!"),
        "tick_failed": MessageLookupByLibrary.simpleMessage(
            "Report failed. Check your connection."),
        "ticking": MessageLookupByLibrary.simpleMessage("Reporting..."),
        "welcome": m0
      };
}
