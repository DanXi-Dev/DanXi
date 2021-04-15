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

  static m0(time) => "Automatic check-in in ${time} seconds. Tap to cancel.";

  static m1(mostCrowded, leastCrowded) => "[Most Crowded]${mostCrowded}餐厅 [Least Crowded]${leastCrowded}餐厅";

  static m2(name) => "Reply No.${name}";

  static m3(name) => "Welcome, ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "about" : MessageLookupByLibrary.simpleMessage("About This App"),
    "account" : MessageLookupByLibrary.simpleMessage("Account"),
    "and" : MessageLookupByLibrary.simpleMessage(" and "),
    "app_description" : MessageLookupByLibrary.simpleMessage("A miniature Fudan Integrated Service App, created by several Fudan undergraduate students with love. We hope it can facilitate your life~"),
    "app_description_title" : MessageLookupByLibrary.simpleMessage("Description"),
    "app_name" : MessageLookupByLibrary.simpleMessage("DanXi"),
    "author_descriptor" : MessageLookupByLibrary.simpleMessage("Passionate developers from\nEngineering @ Fudan University"),
    "authors" : MessageLookupByLibrary.simpleMessage("Developers"),
    "cancel" : MessageLookupByLibrary.simpleMessage("Cancel"),
    "change_account" : MessageLookupByLibrary.simpleMessage("Switch Account"),
    "choose_area" : MessageLookupByLibrary.simpleMessage("Select Campus"),
    "contact_us" : MessageLookupByLibrary.simpleMessage("Contact Us"),
    "cupertino" : MessageLookupByLibrary.simpleMessage("Cupertino"),
    "current_connection" : MessageLookupByLibrary.simpleMessage("Current Connection"),
    "current_connection_failed" : MessageLookupByLibrary.simpleMessage("Failed to obtain WLAN information, Precise Location permission required"),
    "current_connection_no_wifi" : MessageLookupByLibrary.simpleMessage("Not connected to WLAN"),
    "dashboard" : MessageLookupByLibrary.simpleMessage("Dashboard"),
    "default_campus" : MessageLookupByLibrary.simpleMessage("Current Campus"),
    "dev_image_url_1" : MessageLookupByLibrary.simpleMessage("assets/graphics/w568w.jpeg"),
    "dev_image_url_2" : MessageLookupByLibrary.simpleMessage("assets/graphics/kavinzhao.jpeg"),
    "dev_image_url_3" : MessageLookupByLibrary.simpleMessage("assets/graphics/kyln24.jpeg"),
    "dev_name_1" : MessageLookupByLibrary.simpleMessage("许冬\n[w568w]"),
    "dev_name_2" : MessageLookupByLibrary.simpleMessage("赵行健\n[kavinzhao]"),
    "dev_name_3" : MessageLookupByLibrary.simpleMessage("郭虹麟\n[KYLN24]"),
    "dev_page_1" : MessageLookupByLibrary.simpleMessage("https://github.com/w568w"),
    "dev_page_2" : MessageLookupByLibrary.simpleMessage("https://github.com/kavinzhao"),
    "dev_page_3" : MessageLookupByLibrary.simpleMessage("https://github.com/KYLN24"),
    "dining_hall_crowdedness" : MessageLookupByLibrary.simpleMessage("Canteen Popularity"),
    "ecard_balance" : MessageLookupByLibrary.simpleMessage("Card Balance"),
    "ecard_balance_log" : MessageLookupByLibrary.simpleMessage("Transactions"),
    "empty_classrooms" : MessageLookupByLibrary.simpleMessage("Empty Classrooms"),
    "failed" : MessageLookupByLibrary.simpleMessage("Unable to load content, tap to retry"),
    "fatal_error" : MessageLookupByLibrary.simpleMessage("Fatal Error"),
    "fenglin_campus" : MessageLookupByLibrary.simpleMessage("Fenglin"),
    "forum" : MessageLookupByLibrary.simpleMessage("The \"Hole\""),
    "forum_post_enter_content" : MessageLookupByLibrary.simpleMessage("Post"),
    "fudan_aao_notices" : MessageLookupByLibrary.simpleMessage("Academic Announcements"),
    "fudan_daily" : MessageLookupByLibrary.simpleMessage("Automatic COVID-19 Safety Check-In"),
    "fudan_daily_tick" : MessageLookupByLibrary.simpleMessage("Tap to check in"),
    "fudan_daily_tick_countdown" : m0,
    "fudan_daily_ticked" : MessageLookupByLibrary.simpleMessage("Already done"),
    "fudan_qr_code" : MessageLookupByLibrary.simpleMessage("Fudan QR Code"),
    "good_afternoon" : MessageLookupByLibrary.simpleMessage("The afternoon knows what the morning never suspected."),
    "good_morning" : MessageLookupByLibrary.simpleMessage("Every dawn is a new sunrise."),
    "good_night" : MessageLookupByLibrary.simpleMessage("Goodnight stars, goodnight air, goodnight noises everywhere."),
    "good_noon" : MessageLookupByLibrary.simpleMessage("Rise and shine."),
    "handan_campus" : MessageLookupByLibrary.simpleMessage("Handan"),
    "i_see" : MessageLookupByLibrary.simpleMessage("OK"),
    "jiangwan_campus" : MessageLookupByLibrary.simpleMessage("Jiangwan"),
    "last_15_days" : MessageLookupByLibrary.simpleMessage("Last 15 days"),
    "last_30_days" : MessageLookupByLibrary.simpleMessage("Last 30 days"),
    "last_7_days" : MessageLookupByLibrary.simpleMessage("Last 7 days"),
    "last_transaction" : MessageLookupByLibrary.simpleMessage("Last Transaction"),
    "late_night" : MessageLookupByLibrary.simpleMessage("The dead of midnight is the noon of thought."),
    "loading" : MessageLookupByLibrary.simpleMessage("Loading..."),
    "loading_qr_code" : MessageLookupByLibrary.simpleMessage("Loading Fudan QR Code...\nThis may take 5-10 seconds, depending on Fudan servers."),
    "login" : MessageLookupByLibrary.simpleMessage("Login"),
    "login_failed" : MessageLookupByLibrary.simpleMessage("Login failed. Check your ID and/or password."),
    "login_issue_1" : MessageLookupByLibrary.simpleMessage("Failed to log in through UIS system.\nIf you has attempted to log in with wrong passwords for several times, you might need to complete a successful login through a browser manually."),
    "login_issue_1_action" : MessageLookupByLibrary.simpleMessage("Open UIS Login Page"),
    "login_uis" : MessageLookupByLibrary.simpleMessage("Fudan UIS Login"),
    "login_uis_description" : MessageLookupByLibrary.simpleMessage("Your login information is only sent to Fudan servers via secure connection."),
    "login_uis_pwd" : MessageLookupByLibrary.simpleMessage("Password"),
    "login_uis_uid" : MessageLookupByLibrary.simpleMessage("ID"),
    "login_with_uis" : MessageLookupByLibrary.simpleMessage("Sign in anonymously as:"),
    "logining" : MessageLookupByLibrary.simpleMessage("Logging in..."),
    "logout" : MessageLookupByLibrary.simpleMessage("Logout"),
    "logout_prompt" : MessageLookupByLibrary.simpleMessage("You need to restart this app for changes to take effect."),
    "logout_question_prompt" : MessageLookupByLibrary.simpleMessage("Restart the app for changes to take effect"),
    "logout_question_prompt_title" : MessageLookupByLibrary.simpleMessage("Are you sure?"),
    "logout_subtitle" : MessageLookupByLibrary.simpleMessage("And delete all data from this device"),
    "material" : MessageLookupByLibrary.simpleMessage("Material"),
    "most_least_crowded_canteen" : m1,
    "new_post" : MessageLookupByLibrary.simpleMessage("New Post"),
    "open_source_software_licenses" : MessageLookupByLibrary.simpleMessage("Open Source Software Licenses"),
    "out_of_dining_time" : MessageLookupByLibrary.simpleMessage("It\'s not dining time right now."),
    "post_failed" : MessageLookupByLibrary.simpleMessage("Network error, post failed."),
    "privacy_policy" : MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "privacy_policy_url" : MessageLookupByLibrary.simpleMessage(""),
    "project_page" : MessageLookupByLibrary.simpleMessage("Project Page"),
    "project_url" : MessageLookupByLibrary.simpleMessage("https://github.com/w568w/DanXi"),
    "reply_to" : m2,
    "select_campus" : MessageLookupByLibrary.simpleMessage("Select Campus"),
    "settings" : MessageLookupByLibrary.simpleMessage("Settings"),
    "share" : MessageLookupByLibrary.simpleMessage("Share"),
    "share_as_ics" : MessageLookupByLibrary.simpleMessage("Export as ICS"),
    "tag_least_crowded" : MessageLookupByLibrary.simpleMessage("Least Crowded"),
    "tag_most_crowded" : MessageLookupByLibrary.simpleMessage("Most Crowded"),
    "tap_to_view" : MessageLookupByLibrary.simpleMessage("Tap to view"),
    "terms_and_conditions" : MessageLookupByLibrary.simpleMessage("Terms and Conditions"),
    "terms_and_conditions_content" : MessageLookupByLibrary.simpleMessage("Your use of this application is governed under "),
    "terms_and_conditions_content_end" : MessageLookupByLibrary.simpleMessage(". "),
    "terms_and_conditions_title" : MessageLookupByLibrary.simpleMessage("Legal"),
    "terms_and_conditions_url" : MessageLookupByLibrary.simpleMessage(""),
    "theme" : MessageLookupByLibrary.simpleMessage("Theme"),
    "tick_failed" : MessageLookupByLibrary.simpleMessage("Failed to check in. Check your internet connection."),
    "tick_issue_1" : MessageLookupByLibrary.simpleMessage("Failed to check in. Unable to obtain the previous record.\nIf you forgot to check in yesterday, you might need to check in manually."),
    "ticking" : MessageLookupByLibrary.simpleMessage("Checking in..."),
    "timetable" : MessageLookupByLibrary.simpleMessage("Agenda"),
    "view_ossl" : MessageLookupByLibrary.simpleMessage("This app is made possible thanks to various open-source software. View "),
    "welcome" : m3,
    "zhangjiang_campus" : MessageLookupByLibrary.simpleMessage("Zhangjiang")
  };
}
