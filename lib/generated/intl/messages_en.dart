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

  static m0(num) => "${num}d ago";

  static m1(date) => "DevTeam Announcement ${date}";

  static m2(tag) => "Filtering by \"${tag}\"";

  static m3(time) => "Automatic check-in in ${time} seconds. Tap to cancel.";

  static m4(num) => "${num} hr ago";

  static m5(username, date) => "[${username}] replied ${date}:";

  static m6(num) => "${num} min ago";

  static m7(mostCrowded, leastCrowded) => "[Most Crowded]${mostCrowded}餐厅 [Least Crowded]${leastCrowded}餐厅";

  static m8(courseName, courseLeft) => "Next course is ${courseName}. You have ${courseLeft} courses left today";

  static m9(id) => "Reason for reporting #${id}";

  static m10(code) => "Reply failed (HTTP ${code})";

  static m11(name) => "Reply #${name}";

  static m12(code) => "Report failed (HTTP ${code})";

  static m13(num) => "${num} sec ago";

  static m14(count) => "Popularity: ${count}";

  static m15(week) => "Week ${week}";

  static m16(name) => "Welcome, ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "about" : MessageLookupByLibrary.simpleMessage("About This App"),
    "account" : MessageLookupByLibrary.simpleMessage("Switch Account"),
    "acknowledgement_link_1" : MessageLookupByLibrary.simpleMessage("https://github.com/ivanfei-1"),
    "acknowledgement_name_1" : MessageLookupByLibrary.simpleMessage("Ivan Fei"),
    "acknowledgements" : MessageLookupByLibrary.simpleMessage("Acknowledgements"),
    "acknowledgements_1" : MessageLookupByLibrary.simpleMessage("We would like to acknowledge "),
    "acknowledgements_2" : MessageLookupByLibrary.simpleMessage(" for designing the icon of this app."),
    "add" : MessageLookupByLibrary.simpleMessage("Add"),
    "add_new_card" : MessageLookupByLibrary.simpleMessage("New Card"),
    "add_new_divider" : MessageLookupByLibrary.simpleMessage("New Divider"),
    "add_new_tag" : MessageLookupByLibrary.simpleMessage("Add new tag"),
    "afternoon" : MessageLookupByLibrary.simpleMessage("Afternoon"),
    "and" : MessageLookupByLibrary.simpleMessage(" and "),
    "app_description" : MessageLookupByLibrary.simpleMessage("A miniature Fudan Integrated Service App, created by several Fudan undergraduate students with love. We hope it can facilitate your life~"),
    "app_description_title" : MessageLookupByLibrary.simpleMessage("Description"),
    "app_feedback" : MessageLookupByLibrary.simpleMessage("[Feedback]"),
    "app_name" : MessageLookupByLibrary.simpleMessage("DanXi"),
    "author_descriptor" : MessageLookupByLibrary.simpleMessage("Passionate developers\nfrom Engineering & Economics\nat Fudan University"),
    "authors" : MessageLookupByLibrary.simpleMessage("Developers"),
    "cancel" : MessageLookupByLibrary.simpleMessage("Cancel"),
    "cannot_launch_url" : MessageLookupByLibrary.simpleMessage("Unable to open this URL"),
    "captcha_needed" : MessageLookupByLibrary.simpleMessage("Captcha needed, please following the on-screen instructions."),
    "change_account" : MessageLookupByLibrary.simpleMessage("Switch Account"),
    "choose_area" : MessageLookupByLibrary.simpleMessage("Select Campus"),
    "classroom" : MessageLookupByLibrary.simpleMessage("Classroom"),
    "connection_failed" : MessageLookupByLibrary.simpleMessage("Login failed. Check your Internet connection.\nMake sure to grant WLAN & Celluar permission when prompted."),
    "contact_us" : MessageLookupByLibrary.simpleMessage("Contact Us"),
    "copy" : MessageLookupByLibrary.simpleMessage("Copy"),
    "copy_success" : MessageLookupByLibrary.simpleMessage("Text copied"),
    "credentials_invalid" : MessageLookupByLibrary.simpleMessage("Invalid username or password"),
    "cupertino" : MessageLookupByLibrary.simpleMessage("[WARNING: DEBUG FEATURE] Cupertino"),
    "current_connection" : MessageLookupByLibrary.simpleMessage("Current Connection"),
    "current_connection_failed" : MessageLookupByLibrary.simpleMessage("Failed to obtain WLAN information, Precise Location permission required"),
    "current_connection_no_wifi" : MessageLookupByLibrary.simpleMessage("Not connected to WLAN"),
    "current_date" : MessageLookupByLibrary.simpleMessage("Current date: "),
    "dashboard" : MessageLookupByLibrary.simpleMessage("Dashboard"),
    "dashboard_layout" : MessageLookupByLibrary.simpleMessage("Dashboard Layout"),
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
    "divider" : MessageLookupByLibrary.simpleMessage("Divider"),
    "ecard_balance" : MessageLookupByLibrary.simpleMessage("Card Balance"),
    "ecard_balance_log" : MessageLookupByLibrary.simpleMessage("Transactions"),
    "edit" : MessageLookupByLibrary.simpleMessage("Edit"),
    "editor_hint" : MessageLookupByLibrary.simpleMessage("Hint: Swipe the toolbar to the right to see more styling options."),
    "empty_classrooms" : MessageLookupByLibrary.simpleMessage("Empty Classrooms"),
    "end_reached" : MessageLookupByLibrary.simpleMessage("You have reached the end."),
    "error_login_expired" : MessageLookupByLibrary.simpleMessage("Login Expired. Tap to login again"),
    "evening" : MessageLookupByLibrary.simpleMessage("Evening"),
    "exam_schedule" : MessageLookupByLibrary.simpleMessage("Exam Schedule"),
    "fail_to_acquire_qr" : MessageLookupByLibrary.simpleMessage("Failed to obtain QR code. Please make sure you have activated the QR code in eHall."),
    "failed" : MessageLookupByLibrary.simpleMessage("Unable to load content, tap to retry"),
    "fatal_error" : MessageLookupByLibrary.simpleMessage("Fatal Error"),
    "favorites" : MessageLookupByLibrary.simpleMessage("Favorites"),
    "fduhole_nsfw_behavior" : MessageLookupByLibrary.simpleMessage("FDUHole: NSFW content"),
    "feedback_email" : MessageLookupByLibrary.simpleMessage("danxi_dev@protonmail.com"),
    "fenglin_campus" : MessageLookupByLibrary.simpleMessage("Fenglin"),
    "filtering_by_tag" : m2,
    "fold" : MessageLookupByLibrary.simpleMessage("Fold"),
    "folded" : MessageLookupByLibrary.simpleMessage("This content is hidden. Tap to view"),
    "forum" : MessageLookupByLibrary.simpleMessage("Tree Hole"),
    "forum_post_enter_content" : MessageLookupByLibrary.simpleMessage("Post"),
    "fudan_aao_notices" : MessageLookupByLibrary.simpleMessage("Academic Announcements"),
    "fudan_daily" : MessageLookupByLibrary.simpleMessage("Safety Fudan Check-In"),
    "fudan_daily_disabled_notice" : MessageLookupByLibrary.simpleMessage("In response to request from the University, Auto-CheckIn is no longer available."),
    "fudan_daily_tick" : MessageLookupByLibrary.simpleMessage("[WARNING: DEBUG FEATURE] Tap to check in"),
    "fudan_daily_tick_countdown" : m3,
    "fudan_daily_tick_link" : MessageLookupByLibrary.simpleMessage("Tap to open check-in webpage"),
    "fudan_daily_ticked" : MessageLookupByLibrary.simpleMessage("Already done"),
    "fudan_qr_code" : MessageLookupByLibrary.simpleMessage("Fudan QR Code"),
    "good_afternoon" : MessageLookupByLibrary.simpleMessage("The afternoon knows what the morning never suspected."),
    "good_morning" : MessageLookupByLibrary.simpleMessage("Every dawn is a new sunrise."),
    "good_night" : MessageLookupByLibrary.simpleMessage("Goodnight stars, goodnight air, goodnight noises everywhere."),
    "good_noon" : MessageLookupByLibrary.simpleMessage("Rise and shine."),
    "handan_campus" : MessageLookupByLibrary.simpleMessage("Handan"),
    "hidden_widgets" : MessageLookupByLibrary.simpleMessage("Hidden"),
    "hide" : MessageLookupByLibrary.simpleMessage("Hide"),
    "hour_ago" : m4,
    "i_see" : MessageLookupByLibrary.simpleMessage("OK"),
    "image_tag" : MessageLookupByLibrary.simpleMessage("[Image]"),
    "invalid_format" : MessageLookupByLibrary.simpleMessage("Invalid format"),
    "jiangwan_campus" : MessageLookupByLibrary.simpleMessage("Jiangwan"),
    "last_15_days" : MessageLookupByLibrary.simpleMessage("Last 15 days"),
    "last_30_days" : MessageLookupByLibrary.simpleMessage("Last 30 days"),
    "last_7_days" : MessageLookupByLibrary.simpleMessage("Last 7 days"),
    "last_created" : MessageLookupByLibrary.simpleMessage("Last created"),
    "last_replied" : MessageLookupByLibrary.simpleMessage("Last replied"),
    "last_transaction" : MessageLookupByLibrary.simpleMessage("Last Transaction"),
    "late_night" : MessageLookupByLibrary.simpleMessage("The dead of midnight is the noon of thought."),
    "latest_reply" : m5,
    "link" : MessageLookupByLibrary.simpleMessage("Link"),
    "loading" : MessageLookupByLibrary.simpleMessage("Loading..."),
    "loading_bbs_secure_connection" : MessageLookupByLibrary.simpleMessage("Performing server security check, please wait..."),
    "loading_qr_code" : MessageLookupByLibrary.simpleMessage("Loading Fudan QR Code...\nThis may take 5-10 seconds, depending on Fudan servers."),
    "location_permission_denied_promot" : MessageLookupByLibrary.simpleMessage("Location information unavailable. You will not be able to check-in in the app. If you would like to grant location permission to this app, please adjust your preferences in Settings."),
    "login" : MessageLookupByLibrary.simpleMessage("Login"),
    "login_issue_1" : MessageLookupByLibrary.simpleMessage("Failed to log in through UIS system.\nIf you has attempted to log in with wrong passwords for several times, you might need to complete a successful login through a browser manually."),
    "login_issue_1_action" : MessageLookupByLibrary.simpleMessage("Open UIS Login Page"),
    "login_uis" : MessageLookupByLibrary.simpleMessage("Fudan UIS Login"),
    "login_uis_description" : MessageLookupByLibrary.simpleMessage("Your password is only sent to Fudan servers via secure connection."),
    "login_uis_pwd" : MessageLookupByLibrary.simpleMessage("Password"),
    "login_uis_uid" : MessageLookupByLibrary.simpleMessage("ID"),
    "login_with_uis" : MessageLookupByLibrary.simpleMessage("Sign in anonymously as:"),
    "logining" : MessageLookupByLibrary.simpleMessage("Logging in..."),
    "logout" : MessageLookupByLibrary.simpleMessage("Logout"),
    "logout_prompt" : MessageLookupByLibrary.simpleMessage("You need to restart this app for changes to take effect."),
    "logout_question_prompt" : MessageLookupByLibrary.simpleMessage("All data stored locally will be deleted."),
    "logout_question_prompt_title" : MessageLookupByLibrary.simpleMessage("Are you sure?"),
    "logout_subtitle" : MessageLookupByLibrary.simpleMessage("And delete all data from this device"),
    "material" : MessageLookupByLibrary.simpleMessage("[WARNING: DEBUG FEATURE] Material"),
    "minute_ago" : m6,
    "moment_ago" : MessageLookupByLibrary.simpleMessage("A moment ago"),
    "morning" : MessageLookupByLibrary.simpleMessage("Morning"),
    "most_least_crowded_canteen" : m7,
    "name" : MessageLookupByLibrary.simpleMessage("Name"),
    "new_post" : MessageLookupByLibrary.simpleMessage("New Post"),
    "new_shortcut_card" : MessageLookupByLibrary.simpleMessage("New Shortcut Card"),
    "new_shortcut_description" : MessageLookupByLibrary.simpleMessage("Create a card that opens a webpage when tapped."),
    "next_course_is" : m8,
    "next_course_none" : MessageLookupByLibrary.simpleMessage("You have completed today\'s courses"),
    "no_favorites" : MessageLookupByLibrary.simpleMessage("You have no favorites"),
    "no_summary" : MessageLookupByLibrary.simpleMessage("[Unable to display content of this type.]"),
    "open_source_software_licenses" : MessageLookupByLibrary.simpleMessage("Open Source Software Licenses"),
    "operation_failed" : MessageLookupByLibrary.simpleMessage("Operaion Failed"),
    "other_types_exam" : MessageLookupByLibrary.simpleMessage("Paper and Other"),
    "out_of_dining_time" : MessageLookupByLibrary.simpleMessage("It\'s not dining time right now."),
    "pe_exercises" : MessageLookupByLibrary.simpleMessage("PE Exercises"),
    "post_failed" : MessageLookupByLibrary.simpleMessage("Failed to post. Please check your internet connection."),
    "privacy_policy" : MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "privacy_policy_url" : MessageLookupByLibrary.simpleMessage("https://danxi-dev.github.io/privacy"),
    "project_page" : MessageLookupByLibrary.simpleMessage("Project Page"),
    "project_url" : MessageLookupByLibrary.simpleMessage("https://danxi-dev.github.io"),
    "rate" : MessageLookupByLibrary.simpleMessage("Rate Us"),
    "reason_report_post" : m9,
    "reorder_hint" : MessageLookupByLibrary.simpleMessage("To reorder cards, press and hold a tile and drag it.\nSwipe to remove an auxiliary card."),
    "reply_failed" : m10,
    "reply_to" : m11,
    "report" : MessageLookupByLibrary.simpleMessage("Report"),
    "report_failed" : m12,
    "report_success" : MessageLookupByLibrary.simpleMessage("Report success. Thank you for your contribution to our community."),
    "reset_layout" : MessageLookupByLibrary.simpleMessage("Reset Layout"),
    "school_bus" : MessageLookupByLibrary.simpleMessage("School Bus"),
    "search_hint" : MessageLookupByLibrary.simpleMessage("Search or #PID"),
    "search_result" : MessageLookupByLibrary.simpleMessage("Search Result"),
    "second_ago" : m13,
    "select_campus" : MessageLookupByLibrary.simpleMessage("Select Campus"),
    "select_tags" : MessageLookupByLibrary.simpleMessage("Select Tags"),
    "settings" : MessageLookupByLibrary.simpleMessage("Settings"),
    "share" : MessageLookupByLibrary.simpleMessage("Share"),
    "share_as_ics" : MessageLookupByLibrary.simpleMessage("Export as ICS"),
    "show" : MessageLookupByLibrary.simpleMessage("Show"),
    "sort_order" : MessageLookupByLibrary.simpleMessage("Sort order"),
    "submit" : MessageLookupByLibrary.simpleMessage("Submit"),
    "tag_count" : m14,
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
    "today_course" : MessageLookupByLibrary.simpleMessage("Courses Today"),
    "unable_to_access_url" : MessageLookupByLibrary.simpleMessage("Test connection failed\nCan\'t to connect to this website, please check your URL."),
    "unmovable_widget" : MessageLookupByLibrary.simpleMessage("This object cannot be moved"),
    "uploading_image" : MessageLookupByLibrary.simpleMessage("Uploading image..."),
    "uploading_image_failed" : MessageLookupByLibrary.simpleMessage("Failed to upload image. Please check your internet connection."),
    "version" : MessageLookupByLibrary.simpleMessage("Version"),
    "view_ossl" : MessageLookupByLibrary.simpleMessage("This app is made possible thanks to various open-source software. View "),
    "weak_password" : MessageLookupByLibrary.simpleMessage("Login failed. Unknown error.\nNote: Danxi does not support weak passwords. If UIS warns of weak password at login, please change your password at UIS Portal and try again."),
    "week" : m15,
    "welcome" : m16,
    "welcome_feature" : MessageLookupByLibrary.simpleMessage("Welcome"),
    "zhangjiang_campus" : MessageLookupByLibrary.simpleMessage("Zhangjiang")
  };
}
