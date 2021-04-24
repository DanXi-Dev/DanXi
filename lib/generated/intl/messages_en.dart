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

  static m0(num) => "${num} day(s) ago";

  static m1(date) => "DevTeam Announcement ${date}";

  static m2(time) => "Automatic check-in in ${time} seconds. Tap to cancel.";

  static m3(num) => "${num} hr(s) ago";

  static m4(num) => "${num} min(s) ago";

  static m5(mostCrowded, leastCrowded) => "[Most Crowded]${mostCrowded}餐厅 [Least Crowded]${leastCrowded}餐厅";

  static m6(code) => "Reply failed (HTTP ${code})";

  static m7(name) => "Reply No.${name}";

  static m8(code) => "Report failed (HTTP ${code})";

  static m9(num) => "${num} sec(s) ago";

  static m10(week) => "Week ${week}";

  static m11(name) => "Welcome, ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "about" : MessageLookupByLibrary.simpleMessage("About This App"),
    "account" : MessageLookupByLibrary.simpleMessage("Switch Account"),
    "afternoon" : MessageLookupByLibrary.simpleMessage("Afternoon"),
    "and" : MessageLookupByLibrary.simpleMessage(" and "),
    "app_description" : MessageLookupByLibrary.simpleMessage("A miniature Fudan Integrated Service App, created by several Fudan undergraduate students with love. We hope it can facilitate your life~"),
    "app_description_title" : MessageLookupByLibrary.simpleMessage("Description"),
    "app_feedback" : MessageLookupByLibrary.simpleMessage("[Feedback]"),
    "app_name" : MessageLookupByLibrary.simpleMessage("Danxi"),
    "author_descriptor" : MessageLookupByLibrary.simpleMessage("Passionate developers\nfrom Engineering & Economics\nat Fudan University"),
    "authors" : MessageLookupByLibrary.simpleMessage("Developers"),
    "cancel" : MessageLookupByLibrary.simpleMessage("Cancel"),
    "captcha_needed" : MessageLookupByLibrary.simpleMessage("Captcha needed, please following the on-screen instructions."),
    "change_account" : MessageLookupByLibrary.simpleMessage("Switch Account"),
    "choose_area" : MessageLookupByLibrary.simpleMessage("Select Campus"),
    "classroom" : MessageLookupByLibrary.simpleMessage("Classroom"),
    "connection_failed" : MessageLookupByLibrary.simpleMessage("Login failed. Check your Internet connection.\nMake sure to grant WLAN & Celluar permission when prompted."),
    "contact_us" : MessageLookupByLibrary.simpleMessage("Contact Us"),
    "credentials_invalid" : MessageLookupByLibrary.simpleMessage("Invalid username or password"),
    "cupertino" : MessageLookupByLibrary.simpleMessage("Cupertino"),
    "current_connection" : MessageLookupByLibrary.simpleMessage("Current Connection"),
    "current_connection_failed" : MessageLookupByLibrary.simpleMessage("Failed to obtain WLAN information, Precise Location permission required"),
    "current_connection_no_wifi" : MessageLookupByLibrary.simpleMessage("Not connected to WLAN"),
    "dashboard" : MessageLookupByLibrary.simpleMessage("Dashboard"),
    "day_ago" : m0,
    "default_campus" : MessageLookupByLibrary.simpleMessage("Current Campus"),
    "dev_image_url_1" : MessageLookupByLibrary.simpleMessage("assets/graphics/w568w.jpeg"),
    "dev_image_url_2" : MessageLookupByLibrary.simpleMessage("assets/graphics/kavinzhao.jpeg"),
    "dev_image_url_3" : MessageLookupByLibrary.simpleMessage("assets/graphics/kyln24.jpeg"),
    "dev_image_url_4" : MessageLookupByLibrary.simpleMessage("assets/graphics/hasbai.jpeg"),
    "dev_name_1" : MessageLookupByLibrary.simpleMessage("w568w"),
    "dev_name_2" : MessageLookupByLibrary.simpleMessage("kavinzhao"),
    "dev_name_3" : MessageLookupByLibrary.simpleMessage("KYLN24"),
    "dev_name_4" : MessageLookupByLibrary.simpleMessage("hasbai"),
    "dev_page_1" : MessageLookupByLibrary.simpleMessage("https://github.com/w568w"),
    "dev_page_2" : MessageLookupByLibrary.simpleMessage("https://github.com/kavinzhao"),
    "dev_page_3" : MessageLookupByLibrary.simpleMessage("https://github.com/KYLN24"),
    "dev_page_4" : MessageLookupByLibrary.simpleMessage("https://github.com/hasbai"),
    "developer_announcement" : m1,
    "dining_hall_crowdedness" : MessageLookupByLibrary.simpleMessage("Canteen Popularity"),
    "ecard_balance" : MessageLookupByLibrary.simpleMessage("Card Balance"),
    "ecard_balance_log" : MessageLookupByLibrary.simpleMessage("Transactions"),
    "empty_classrooms" : MessageLookupByLibrary.simpleMessage("Empty Classrooms"),
    "end_reached" : MessageLookupByLibrary.simpleMessage("You have reached the end."),
    "evening" : MessageLookupByLibrary.simpleMessage("Evening"),
    "fail_to_acquire_qr" : MessageLookupByLibrary.simpleMessage("Failed to obtain QR code. Please make sure you have activated the QR code in eHall."),
    "failed" : MessageLookupByLibrary.simpleMessage("Unable to load content, tap to retry"),
    "fatal_error" : MessageLookupByLibrary.simpleMessage("Fatal Error"),
    "feedback_email" : MessageLookupByLibrary.simpleMessage("danxi_dev@protonmail.com"),
    "fenglin_campus" : MessageLookupByLibrary.simpleMessage("Fenglin"),
    "forum" : MessageLookupByLibrary.simpleMessage("Tree Hole"),
    "forum_post_enter_content" : MessageLookupByLibrary.simpleMessage("Post"),
    "fudan_aao_notices" : MessageLookupByLibrary.simpleMessage("Academic Announcements"),
    "fudan_daily" : MessageLookupByLibrary.simpleMessage("Automatic COVID-19 Safety Check-In"),
    "fudan_daily_tick" : MessageLookupByLibrary.simpleMessage("Tap to check in"),
    "fudan_daily_tick_countdown" : m2,
    "fudan_daily_ticked" : MessageLookupByLibrary.simpleMessage("Already done"),
    "fudan_qr_code" : MessageLookupByLibrary.simpleMessage("Fudan QR Code"),
    "good_afternoon" : MessageLookupByLibrary.simpleMessage("The afternoon knows what the morning never suspected."),
    "good_morning" : MessageLookupByLibrary.simpleMessage("Every dawn is a new sunrise."),
    "good_night" : MessageLookupByLibrary.simpleMessage("Goodnight stars, goodnight air, goodnight noises everywhere."),
    "good_noon" : MessageLookupByLibrary.simpleMessage("Rise and shine."),
    "handan_campus" : MessageLookupByLibrary.simpleMessage("Handan"),
    "hour_ago" : m3,
    "i_see" : MessageLookupByLibrary.simpleMessage("OK"),
    "jiangwan_campus" : MessageLookupByLibrary.simpleMessage("Jiangwan"),
    "last_15_days" : MessageLookupByLibrary.simpleMessage("Last 15 days"),
    "last_30_days" : MessageLookupByLibrary.simpleMessage("Last 30 days"),
    "last_7_days" : MessageLookupByLibrary.simpleMessage("Last 7 days"),
    "last_transaction" : MessageLookupByLibrary.simpleMessage("Last Transaction"),
    "late_night" : MessageLookupByLibrary.simpleMessage("The dead of midnight is the noon of thought."),
    "loading" : MessageLookupByLibrary.simpleMessage("Loading..."),
    "loading_bbs_secure_connection" : MessageLookupByLibrary.simpleMessage("Performing server security check, please wait..."),
    "loading_qr_code" : MessageLookupByLibrary.simpleMessage("Loading Fudan QR Code...\nThis may take 5-10 seconds, depending on Fudan servers."),
    "login" : MessageLookupByLibrary.simpleMessage("Login"),
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
    "logout_question_prompt" : MessageLookupByLibrary.simpleMessage("All data stored locally will be deleted."),
    "logout_question_prompt_title" : MessageLookupByLibrary.simpleMessage("Are you sure?"),
    "logout_subtitle" : MessageLookupByLibrary.simpleMessage("And delete all data from this device"),
    "material" : MessageLookupByLibrary.simpleMessage("Material"),
    "minute_ago" : m4,
    "moment_ago" : MessageLookupByLibrary.simpleMessage("Moment ago"),
    "morning" : MessageLookupByLibrary.simpleMessage("Morning"),
    "most_least_crowded_canteen" : m5,
    "new_post" : MessageLookupByLibrary.simpleMessage("New Post"),
    "open_source_software_licenses" : MessageLookupByLibrary.simpleMessage("Open Source Software Licenses"),
    "out_of_dining_time" : MessageLookupByLibrary.simpleMessage("It\'s not dining time right now."),
    "post_failed" : MessageLookupByLibrary.simpleMessage("Network error, post failed."),
    "privacy_policy" : MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "privacy_policy_url" : MessageLookupByLibrary.simpleMessage("https://danxi-dev.github.io/privacy"),
    "project_page" : MessageLookupByLibrary.simpleMessage("Project Page"),
    "project_url" : MessageLookupByLibrary.simpleMessage("https://github.com/w568w/DanXi"),
    "reply_failed" : m6,
    "reply_to" : m7,
    "report" : MessageLookupByLibrary.simpleMessage("Report this post"),
    "report_failed" : m8,
    "report_success" : MessageLookupByLibrary.simpleMessage("Report success. Thank you for your contribution to our community."),
    "second_ago" : m9,
    "select_campus" : MessageLookupByLibrary.simpleMessage("Select Campus"),
    "settings" : MessageLookupByLibrary.simpleMessage("Settings"),
    "share" : MessageLookupByLibrary.simpleMessage("Share"),
    "share_as_ics" : MessageLookupByLibrary.simpleMessage("Export as ICS"),
    "tag_least_crowded" : MessageLookupByLibrary.simpleMessage("Least Crowded"),
    "tag_most_crowded" : MessageLookupByLibrary.simpleMessage("Most Crowded"),
    "tap_to_view" : MessageLookupByLibrary.simpleMessage("Tap to view"),
    "terms_and_conditions" : MessageLookupByLibrary.simpleMessage("Terms and Conditions"),
    "terms_and_conditions_content" : MessageLookupByLibrary.simpleMessage("Your use of this application is governed under "),
    "terms_and_conditions_content_end" : MessageLookupByLibrary.simpleMessage(". By logging in, you indicate that you have read and consent to these policies. "),
    "terms_and_conditions_title" : MessageLookupByLibrary.simpleMessage("Legal"),
    "theme" : MessageLookupByLibrary.simpleMessage("Theme"),
    "tick_failed" : MessageLookupByLibrary.simpleMessage("Failed to check in. Check your internet connection."),
    "tick_issue_1" : MessageLookupByLibrary.simpleMessage("Failed to check in. Unable to obtain the previous record.\nIf you forgot to check in yesterday, you might need to check in manually."),
    "ticking" : MessageLookupByLibrary.simpleMessage("Checking in..."),
    "timetable" : MessageLookupByLibrary.simpleMessage("Agenda"),
    "view_ossl" : MessageLookupByLibrary.simpleMessage("This app is made possible thanks to various open-source software. View "),
    "weak_password" : MessageLookupByLibrary.simpleMessage("Login failed. Unknown error.\nNote: Danxi does not support weak passwords. If UIS warns of weak password at login, please change your password at UIS Portal and try again."),
    "week" : m10,
    "welcome" : m11,
    "zhangjiang_campus" : MessageLookupByLibrary.simpleMessage("Zhangjiang")
  };
}
