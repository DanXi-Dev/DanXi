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
import 'package:dan_xi/common/pubspec.yaml.g.dart' as pubspec;
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/user.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/settings/open_source_license.dart';
import 'package:dan_xi/provider/ad_manager.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/clean_mode_filter.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/util/win32/auto_start.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/image_picker_proxy.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dan_xi/widget/opentreehole/post_render.dart';
import 'package:dan_xi/widget/opentreehole/render/render_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateOTUserProfile(BuildContext context) async {
  try {
    await OpenTreeHoleRepository.getInstance().updateUserProfile();
  } catch (e, st) {
    Noticing.showModalError(context, e, trace: st);
  }
}

class SettingsSubpage extends PlatformSubpage<SettingsSubpage> {
  @override
  _SettingsSubpageState createState() => _SettingsSubpageState();

  const SettingsSubpage({Key? key}) : super(key: key);

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).settings);
}

class _SettingsSubpageState extends PlatformSubpageState<SettingsSubpage> {
  /// All open-source license for the app.
  static const List<LicenseItem> _LICENSE_ITEMS = [
    LicenseItem("asn1lib", LICENSE_BSD, "https://github.com/wstrange/asn1lib"),
    LicenseItem("cached_network_image", LICENSE_MIT,
        "https://github.com/Baseflow/flutter_cached_network_image"),
    LicenseItem(
        "system_tray", LICENSE_MIT, "https://github.com/antler119/system_tray"),
    LicenseItem(
        "win32", LICENSE_BSD_3_0_CLAUSE, "https://github.com/timsneath/win32"),
    LicenseItem("collection", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/dart-lang/collection"),
    LicenseItem(
        "meta", LICENSE_BSD_3_0_CLAUSE, "https://github.com/dart-lang/sdk"),
    LicenseItem("bitsdojo_window", LICENSE_MIT,
        "https://github.com/bitsdojo/bitsdojo_window"),
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
    // LicenseItem("google_mobile_ads", LICENSE_APACHE_2_0,
    //     "https://github.com/googleads/googleads-mobile-flutter"),
    LicenseItem("auto_size_text", LICENSE_MIT,
        "https://github.com/leisim/auto_size_text"),
    LicenseItem("beautiful_soup_dart", LICENSE_MIT,
        "https://github.com/mzdm/beautiful_soup"),
    LicenseItem("build_runner", LICENSE_BSD,
        "https://github.com/dart-lang/build/tree/master/build_runner"),
    LicenseItem(
        "catcher", LICENSE_APACHE_2_0, "https://github.com/jhomlala/catcher"),
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
    // LicenseItem("xiao_mi_push_plugin", LICENSE_APACHE_2_0,
    //     "https://github.com/w568w/FlutterXiaoMiPushPlugin"),
    LicenseItem("http", LICENSE_BSD, "https://github.com/dart-lang/http"),
    LicenseItem(
        "ical", LICENSE_BSD_3_0_CLAUSE, "https://github.com/dartclub/ical"),
    LicenseItem("platform_device_id", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/BestBurning/platform_device_id"),
    // LicenseItem("in_app_review", LICENSE_MIT,
    //     "https://github.com/britannio/in_app_review"),
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
    LicenseItem("lunar", LICENSE_MIT, "https://github.com/6tail/lunar-flutter")
  ];
  BannerAd? myBanner;

  @override
  void initState() {
    super.initState();
    myBanner = AdManager.loadBannerAd(3); // 3 for settings page
  }

  String? _clearCacheSubtitle;

  Future<void> _deleteAllDataAndExit() async {
    ProgressFuture progressDialog =
        showProgressDialog(loadingText: S.of(context).logout, context: context);
    try {
      await OpenTreeHoleRepository.getInstance().logout();
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    _preferences.clear().then((value) => FlutterApp.restartApp(context));
  }

  List<Widget> _buildCampusAreaList(BuildContext menuContext) {
    List<Widget> list = [];
    onTapListener(Campus campus) {
      SettingsProvider.getInstance().campus = campus;
      dashboardPageKey.currentState?.rebuildFeatures();
      dashboardPageKey.currentState?.setState(() {});
      refreshSelf();
    }

    for (var value in Constant.CAMPUS_VALUES) {
      list.add(PlatformContextMenuItem(
        menuContext: menuContext,
        child: Text(value.displayTitle(menuContext)!),
        onPressed: () => onTapListener(value),
      ));
    }
    return list;
  }

  List<Widget> _buildFoldBehaviorList(BuildContext menuContext) {
    List<Widget> list = [];
    void onTapListener(FoldBehavior value) {
      OpenTreeHoleRepository.getInstance().userInfo!.config!.show_folded =
          value.internalString();
      updateOTUserProfile(context);
      treeholePageKey.currentState?.setState(() {});
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
            child: Material(
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    AutoBannerAdWidget(bannerAd: myBanner),
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
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                  PlatformDialogAction(
                                      child: Text(
                                        S.of(context).i_see,
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).errorColor),
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
                              .displayTitle(context)!),
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

                        // Timetable Start date
                        /*
                        ListTile(
                          title: Text(S.of(context).semester_start_date),
                          leading: PlatformX.isMaterial(context)
                              ? const Icon(Icons.calendar_today)
                              : const Icon(CupertinoIcons.calendar_badge_plus),
                          subtitle: Text(DateFormat("yyyy-MM-dd")
                              .format(TimeTable.defaultStartTime)),
                          onTap: () async {
                            DateTime? newDate = await showPlatformDatePicker(
                                context: context,
                                initialDate: TimeTable.defaultStartTime,
                                firstDate:
                                    DateTime.fromMillisecondsSinceEpoch(0),
                                lastDate: TimeTable.defaultStartTime
                                    .add(const Duration(days: 365 * 100)));
                            if (newDate != null) {
                              setState(() {
                                TimeTable.defaultStartTime = newDate;
                                SettingsProvider.getInstance()
                                        .lastSemesterStartTime =
                                    TimeTable.defaultStartTime
                                        .toIso8601String();
                              });
                            }
                          },
                        ),*/
                      ]),
                    ),

                    // Accessibility
                    Card(
                      child: SwitchListTile.adaptive(
                        title: Text(S.of(context).accessibility_coloring),
                        subtitle:
                            Text(S.of(context).high_contrast_color_description),
                        secondary: const Icon(Icons.accessibility_new_rounded),
                        value: SettingsProvider.getInstance()
                            .useAccessibilityColoring,
                        onChanged: (bool value) {
                          setState(() => SettingsProvider.getInstance()
                              .useAccessibilityColoring = value);
                          treeholePageKey.currentState?.setState(() {});
                        },
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
                    _buildFDUHoleSettingsCard(context),
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
                  ]),
            )));
  }

  Widget _buildFDUHoleSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ExpansionTileX(
            leading: Icon(PlatformIcons(context).accountCircle),
            title: Text(S.of(context).forum),
            subtitle: Text(
                OpenTreeHoleRepository.getInstance().isUserInitialized
                    ? S.of(context).fduhole_user_id(
                        (OpenTreeHoleRepository.getInstance().userInfo?.user_id)
                            .toString())
                    : S.of(context).not_logged_in),
            children: [
              if (OpenTreeHoleRepository.getInstance().isUserInitialized) ...[
                FutureWidget<OTUser?>(
                  future: OpenTreeHoleRepository.getInstance().getUserProfile(),
                  successBuilder:
                      (BuildContext context, AsyncSnapshot<OTUser?> snapshot) =>
                          ListTile(
                    title: Text(S.of(context).fduhole_nsfw_behavior),
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
                    title: Text(S.of(context).fduhole_nsfw_behavior),
                    leading: PlatformX.isMaterial(context)
                        ? const Icon(Icons.hide_image)
                        : const Icon(CupertinoIcons.eye_slash),
                    subtitle: Text(S.of(context).fatal_error),
                    onTap: () => refreshSelf(),
                  ),
                  loadingBuilder: ListTile(
                    title: Text(S.of(context).fduhole_nsfw_behavior),
                    leading: PlatformX.isMaterial(context)
                        ? const Icon(Icons.hide_image)
                        : const Icon(CupertinoIcons.eye_slash),
                    subtitle: Text(S.of(context).loading),
                    onTap: () => refreshSelf(),
                  ),
                ),
                OTNotificationSettingsTile(
                  parentSetStateFunction: refreshSelf,
                ),
                SwitchListTile.adaptive(
                  title: Text(S.of(context).fduhole_clean_mode),
                  secondary: const Icon(Icons.ac_unit),
                  subtitle: Text(S.of(context).fduhole_clean_mode_description),
                  value: SettingsProvider.getInstance().cleanMode,
                  onChanged: (bool value) {
                    if (value) {
                      _showCleanModeGuideDialog();
                    }
                    setState(
                        () => SettingsProvider.getInstance().cleanMode = value);
                  },
                ),
                ListTile(
                  leading: Icon(PlatformIcons(context).tag),
                  title: Text(S.of(context).fduhole_hidden_tags),
                  subtitle: Text(S.of(context).fduhole_hidden_tags_description),
                  onTap: () async {
                    await smartNavigatorPush(context, '/bbs/tags/blocklist');
                    treeholePageKey.currentState?.setState(() {});
                  },
                ),
                ListTile(
                  leading: Icon(PlatformIcons(context).photoLibrary),
                  title: Text(S.of(context).background_image),
                  subtitle: Text(S.of(context).background_image_description),
                  onTap: () async {
                    if (SettingsProvider.getInstance().backgroundImagePath ==
                        null) {
                      final ImagePickerProxy _picker =
                          ImagePickerProxy.createPicker();
                      final String? _file = await _picker.pickImage();
                      if (_file == null) return;
                      final String path =
                          (await getApplicationDocumentsDirectory()).path;
                      final File file = File(_file);
                      final imagePath = '$path/background';
                      await file.copy(imagePath);
                      SettingsProvider.getInstance().backgroundImagePath =
                          imagePath;
                      treeholePageKey.currentState?.setState(() {});
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
                        treeholePageKey.currentState?.setState(() {});
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
                    await DefaultCacheManager().emptyCache();
                    setState(() {
                      _clearCacheSubtitle = S.of(context).cache_cleared;
                    });
                  },
                ),
                ListTile(
                  leading: const SizedBox(),
                  title: Text(S.of(context).modify_password),
                  onTap: () => BrowserUtil.openUrl(
                      Constant.OPEN_TREEHOLE_FORGOT_PASSWORD_URL, context),
                ),
              ],
              ListTile(
                leading: const SizedBox(),
                title: OpenTreeHoleRepository.getInstance().isUserInitialized
                    ? Text(
                        S.of(context).logout,
                        style: TextStyle(color: Theme.of(context).errorColor),
                      )
                    : Text(
                        S.of(context).login,
                        style:
                            TextStyle(color: Theme.of(context).indicatorColor),
                      ),
                onTap: () async {
                  if (!OpenTreeHoleRepository.getInstance().isUserInitialized) {
                    if (SettingsProvider.getInstance().fduholeToken == null) {
                      Noticing.showNotice(
                          context, S.of(context).login_from_treehole_page,
                          title: S.of(context).login);
                    }
                    await OpenTreeHoleRepository.getInstance().initializeRepo();
                    treeholePageKey.currentState?.setState(() {});
                    refreshSelf();
                  } else if (await Noticing.showConfirmationDialog(
                          context, S.of(context).logout_fduhole,
                          title: S.of(context).logout,
                          isConfirmDestructive: true) ==
                      true) {
                    ProgressFuture progressDialog = showProgressDialog(
                        loadingText: S.of(context).logout, context: context);
                    try {
                      await OpenTreeHoleRepository.getInstance().logout();
                      while (auxiliaryNavigatorState?.canPop() == true) {
                        auxiliaryNavigatorState?.pop();
                      }
                      settingsPageKey.currentState?.setState(() {});
                      treeholePageKey.currentState?.listViewController
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

  void _toggleAdDisplay() {
    SettingsProvider.getInstance().isAdEnabled =
        !SettingsProvider.getInstance().isAdEnabled;
    dashboardPageKey.currentState?.setState(() {});
    treeholePageKey.currentState?.setState(() {});
    timetablePageKey.currentState?.setState(() {});
    setState(() {});
  }

  static const String CLEAN_MODE_EXAMPLE = '`差不多得了😅，自己不会去看看吗😇`';

  /*Future<bool?> _showAdsDialog() => showPlatformDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
            title: Text(S.of(context).sponsor_us),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(context).sponsor_us_detail),
              ],
            ),
            actions: [
              TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(S.of(context).i_see),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ));*/

  _showAdsThankDialog() {
    Noticing.showNotice(context, S.of(context).thankyouforenablingads,
        title: "", useSnackBar: false);
  }

  _showCleanModeGuideDialog() => showPlatformDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(S.of(context).fduhole_clean_mode),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.of(context).fduhole_clean_mode_detail),
                const SizedBox(
                  height: 8,
                ),
                Text(S.of(context).before_enabled),
                const SizedBox(
                  height: 4,
                ),
                PostRenderWidget(
                  render: kMarkdownRender,
                  content: CLEAN_MODE_EXAMPLE,
                  hasBackgroundImage: false,
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(S.of(context).after_enabled),
                const SizedBox(
                  height: 4,
                ),
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
    // final inAppReview = InAppReview.instance;
    final Color _originalDividerColor = Theme.of(context).dividerColor;
    final double _avatarSize =
        (ViewportUtils.getMainNavigatorWidth(context) - 120) / 8;
    final TextStyle? defaultText = Theme.of(context).textTheme.bodyText2;
    final TextStyle linkText = Theme.of(context)
        .textTheme
        .bodyText2!
        .copyWith(color: Theme.of(context).colorScheme.secondary);

    final developersIcons = Constant.getDevelopers(context)
        .map((e) => ListTile(
              minLeadingWidth: 0,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                  width: _avatarSize,
                  height: _avatarSize,
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
                      Text(
                        S.of(context).app_description_title,
                        textScaleFactor: 1.1,
                      ),
                      Divider(
                        color: _originalDividerColor,
                      ),
                      Text(S.of(context).app_description),
                      const SizedBox(
                        height: 16,
                      ),
                      //Terms and Conditions
                      Text(
                        S.of(context).terms_and_conditions_title,
                        textScaleFactor: 1.1,
                      ),
                      Divider(
                        color: _originalDividerColor,
                      ),
                      RichText(
                          text: TextSpan(children: [
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
                      const SizedBox(
                        height: 16,
                      ),
                      //Acknowledgement
                      Text(
                        S.of(context).acknowledgements,
                        textScaleFactor: 1.1,
                      ),
                      Divider(
                        color: _originalDividerColor,
                      ),
                      RichText(
                          text: TextSpan(children: [
                        TextSpan(
                          style: defaultText,
                          text: S.of(context).acknowledgements_1,
                        ),
                        TextSpan(
                            style: linkText,
                            text: S.of(context).acknowledgement_name_1,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => BrowserUtil.openUrl(
                                  S.of(context).acknowledgement_link_1,
                                  context)),
                        TextSpan(
                          style: defaultText,
                          text: S.of(context).acknowledgements_2,
                        ),
                      ])),

                      const SizedBox(
                        height: 16,
                      ),

                      // Authors
                      Text(
                        S.of(context).authors,
                        textScaleFactor: 1.1,
                      ),
                      Divider(
                        color: _originalDividerColor,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: developersIcons.sublist(
                                      0, (developersIcons.length + 1) ~/ 2)),
                            ),
                            Expanded(
                                child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: developersIcons
                                  .sublist((developersIcons.length + 1) ~/ 2),
                            )),
                          ]),
                      const SizedBox(height: 16),
                      //Version
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'FOSS ${S.of(context).version} ${pubspec.major}.${pubspec.minor}.${pubspec.patch} build ${pubspec.build.first}',
                          textScaleFactor: 0.7,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            S.of(context).author_descriptor,
                            textScaleFactor: 0.7,
                            textAlign: TextAlign.right,
                          )
                        ],
                      ),
                    ]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  // FutureBuilder<bool>(
                  //   builder:
                  //       (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  //     if (snapshot.hasError || snapshot.data == false) {
                  //       return const SizedBox();
                  //     }
                  //     return TextButton(
                  //       child: Text(S.of(context).rate),
                  //       onPressed: () {
                  //         inAppReview.openStoreListing(
                  //           appStoreId: Constant.APPSTORE_APPID,
                  //         );
                  //       },
                  //     );
                  //   },
                  //   future: inAppReview.isAvailable(),
                  // ),
                  // const SizedBox(width: 8),
                  TextButton(
                    child: Text(S.of(context).contact_us),
                    onPressed: () async {
                      final Email email = Email(
                        body: '',
                        subject: S.of(context).app_feedback,
                        recipients: [S.of(context).feedback_email],
                        isHTML: false,
                      );
                      await FlutterEmailSender.send(email);
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
                ],
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
  const OTNotificationSettingsWidget({Key? key}) : super(key: key);

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
    if (OpenTreeHoleRepository.getInstance().userInfo?.config?.notify == null) {
      return [Text(S.of(context).fatal_error)];
    }
    getNotifyListNonNull() =>
        OpenTreeHoleRepository.getInstance().userInfo!.config!.notify!;
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
  final Function parentSetStateFunction;

  const OTNotificationSettingsTile(
      {Key? key, required this.parentSetStateFunction})
      : super(key: key);

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
    // if (PlatformX.isApplePlatform || PlatformX.isAndroid) {
    //   final loadingBuilder = ListTile(
    //       title: Text(S.of(context).notification_settings),
    //       leading: PlatformX.isMaterial(context)
    //           ? const Icon(Icons.notifications)
    //           : const Icon(CupertinoIcons.bell),
    //       subtitle: Text(S.of(context).loading),
    //       onTap: () => parentSetStateFunction());
    //   final errorBuilder = ListTile(
    //       title: Text(S.of(context).notification_settings),
    //       leading: PlatformX.isMaterial(context)
    //           ? const Icon(Icons.notifications)
    //           : const Icon(CupertinoIcons.bell),
    //       subtitle: Text(S.of(context).fatal_error),
    //       onTap: () => parentSetStateFunction());
    //   return FutureWidget<bool>(
    //       future: Permission.notification.isGranted,
    //       successBuilder:
    //           (BuildContext context, AsyncSnapshot<bool> permissionSnapshot) {
    //         if (permissionSnapshot.data == true) {
    //           if (!OpenTreeHoleRepository.getInstance().isUserInitialized) {
    //             return ListTile(
    //               title: Text(S.of(context).notification_settings),
    //               leading: PlatformX.isMaterial(context)
    //                   ? const Icon(Icons.notifications)
    //                   : const Icon(CupertinoIcons.bell),
    //               subtitle: Text(S.of(context).not_logged_in),
    //               onTap: () => parentSetStateFunction(),
    //             );
    //           }
    //
    //           return FutureWidget<OTUser?>(
    //             future: OpenTreeHoleRepository.getInstance().getUserProfile(),
    //             successBuilder:
    //                 (BuildContext context, AsyncSnapshot<OTUser?> snapshot) =>
    //                     ListTile(
    //               title: Text(S.of(context).notification_settings),
    //               leading: PlatformX.isMaterial(context)
    //                   ? const Icon(Icons.notifications)
    //                   : const Icon(CupertinoIcons.bell),
    //               subtitle: Text(_generateNotificationSettingsSummary(
    //                   context, snapshot.data?.config?.notify)),
    //               onTap: () {
    //                 showPlatformModalSheet(
    //                   context: context,
    //                   builder: (BuildContext context) {
    //                     const Widget body = Padding(
    //                         padding: EdgeInsets.all(16.0),
    //                         child: OTNotificationSettingsWidget());
    //                     if (PlatformX.isCupertino(context)) {
    //                       return const SafeArea(child: Card(child: body));
    //                     } else {
    //                       return const SafeArea(child: body);
    //                     }
    //                   },
    //                 ).then((value) => parentSetStateFunction());
    //               },
    //             ),
    //             errorBuilder: errorBuilder,
    //             loadingBuilder: loadingBuilder,
    //           );
    //         } else {
    //           return ListTile(
    //               title: Text(S.of(context).notification_settings),
    //               leading: PlatformX.isMaterial(context)
    //                   ? const Icon(Icons.notifications)
    //                   : const Icon(CupertinoIcons.bell),
    //               subtitle: Text(S.of(context).unauthorized),
    //               onTap: () {
    //                 parentSetStateFunction();
    //               });
    //         }
    //       },
    //       errorBuilder: errorBuilder,
    //       loadingBuilder: loadingBuilder);
    // } else {
    return ListTile(
        title: Text(S.of(context).notification_settings),
        leading: PlatformX.isMaterial(context)
            ? const Icon(Icons.notifications)
            : const Icon(CupertinoIcons.bell),
        subtitle: Text(S.of(context).unsupported),
        enabled: false);
    // }
  }
}
