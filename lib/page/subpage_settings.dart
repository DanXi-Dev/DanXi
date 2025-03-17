/*
 *     Copyright (C) 2021 DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/pubspec.yaml.g.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/user.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/settings/open_source_license.dart';
import 'package:dan_xi/page/subpage_forum.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/forum/clean_mode_filter.dart';
import 'package:dan_xi/util/io/cache_manager_with_webvpn.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/util/win32/auto_start.dart'
    if (dart.library.html) 'package:dan_xi/util/win32/auto_start_stub.dart';
import 'package:dan_xi/widget/dialogs/swatch_picker_dialog.dart';
import 'package:dan_xi/widget/forum/post_render.dart';
import 'package:dan_xi/widget/forum/render/render_impl.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/image_picker_proxy.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:nil/nil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

Future<void> updateOTUserProfile(BuildContext context) async {
  try {
    await ForumRepository.getInstance().updateUserProfile();
  } catch (e, st) {
    if (context.mounted) {
      Noticing.showErrorDialog(context, e, trace: st);
    }
  }
}

class SettingsSubpage extends PlatformSubpage<SettingsSubpage> {
  @override
  SettingsSubpageState createState() => SettingsSubpageState();

  const SettingsSubpage({super.key});

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).settings);
}

class SettingsSubpageState extends PlatformSubpageState<SettingsSubpage> {
  /// All open-source license for the app.
  static const List<LicenseItem> _LICENSE_ITEMS = [
    LicenseItem("asn1lib", LICENSE_BSD, "https://github.com/wstrange/asn1lib"),
    LicenseItem("cached_network_image", LICENSE_MIT,
        "https://github.com/Baseflow/flutter_cached_network_image"),
    LicenseItem(
        "win32", LICENSE_BSD_3_0_CLAUSE, "https://github.com/timsneath/win32"),
    LicenseItem("collection", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/dart-lang/collection"),
    LicenseItem(
        "meta", LICENSE_BSD_3_0_CLAUSE, "https://github.com/dart-lang/sdk"),
    LicenseItem("flutter_layout_grid", LICENSE_MIT,
        "https://github.com/madewithfelt/flutter_layout_grid"),
    LicenseItem(
        "flutter_js", LICENSE_MIT, "https://github.com/abner/flutter_js"),
    LicenseItem("fluttertoast", LICENSE_MIT,
        "https://github.com/PonnamKarthik/FlutterToast"),
    LicenseItem("markdown", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/dart-lang/markdown"),
    LicenseItem("flutter_typeahead", LICENSE_BSD_2_0_CLAUSE,
        "https://github.com/AbdulRahmanAlHamali/flutter_typeahead"),
    LicenseItem("flutter_markdown", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/flutter/packages/tree/master/packages/flutter_markdown"),
    LicenseItem("image_picker", LICENSE_APACHE_2_0,
        "https://github.com/flutter/plugins/tree/master/packages/image_picker/image_picker"),
    LicenseItem("Kotlin Stdlib Jdk7", LICENSE_APACHE_2_0,
        "https://github.com/JetBrains/kotlin"),
    LicenseItem("auto_size_text", LICENSE_MIT,
        "https://github.com/leisim/auto_size_text"),
    LicenseItem("beautiful_soup_dart", LICENSE_MIT,
        "https://github.com/mzdm/beautiful_soup"),
    LicenseItem("build_runner", LICENSE_BSD,
        "https://github.com/dart-lang/build/tree/master/build_runner"),
    LicenseItem("clipboard", LICENSE_BSD,
        "https://github.com/samuelezedi/flutter_clipboard"),
    LicenseItem("cupertino_icons", LICENSE_MIT,
        "https://github.com/flutter/cupertino_icons"),
    LicenseItem("desktop_window", LICENSE_MIT,
        "https://github.com/mix1009/desktop_window"),
    LicenseItem("dio", LICENSE_MIT, "https://github.com/flutterchina/dio"),
    LicenseItem("dio_cookie_manager", LICENSE_MIT,
        "https://github.com/flutterchina/dio"),
    LicenseItem("dio_log", LICENSE_APACHE_2_0,
        "https://github.com/flutterplugin/dio_log"),
    LicenseItem("event_bus", LICENSE_MIT,
        "https://github.com/marcojakob/dart-event-bus"),
    LicenseItem("file_picker", LICENSE_MIT,
        "https://github.com/miguelpruivo/plugins_flutter_file_picker"),
    LicenseItem("flutter", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/flutter/flutter"),
    LicenseItem("flutter_email_sender", LICENSE_APACHE_2_0,
        "https://github.com/sidlatau/flutter_email_sender"),
    LicenseItem("flutter_html", LICENSE_MIT,
        "https://github.com/Sub6Resources/flutter_html"),
    LicenseItem("flutter_inappwebview", LICENSE_APACHE_2_0,
        "https://github.com/pichillilorenzo/flutter_inappwebview"),
    LicenseItem("flutter_math_fork", LICENSE_APACHE_2_0,
        "https://github.com/simpleclub-extended/flutter_math_fork"),
    LicenseItem("flutter_linkify", LICENSE_MIT,
        "https://github.com/Cretezy/flutter_linkify"),
    LicenseItem("flutter_localizations", LICENSE_BSD_3_0_CLAUSE,
        "https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html"),
    LicenseItem("flutter_phoenix", LICENSE_MIT,
        "https://github.com/mobiten/flutter_phoenix"),
    LicenseItem("flutter_platform_widgets", LICENSE_MIT,
        "https://github.com/stryder-dev/flutter_platform_widgets"),
    LicenseItem("flutter_progress_dialog", LICENSE_APACHE_2_0,
        "https://github.com/wuzhendev/flutter_progress_dialog"),
    LicenseItem("flutter_sfsymbols", LICENSE_APACHE_2_0,
        "https://github.com/virskor/flutter_sfsymbols"),
    LicenseItem("flutter_tagging", LICENSE_BSD,
        "https://github.com/sarbagyastha/flutter_tagging"),
    LicenseItem("flutter_test", LICENSE_BSD_3_0_CLAUSE,
        "https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html"),
    LicenseItem("gallery_saver", LICENSE_APACHE_2_0,
        "https://github.com/CarnegieTechnologies/gallery_saver"),
    LicenseItem("xiao_mi_push_plugin", LICENSE_APACHE_2_0,
        "https://github.com/w568w/FlutterXiaoMiPushPlugin"),
    LicenseItem("http", LICENSE_BSD, "https://github.com/dart-lang/http"),
    LicenseItem(
        "ical", LICENSE_BSD_3_0_CLAUSE, "https://github.com/dartclub/ical"),
    LicenseItem("platform_device_id", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/BestBurning/platform_device_id"),
    LicenseItem("in_app_review", LICENSE_MIT,
        "https://github.com/britannio/in_app_review"),
    LicenseItem("intl", LICENSE_BSD, "https://github.com/dart-lang/intl"),
    LicenseItem("json_serializable", LICENSE_BSD,
        "https://github.com/google/json_serializable.dart/tree/master/json_serializable"),
    LicenseItem("linkify", LICENSE_MIT, "https://github.com/Cretezy/linkify"),
    LicenseItem("pubspec_generator", LICENSE_MIT,
        "https://github.com/PlugFox/pubspec_generator"),
    LicenseItem(
        "open_file", LICENSE_BSD, "https://github.com/crazecoder/open_file"),
    LicenseItem(
        "package_info", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem(
        "path_provider", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("permission_handler", LICENSE_MIT,
        "https://github.com/baseflowit/flutter-permission-handler"),
    LicenseItem("photo_view", LICENSE_MIT,
        "https://github.com/renancaraujo/photo_view"),
    LicenseItem(
        "provider", LICENSE_MIT, "https://github.com/rrousselGit/provider"),
    LicenseItem(
        "qr_flutter", LICENSE_BSD, "https://github.com/theyakka/qr.flutter"),
    LicenseItem(
        "quick_actions", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("screen", LICENSE_MIT,
        "https://github.com/clovisnicolas/flutter_screen"),
    LicenseItem("share", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("shared_preferences", LICENSE_BSD,
        "https://github.com/flutter/plugins"),
    LicenseItem(
        "url_launcher", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("screen_brightness", LICENSE_MIT,
        "https://github.com/aaassseee/screen_brightness"),
    LicenseItem("uuid", LICENSE_MIT, "https://github.com/Daegalus/dart-uuid"),
    LicenseItem("lunar", LICENSE_MIT, "https://github.com/6tail/lunar-flutter"),
    LicenseItem("animated_text_kit", LICENSE_MIT,
        "https://github.com/aagarwal1012/Animated-Text-Kit"),
    LicenseItem("flutter_fgbg", LICENSE_MIT,
        "https://github.com/ajinasokan/flutter_fgbg"),
    LicenseItem("lazy_load_indexed_stack", LICENSE_MIT,
        "https://github.com/okaryo/lazy_load_indexed_stack"),
    LicenseItem("screen_capture_event", LICENSE_MIT,
        "https://github.com/nizwar/screen_capture_event"),
    LicenseItem("otp", LICENSE_MIT, "https://github.com/Daegalus/dart-otp"),
    LicenseItem(
        "js", LICENSE_BSD_3_0_CLAUSE, "https://github.com/dart-lang/sdk"),
    LicenseItem("device_info_plus", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/fluttercommunity/plus_plugins/tree/main/packages/device_info_plus"),
    LicenseItem("nil", LICENSE_MIT, "https://github.com/letsar/nil"),
    LicenseItem("flex_color_picker", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/rydmike/flex_color_picker"),
    LicenseItem("material_color_generator", LICENSE_BSD_2_0_CLAUSE,
        "https://github.com/berkanaslan/material-color-generator"),
    LicenseItem("flutter_swiper_view", LICENSE_MIT,
        "https://github.com/feicien/flutter_swiper_view"),
    LicenseItem("mutex", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/hoylen/dart-mutex"),
    LicenseItem("receive_intent", LICENSE_GPL_3_0,
        "https://github.com/w568w/receive_intent"),
    LicenseItem("flutter_secure_storage", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/mogol/flutter_secure_storage"),
    LicenseItem("encrypt_shared_preferences", LICENSE_APACHE_2_0,
        "https://github.com/xaldarof/encrypted-shared-preferences"),
    LicenseItem("device_identity", LICENSE_MIT,
        "https://github.com/50431040/device_identity"),
    LicenseItem("tutorial_coach_mark", LICENSE_MIT,
        "https://github.com/RafaelBarbosatec/tutorial_coach_mark"),
    LicenseItem("toml", LICENSE_MIT, "https://github.com/just95/toml.dart"),
    LicenseItem("pub_semver", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/dart-lang/pub_semver"),
  ];

  String? _clearCacheSubtitle;

  Future<void> _deleteAllDataAndExit() async {
    ProgressFuture progressDialog =
        showProgressDialog(loadingText: S.of(context).logout, context: context);
    try {
      await ForumRepository.getInstance().logout();
    } finally {
      progressDialog.dismiss(showAnim: false);
      await SettingsProvider.getInstance().preferences?.clear();
      if (mounted) {
        FlutterApp.restartApp(context);
      }
    }
  }

  List<Widget> _buildCampusAreaList(BuildContext menuContext) {
    List<Widget> list = [];
    onTapListener(Campus campus) {
      SettingsProvider.getInstance().campus = campus;
      dashboardPageKey.currentState?.triggerRebuildFeatures();
      refreshSelf();
    }

    for (var value in Constant.CAMPUS_VALUES) {
      list.add(PlatformContextMenuItem(
        menuContext: menuContext,
        child: Text(value.displayTitle(menuContext)),
        onPressed: () => onTapListener(value),
      ));
    }
    return list;
  }

  List<Widget> _buildFoldBehaviorList(BuildContext menuContext) {
    List<Widget> list = [];
    void onTapListener(FoldBehavior value) {
      context.read<ForumProvider>().userInfo!.config!.show_folded =
          value.internalString();
      updateOTUserProfile(context);
      forumPageKey.currentState?.setState(() {});
      refreshSelf();
    }

    for (var value in FoldBehavior.values) {
      list.add(
        PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () => onTapListener(value),
          child: Text(value.displayTitle(menuContext)!),
        ),
      );
    }
    return list;
  }

  List<Widget> _buildLanguageList(BuildContext menuContext) {
    List<Widget> list = [];
    onTapListener(Language language) {
      SettingsProvider.getInstance().language = language;
    }

    for (var value in Constant.LANGUAGE_VALUES) {
      list.add(PlatformContextMenuItem(
        menuContext: menuContext,
        child: Text(value.displayTitle(menuContext)),
        onPressed: () => onTapListener(value),
      ));
    }
    return list;
  }

  List<Widget> _buildThemeList(BuildContext menuContext) {
    List<Widget> list = [];
    onTapListener(ThemeType theme) {
      SettingsProvider.getInstance().themeType = theme;
    }

    for (var value in ThemeType.values) {
      list.add(PlatformContextMenuItem(
        menuContext: menuContext,
        child: Text(value.displayTitle(menuContext) ?? "null"),
        onPressed: () => onTapListener(value),
      ));
    }
    return list;
  }

  @override
  Widget buildPage(BuildContext context) {
    // Load preference fields
    return WithScrollbar(
        controller: PrimaryScrollController.of(context),
        child: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top,
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              refreshSelf();
            },
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  //Account Selection
                  Card(
                    child: Column(children: [
                      ListTile(
                        title: Text(S.of(context).account),
                        leading: PlatformX.isMaterial(context)
                            ? const Icon(Icons.account_circle)
                            : const Icon(CupertinoIcons.person_circle),
                        subtitle: Text(
                            "${StateProvider.personInfo.value!.name} (${StateProvider.personInfo.value!.id})"),
                        onTap: () {
                          showPlatformDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) =>
                                PlatformAlertDialog(
                              title: Text(
                                  S.of(context).logout_question_prompt_title),
                              content:
                                  Text(S.of(context).logout_question_prompt),
                              actions: [
                                PlatformDialogAction(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                PlatformDialogAction(
                                    child: Text(
                                      S.of(context).i_see,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteAllDataAndExit();
                                    })
                              ],
                            ),
                          );
                        },
                      ),

                      // Campus
                      ListTile(
                        title: Text(S.of(context).default_campus),
                        leading: PlatformX.isMaterial(context)
                            ? const Icon(Icons.location_on)
                            : const Icon(CupertinoIcons.location_fill),
                        subtitle: Text(SettingsProvider.getInstance()
                            .campus
                            .displayTitle(context)),
                        onTap: () => showPlatformModalSheet(
                            context: context,
                            builder: (BuildContext context) =>
                                PlatformContextMenu(
                                    actions: _buildCampusAreaList(context),
                                    cancelButton: CupertinoActionSheetAction(
                                        child: Text(S.of(context).cancel),
                                        onPressed: () =>
                                            Navigator.of(context).pop()))),
                      ),
                    ]),
                  ),
                  // Accessibility
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(S.of(context).default_language),
                          leading: PlatformX.isMaterial(context)
                              ? const Icon(Icons.language)
                              : const Icon(CupertinoIcons.globe),
                          subtitle: Text(SettingsProvider.getInstance()
                              .language
                              .displayTitle(context)),
                          onTap: () => showPlatformModalSheet(
                              context: context,
                              builder: (BuildContext context) =>
                                  PlatformContextMenu(
                                      actions: _buildLanguageList(context),
                                      cancelButton: CupertinoActionSheetAction(
                                          child: Text(S.of(context).cancel),
                                          onPressed: () =>
                                              Navigator.of(context).pop()))),
                        ),
                        Selector<SettingsProvider, bool>(
                          selector: (_, model) =>
                              model.useAccessibilityColoring,
                          builder: (_, bool value, __) =>
                              SwitchListTile.adaptive(
                            title: Text(S.of(context).accessibility_coloring),
                            subtitle: Text(
                                S.of(context).high_contrast_color_description),
                            secondary:
                                const Icon(Icons.accessibility_new_rounded),
                            value: value,
                            onChanged: (bool value) {
                              SettingsProvider.getInstance()
                                  .useAccessibilityColoring = value;
                              forumPageKey.currentState?.setState(() {});
                            },
                          ),
                        ),
                        if (PlatformX.isMaterial(context))
                          ListTile(
                            title: Text(S.of(context).theme_color),
                            subtitle:
                                Text(S.of(context).theme_color_description),
                            leading: const Icon(Icons.color_lens),
                            onTap: () async {
                              MaterialColor? result =
                                  await showPlatformDialog<MaterialColor?>(
                                context: context,
                                builder: (_) => SwatchPickerDialog(
                                  initialSelectedColor: context
                                      .read<SettingsProvider>()
                                      .primarySwatch,
                                ),
                              );
                              if (result != null && mounted) {
                                context
                                    .read<SettingsProvider>()
                                    .setPrimarySwatch(result.value);
                                FlutterApp.restartApp(context);
                              }
                            },
                          ),
                        ListTile(
                          title: Text(S.of(context).theme),
                          subtitle: Text(context
                                  .select<SettingsProvider, ThemeType>(
                                      (s) => s.themeType)
                                  .displayTitle(context) ??
                              "null"),
                          leading: const Icon(Icons.brightness_4),
                          onTap: () => showPlatformModalSheet(
                              context: context,
                              builder: (BuildContext context) =>
                                  PlatformContextMenu(
                                      actions: _buildThemeList(context),
                                      cancelButton: CupertinoActionSheetAction(
                                          child: Text(S.of(context).cancel),
                                          onPressed: () =>
                                              Navigator.of(context).pop()))),
                        ),
                        ListTile(
                          title: Text(S.of(context).proxy_setting),
                          subtitle: Text(
                              context.select<SettingsProvider, String?>(
                                      (s) => s.proxy) ??
                                  S.of(context).proxy_setting_unset),
                          leading: const Icon(Icons.network_ping),
                          onTap: () async {
                            String? addr = await Noticing.showInputDialog(
                                context,
                                S.of(context).proxy_setting_input_title,
                                initialText:
                                    context.read<SettingsProvider>().proxy,
                                hintText:
                                    S.of(context).proxy_setting_input_hint);
                            if (!context.mounted || addr == null) {
                              return; // return if cancelled
                            }
                            if (addr.isEmpty) addr = null;
                            context.read<SettingsProvider>().proxy = addr;
                            await Noticing.showNotice(context,
                                S.of(context).proxy_setting_set_successfully);
                          },
                          enabled: !PlatformX.isWeb,
                        ),
                        if (context.select<SettingsProvider, bool>(
                            (value) => value.hiddenNotifications.isNotEmpty))
                          ListTile(
                            title:
                                Text(S.of(context).show_hidden_notifications),
                            subtitle: Text(S
                                .of(context)
                                .show_hidden_notifications_description),
                            leading: const Icon(Icons.notifications_off),
                            onTap: () => context
                                .read<SettingsProvider>()
                                .hiddenNotifications = [],
                          ),
                        SwitchListTile.adaptive(
                            title: Text(S.of(context).use_webvpn_title),
                            secondary: const Icon(Icons.network_cell),
                            subtitle:
                                Text(S.of(context).use_webvpn_description),
                            value: context.select<SettingsProvider, bool>(
                                (s) => s.useWebvpn),
                            onChanged: (bool value) async {
                              context.read<SettingsProvider>().useWebvpn =
                                  value;
                            })
                      ],
                    ),
                  ),
                  if (PlatformX.isWindows)
                    Card(
                      child: SwitchListTile.adaptive(
                          title: Text(S.of(context).windows_auto_start_title),
                          secondary: const Icon(Icons.settings_power),
                          subtitle: Text(
                              S.of(context).windows_auto_start_description),
                          value: WindowsAutoStart.autoStart,
                          onChanged: (bool value) async {
                            WindowsAutoStart.autoStart = value;
                            await Noticing.showNotice(
                                context,
                                S
                                    .of(context)
                                    .windows_auto_start_wait_dialog_message,
                                title: S
                                    .of(context)
                                    .windows_auto_start_wait_dialog_title,
                                useSnackBar: false);
                            refreshSelf();
                          }),
                    ),

                  // FDUHOLE
                  _buildForumSettingsCard(context),
                  if (SettingsProvider.getInstance().debugMode)
                    //Theme Selection
                    Card(
                      child: ListTile(
                        title: Text(S.of(context).theme),
                        leading: PlatformX.isMaterial(context)
                            ? const Icon(Icons.color_lens)
                            : const Icon(CupertinoIcons.color_filter),
                        subtitle: Text(PlatformX.isMaterial(context)
                            ? S.of(context).material
                            : S.of(context).cupertino),
                        onTap: () => PlatformX.isMaterial(context)
                            ? PlatformProvider.of(context)!
                                .changeToCupertinoPlatform()
                            : PlatformProvider.of(context)!
                                .changeToMaterialPlatform(),
                      ),
                    ),
                  if (SettingsProvider.getInstance().debugMode)
                    Card(
                        child: ListTile(
                            title: const Text("Fancy Watermark"),
                            leading: const Icon(Icons.numbers),
                            subtitle: const Text(
                                "[WARNING: DEBUG FEATURE] Visible watermark"),
                            onTap: () {
                              if (SettingsProvider.getInstance()
                                  .visibleWatermarkMode) {
                                SettingsProvider.getInstance()
                                    .lightWatermarkColor = 0x2a000000;
                                SettingsProvider.getInstance()
                                    .darkWatermarkColor = 0x2a000000;
                                SettingsProvider.getInstance()
                                    .visibleWatermarkMode = false;
                              } else {
                                SettingsProvider.getInstance()
                                    .lightWatermarkColor = 0x04000000;
                                SettingsProvider.getInstance()
                                    .darkWatermarkColor = 0x0a000000;
                                SettingsProvider.getInstance()
                                    .visibleWatermarkMode = true;
                              }
                              FlutterApp.restartApp(context);
                            })),

                  // Sponsor Option
                  // if (PlatformX.isMobile)
                  //   Card(
                  //     child: ListTile(
                  //       isThreeLine:
                  //           !SettingsProvider.getInstance().isAdEnabled,
                  //       leading: Icon(
                  //         PlatformIcons(context).heartSolid,
                  //       ),
                  //       title: Text(S.of(context).sponsor_us),
                  //       subtitle: Text(
                  //           SettingsProvider.getInstance().isAdEnabled
                  //               ? S.of(context).sponsor_us_enabled
                  //               : S.of(context).sponsor_us_disabled),
                  //       onTap: () async {
                  //         if (SettingsProvider.getInstance().isAdEnabled) {
                  //           _toggleAdDisplay();
                  //         } else {
                  //           _toggleAdDisplay();
                  //           await _showAdsThankDialog();
                  //         }
                  //       },
                  //     ),
                  //   ),

                  // About
                  _buildAboutCard(context)
                ])));
  }

  Widget _buildForumSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ExpansionTileX(
            leading: Icon(PlatformIcons(context).accountCircle),
            title: Text(S.of(context).forum),
            subtitle: Text(context.read<ForumProvider>().isUserInitialized
                ? S.of(context).forum_user_id(
                    context.read<ForumProvider>().userInfo!.user_id ?? "null")
                : S.of(context).not_logged_in),
            children: [
              if (context.watch<ForumProvider>().isUserInitialized) ...[
                FutureWidget<OTUser?>(
                  future: ForumRepository.getInstance().getUserProfile(),
                  successBuilder:
                      (BuildContext context, AsyncSnapshot<OTUser?> snapshot) =>
                          ListTile(
                    title: Text(S.of(context).forum_nsfw_behavior),
                    leading: PlatformX.isMaterial(context)
                        ? const Icon(Icons.hide_image)
                        : const Icon(CupertinoIcons.eye_slash),
                    subtitle: Text(foldBehaviorFromInternalString(
                            snapshot.data!.config!.show_folded!)
                        .displayTitle(context)!),
                    onTap: () {
                      showPlatformModalSheet(
                          context: context,
                          builder: (BuildContext context) =>
                              PlatformContextMenu(
                                actions: _buildFoldBehaviorList(context),
                                cancelButton: CupertinoActionSheetAction(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ));
                    },
                  ),
                  errorBuilder: ListTile(
                    title: Text(S.of(context).forum_nsfw_behavior),
                    leading: PlatformX.isMaterial(context)
                        ? const Icon(Icons.hide_image)
                        : const Icon(CupertinoIcons.eye_slash),
                    subtitle: Text(S.of(context).fatal_error),
                    onTap: () => refreshSelf(),
                  ),
                  loadingBuilder: ListTile(
                    title: Text(S.of(context).forum_nsfw_behavior),
                    leading: PlatformX.isMaterial(context)
                        ? const Icon(Icons.hide_image)
                        : const Icon(CupertinoIcons.eye_slash),
                    subtitle: Text(S.of(context).loading),
                    onTap: () => refreshSelf(),
                  ),
                ),
                OTNotificationSettingsTile(onSettingsUpdate: refreshSelf),
                Selector<SettingsProvider, bool>(
                    builder: (_, bool value, __) => SwitchListTile.adaptive(
                          title: Text(S.of(context).forum_show_banner),
                          secondary: const Icon(Icons.campaign),
                          subtitle:
                              Text(S.of(context).forum_show_banner_description),
                          value: value,
                          onChanged: (bool value) =>
                              SettingsProvider.getInstance().isBannerEnabled =
                                  value,
                        ),
                    selector: (_, model) => model.isBannerEnabled),
                Selector<SettingsProvider, bool>(
                    builder: (_, bool value, __) => SwitchListTile.adaptive(
                          title: Text(S.of(context).forum_clean_mode),
                          secondary: const Icon(Icons.ac_unit),
                          subtitle:
                              Text(S.of(context).forum_clean_mode_description),
                          value: value,
                          onChanged: (bool value) {
                            if (value) {
                              _showCleanModeGuideDialog();
                            }
                            SettingsProvider.getInstance().cleanMode = value;
                          },
                        ),
                    selector: (_, model) => model.cleanMode),
                if (SettingsProvider.getInstance().tagSuggestionAvailable) ...[
                  Selector<SettingsProvider, bool>(
                      builder: (_, bool value, __) => SwitchListTile.adaptive(
                          title: Text(S.of(context).recommended_tags),
                          secondary: const Icon(Icons.recommend),
                          subtitle:
                              Text(S.of(context).recommended_tags_availibity),
                          value: value,
                          onChanged: (bool value) async {
                            if (!value ||
                                await Noticing.showConfirmationDialog(
                                        context,
                                        S
                                            .of(context)
                                            .recommended_tags_description,
                                        title:
                                            S.of(context).recommended_tags) ==
                                    true) {
                              SettingsProvider.getInstance()
                                  .isTagSuggestionEnabled = value;
                            }
                          }),
                      selector: (_, model) => model.isTagSuggestionEnabled),
                ] else
                  ListTile(
                    title: Text(S.of(context).recommended_tags),
                    leading: const Icon(Icons.recommend),
                    subtitle: Text(S.of(context).unavailable),
                    onTap: () => Noticing.showModalNotice(context,
                        title: S.of(context).recommended_tags,
                        message: S.of(context).recommended_tags_description),
                  ),
                ListTile(
                  leading: Icon(PlatformIcons(context).tag),
                  title: Text(S.of(context).forum_hidden_tags),
                  subtitle: Text(S.of(context).forum_hidden_tags_description),
                  onTap: () async {
                    await smartNavigatorPush(context, '/bbs/tags/blocklist');
                    forumPageKey.currentState?.setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(PlatformIcons(context).photoLibrary),
                  title: Text(S.of(context).background_image),
                  subtitle: Text(S.of(context).background_image_description),
                  onTap: () async {
                    if (SettingsProvider.getInstance().backgroundImagePath ==
                        null) {
                      final ImagePickerProxy picker =
                          ImagePickerProxy.createPicker();
                      final String? image = await picker.pickImage();
                      if (image == null) return;
                      final String path =
                          (await getApplicationDocumentsDirectory()).path;
                      final File file = File(image);
                      final imagePath = '$path/background';
                      await file.copy(imagePath);
                      SettingsProvider.getInstance().backgroundImagePath =
                          imagePath;
                      forumPageKey.currentState?.setState(() {});
                    } else {
                      if (await Noticing.showConfirmationDialog(context,
                              S.of(context).background_image_already_set,
                              title: S.of(context).already_set) ==
                          true) {
                        final file = File(SettingsProvider.getInstance()
                            .backgroundImagePath!);
                        if (await file.exists()) {
                          await file.delete();
                          await FileImage(file).evict();
                        }
                        SettingsProvider.getInstance().backgroundImagePath =
                            null;
                        forumPageKey.currentState?.setState(() {});
                      }
                    }
                  },
                ),
                // Clear Cache
                ListTile(
                  leading: Icon(PlatformIcons(context).settings),
                  title: Text(S.of(context).clear_cache),
                  subtitle: Text(_clearCacheSubtitle ??
                      S.of(context).clear_cache_description),
                  onTap: () async {
                    await DefaultCacheManagerWithWebvpn().emptyCache();
                    setState(() {
                      _clearCacheSubtitle = S.of(context).cache_cleared;
                    });
                  },
                ),
                if (SettingsProvider.getInstance().debugMode)
                  ListTile(
                      leading: const Icon(Icons.speed),
                      title: const Text("Light Rendering"),
                      subtitle: const Text(
                          "[WARNING: DEBUG FEATURE] Disable Markdown Rendering"),
                      onTap: () {
                        SettingsProvider.getInstance()
                                .isMarkdownRenderingEnabled =
                            !SettingsProvider.getInstance()
                                .isMarkdownRenderingEnabled;
                      }),
                ListTile(
                  leading: nil,
                  title: Text(S.of(context).modify_password),
                  onTap: () => BrowserUtil.openUrl(
                      Constant.FORUM_FORGOT_PASSWORD_URL, context),
                ),
                ListTile(
                  leading: nil,
                  title: Text(S.of(context).list_my_posts),
                  onTap: () => smartNavigatorPush(context, '/bbs/discussions',
                      arguments: {'showFilterByMe': true},
                      forcePushOnMainNavigator: true),
                ),
                ListTile(
                  leading: nil,
                  title: Text(S.of(context).list_my_replies),
                  onTap: () => smartNavigatorPush(context, '/bbs/postDetail',
                      arguments: {'myReplies': true},
                      forcePushOnMainNavigator: true),
                ),
                ListTile(
                  leading: nil,
                  title: Text(S.of(context).list_view_history),
                  onTap: () => smartNavigatorPush(context, '/bbs/postDetail',
                      arguments: {'viewHistory': true},
                      forcePushOnMainNavigator: true),
                ),
                ListTile(
                  leading: nil,
                  title: Text(S.of(context).list_my_punishments),
                  onTap: () => smartNavigatorPush(context, "/bbs/postDetail",
                      arguments: {"punishmentHistory": true}),
                ),
              ],
              ListTile(
                leading: nil,
                title: context.read<ForumProvider>().isUserInitialized
                    ? Text(
                        S.of(context).logout,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      )
                    : Text(
                        S.of(context).login,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                onTap: () async {
                  if (!context.read<ForumProvider>().isUserInitialized) {
                    if (SettingsProvider.getInstance().forumToken == null) {
                      Noticing.showNotice(
                          context, S.of(context).login_from_forum_page,
                          title: S.of(context).login);
                    } else {
                      await ForumRepository.getInstance().initializeRepo();
                      onLogout();
                      refreshSelf();
                    }
                  } else if (await Noticing.showConfirmationDialog(
                          context, S.of(context).logout_forum,
                          title: S.of(context).logout,
                          isConfirmDestructive: true) ==
                      true) {
                    ProgressFuture progressDialog = showProgressDialog(
                        loadingText: S.of(context).logout, context: context);
                    try {
                      await ForumRepository.getInstance().logout();
                      while (auxiliaryNavigatorState?.canPop() == true) {
                        auxiliaryNavigatorState?.pop();
                      }
                      forumPageKey.currentState?.listViewController
                          .notifyUpdate();
                    } finally {
                      progressDialog.dismiss(showAnim: false);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const String CLEAN_MODE_EXAMPLE = '`差不多得了😅，自己不会去看看吗😇`';

  _showCleanModeGuideDialog() => showPlatformDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(S.of(context).forum_clean_mode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(context).forum_clean_mode_detail),
                const SizedBox(height: 8),
                Text(S.of(context).before_enabled),
                const SizedBox(height: 4),
                PostRenderWidget(
                  render: kMarkdownRender,
                  content: CLEAN_MODE_EXAMPLE,
                  hasBackgroundImage: false,
                ),
                const SizedBox(height: 8),
                Text(S.of(context).after_enabled),
                const SizedBox(height: 4),
                PostRenderWidget(
                  render: kMarkdownRender,
                  content: CleanModeFilter.cleanText(CLEAN_MODE_EXAMPLE),
                  hasBackgroundImage: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(S.of(context).i_see),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ));

  Card _buildAboutCard(BuildContext context) {
    final inAppReview = InAppReview.instance;
    final Color originalDividerColor = Theme.of(context).dividerColor;
    final double avatarSize =
        (ViewportUtils.getMainNavigatorWidth(context) - 120) / 8;
    final TextStyle? defaultText = Theme.of(context).textTheme.bodyMedium;
    final TextStyle linkText = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    final developersIcons = Constant.getDevelopers(context)
        .map((e) => ListTile(
              minLeadingWidth: 0,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          fit: BoxFit.fill, image: AssetImage(e.imageUrl)))),
              title: Text(e.name),
              //subtitle: Text(e.description),
              onTap: () => BrowserUtil.openUrl(e.url, context),
            ))
        .toList();
    return Card(
        child: ExpansionTileX(
            maintainState: true,
            leading: PlatformX.isMaterial(context)
                ? const Icon(Icons.info)
                : const Icon(CupertinoIcons.info_circle),
            title: Text(S.of(context).about),
            children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(25, 5, 25, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      //Description
                      Text(S.of(context).app_description_title,
                          textScaler: TextScaler.linear(1.1)),
                      Divider(
                        color: originalDividerColor,
                      ),
                      Text(S.of(context).app_description),
                      const SizedBox(height: 16),
                      //Terms and Conditions
                      Text(S.of(context).terms_and_conditions_title,
                          textScaler: TextScaler.linear(1.1)),
                      Divider(
                        color: originalDividerColor,
                      ),
                      Text.rich(TextSpan(children: [
                        TextSpan(
                          style: defaultText,
                          text: S.of(context).terms_and_conditions_content,
                        ),
                        TextSpan(
                            style: linkText,
                            text: S.of(context).privacy_policy,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => BrowserUtil.openUrl(
                                  S.of(context).privacy_policy_url, context)),
                        TextSpan(
                          style: defaultText,
                          text: S.of(context).terms_and_conditions_content_end,
                        ),
                        TextSpan(
                          style: defaultText,
                          text: S.of(context).view_ossl,
                        ),
                        TextSpan(
                            style: linkText,
                            text: S.of(context).open_source_software_licenses,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => smartNavigatorPush(
                                  context, "/about/openLicense",
                                  arguments: {"items": _LICENSE_ITEMS})),
                      ])),
                      const SizedBox(height: 16),
                      //Acknowledgement
                      Text(S.of(context).acknowledgements,
                          textScaler: TextScaler.linear(1.1)),
                      Divider(color: originalDividerColor),
                      PostRenderWidget(
                        render: kMarkdownRenderFactory(null),
                        content: S.of(context).acknowledgements_markdown,
                        hasBackgroundImage: false,
                        onTapLink: (url) => BrowserUtil.openUrl(url!, null),
                      ),

                      const SizedBox(height: 16),

                      // Authors
                      Text(S.of(context).authors,
                          textScaler: TextScaler.linear(1.1)),
                      Divider(color: originalDividerColor),
                      const SizedBox(height: 4),
                      LayoutGrid(
                        columnSizes: [1.fr, 1.fr],
                        rowSizes: List.filled(
                            (developersIcons.length + 1) ~/ 2, auto),
                        children: developersIcons,
                      ),
                      const SizedBox(height: 16),
                      //Version
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${S.of(context).version} ${FlutterApp.versionName} build ${Pubspec.version.build.single} #${const String.fromEnvironment("GIT_HASH", defaultValue: "?")}',
                          textScaler: const TextScaler.linear(0.7),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            S.of(context).author_descriptor,
                            textScaler: TextScaler.linear(0.7),
                            textAlign: TextAlign.right,
                          )
                        ],
                      ),
                    ]),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    FutureBuilder<bool>(
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasError || snapshot.data == false) {
                          return nil;
                        }
                        return TextButton(
                          child: Text(S.of(context).rate),
                          onPressed: () {
                            inAppReview.openStoreListing(
                              appStoreId: Constant.APPSTORE_APPID,
                            );
                          },
                        );
                      },
                      future: inAppReview.isAvailable(),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      child: Text(S.of(context).contact_us),
                      onPressed: () async {
                        bool? sendEmail = await Noticing.showConfirmationDialog(
                            context,
                            S
                                .of(context)
                                .our_email_is(S.of(context).feedback_email),
                            confirmText: S.of(context).send_email,
                            cancelText: S.of(context).i_see,
                            title: S.of(context).contact_us);
                        if (sendEmail == true && mounted) {
                          final Email email = Email(
                            body: '',
                            subject: S.of(context).app_feedback,
                            recipients: [S.of(context).feedback_email],
                            isHTML: false,
                          );
                          await FlutterEmailSender.send(email);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      child: Text(S.of(context).project_page),
                      onPressed: () {
                        BrowserUtil.openUrl(S.of(context).project_url, context);
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      child: Text(S.of(context).diagnostic_information),
                      onPressed: () {
                        smartNavigatorPush(context, "/diagnose");
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ]));
  }
}

class Developer {
  final String name;
  final String imageUrl;
  final String description;
  final String url;

  const Developer(this.name, this.imageUrl, this.url, this.description);
}

class OTNotificationSettingsWidget extends StatefulWidget {
  const OTNotificationSettingsWidget({super.key});

  @override
  State<OTNotificationSettingsWidget> createState() =>
      _OTNotificationSettingsWidgetState();
}

class _OTNotificationSettingsWidgetState
    extends State<OTNotificationSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _buildNotificationSettingsList(context),
    );
  }

  List<Widget> _buildNotificationSettingsList(BuildContext context) {
    List<Widget> list = [];
    if (context.read<ForumProvider>().userInfo?.config?.notify == null) {
      return [Text(S.of(context).fatal_error)];
    }
    getNotifyListNonNull() =>
        context.read<ForumProvider>().userInfo!.config!.notify!;
    for (var value in OTNotificationTypes.values) {
      list.add(SwitchListTile.adaptive(
          title: Text(value.displayTitle(context) ?? "null"),
          value: getNotifyListNonNull().contains(value.internalString()),
          onChanged: (newValue) {
            if (newValue == true &&
                !getNotifyListNonNull().contains(value.internalString())) {
              getNotifyListNonNull().add(value.internalString());
              updateOTUserProfile(context);
            } else if (newValue == false &&
                getNotifyListNonNull().contains(value.internalString())) {
              getNotifyListNonNull().remove(value.internalString());
              updateOTUserProfile(context);
            }
            refreshSelf();
          }));
    }
    return list;
  }
}

class OTNotificationSettingsTile extends StatelessWidget {
  final void Function() onSettingsUpdate;

  const OTNotificationSettingsTile({super.key, required this.onSettingsUpdate});

  String _generateNotificationSettingsSummary(
      BuildContext context, List<String>? data) {
    List<String> summary = [];
    data?.forEach((element) {
      final text = notificationTypeFromInternalString(element)
          ?.displayShortTitle(context);
      if (text == null) return;
      summary.add(text);
    });
    return summary.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final icon = PlatformX.isMaterial(context)
        ? const Icon(Icons.notifications)
        : const Icon(CupertinoIcons.bell);

    if (PlatformX.isApplePlatform || PlatformX.isAndroid) {
      final loadingBuilder = ListTile(
          title: Text(S.of(context).notification_settings),
          leading: icon,
          subtitle: Text(S.of(context).loading),
          onTap: onSettingsUpdate);
      final errorBuilder = ListTile(
          title: Text(S.of(context).notification_settings),
          leading: icon,
          subtitle: Text(S.of(context).fatal_error),
          onTap: onSettingsUpdate);
      return FutureWidget<bool>(
          future: Permission.notification.isGranted,
          successBuilder:
              (BuildContext context, AsyncSnapshot<bool> permissionSnapshot) {
            if (permissionSnapshot.data == true) {
              if (!context.read<ForumProvider>().isUserInitialized) {
                return ListTile(
                  title: Text(S.of(context).notification_settings),
                  leading: icon,
                  subtitle: Text(S.of(context).not_logged_in),
                  onTap: onSettingsUpdate,
                );
              }
              return FutureWidget<OTUser?>(
                future: ForumRepository.getInstance().getUserProfile(),
                successBuilder:
                    (BuildContext context, AsyncSnapshot<OTUser?> snapshot) =>
                        ListTile(
                  title: Text(S.of(context).notification_settings),
                  leading: icon,
                  subtitle: Text(_generateNotificationSettingsSummary(
                      context, snapshot.data?.config?.notify)),
                  onTap: () {
                    showPlatformModalSheet(
                      context: context,
                      builder: (BuildContext context) {
                        const Widget body = Padding(
                            padding: EdgeInsets.all(16.0),
                            child: OTNotificationSettingsWidget());
                        return PlatformX.isCupertino(context)
                            ? const SafeArea(child: Card(child: body))
                            : const SafeArea(child: body);
                      },
                    ).then((value) => onSettingsUpdate());
                  },
                ),
                errorBuilder: errorBuilder,
                loadingBuilder: loadingBuilder,
              );
            } else {
              return ListTile(
                  title: Text(S.of(context).notification_settings),
                  leading: icon,
                  subtitle: Text(S.of(context).unauthorized),
                  onTap: () {
                    Permission.notification.request().then((value) {
                      if (value.isGranted) {
                        onSettingsUpdate();
                      }
                    });
                  });
            }
          },
          errorBuilder: errorBuilder,
          loadingBuilder: loadingBuilder);
    } else {
      return ListTile(
          title: Text(S.of(context).notification_settings),
          leading: icon,
          subtitle: Text(S.of(context).unsupported),
          enabled: false);
    }
  }
}
