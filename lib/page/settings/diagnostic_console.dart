/*
 *     Copyright (C) 2022  DanXi-Dev
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dio5_log/bean/net_options.dart';
import 'package:dio5_log/dio_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    as inappwebview;
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:intl/intl.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class DiagnosticConsole extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const DiagnosticConsole({super.key, this.arguments});

  @override
  DiagnosticConsoleState createState() => DiagnosticConsoleState();
}

class DiagnosticConsoleState extends State<DiagnosticConsole> {
  final StringBufferNotifier _console = StringBufferNotifier();

  late List<DiagnosticMethod> diagnoses;

  @override
  void initState() {
    super.initState();
    diagnoses = [diagnoseForum, diagnoseGoogleAds, diagnoseDanXi, diagnoseUrl];
    unawaited(diagnose());
  }

  Future<void> diagnose() async {
    for (var method in diagnoses) {
      try {
        await method();
      } catch (e, st) {
        _console.writeln("Met error when diagnosing! Error is:$e");
        _console.writeln(st);
      } finally {
        _console.writeln("");
      }
    }
  }

  Future<void> diagnoseForum() async {
    _console.writeln(
        "Forum is user initialized: ${context.read<ForumProvider>().isUserInitialized}");
    _console.writeln(
        "Forum is user admin: ${ForumRepository.getInstance().isAdmin}");
    _console.writeln(
        "Forum Push Token last uploaded on this device: ${ForumRepository.getInstance().lastUploadToken}");
    _console.writeln(
        "Forum Token stored: ${context.read<SettingsProvider>().forumToken}");

    String? deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
    } catch (error, stackTrace) {
      _console.writeln("Met error when retrieving Device Id! Error is:$error");
      _console.writeln(stackTrace);
    }
    if (deviceId == null) {
      _console.writeln("Your Device Id(Random UUID): ${const Uuid().v4()}");
    } else {
      _console.writeln("Your Device Id(Real ID): $deviceId");
    }
  }

  Future<void> diagnoseGoogleAds() async {}

  static const _IGNORE_KEYS = ["password"];

  Future<void> diagnoseUrl() async {
    _console.writeln(
        "Base Auth URL: ${SettingsProvider.getInstance().authBaseUrl}");
    _console.writeln(
        "Forum Base URL: ${SettingsProvider.getInstance().forumBaseUrl}");
    _console.writeln(
        "Image Base URL: ${SettingsProvider.getInstance().imageBaseUrl}");
    _console.writeln(
        "Danke Base URL: ${SettingsProvider.getInstance().dankeBaseUrl}");
  }

  Future<void> diagnoseDanXi() async {
    _console.writeln(
        "User Agent used by Danta for UIS: ${UserAgentInterceptor.defaultUsedUserAgent}");
    _console.writeln("User Agent used by Danta for Forum: ${Constant.version}");
    _console.writeln("Media Query: ${MediaQuery.of(context)}");

    _console.writeln("Everything we stored in the local device:");
    var allKeys = await context.read<SettingsProvider>().preferences?.getKeys();
    if (allKeys != null) {
      for (var key in allKeys) {
        // Skip some keys
        if (_IGNORE_KEYS.contains(key)) continue;

        _console.writeln("Key: $key");
        _console.writeln(
            "Value: ${context.read<SettingsProvider>().preferences?.getString(key)}");
      }
    } else {
      _console.writeln("Nothing!");
    }
  }

  Future<void> exportLogArchive() async {
    String requestRepresentation(String key, NetOptions option) {
      StringBuffer sb = StringBuffer();
      sb.writeln(
          "=============================== REQUEST $key ===============================");
      sb.writeln("Id: $key");
      if (option.reqOptions != null) {
        sb.writeln("Request (ID ${option.reqOptions?.id}): ");
        sb.writeln("${option.reqOptions?.method} ${option.reqOptions?.url}");
        sb.writeln("Request Content-Type: ${option.reqOptions?.contentType}");
        sb.writeln("Request Time: ${option.reqOptions?.requestTime}");
        sb.writeln("Request Params: ${option.reqOptions?.params}");
        sb.writeln("Request Data:");
        sb.writeln(option.reqOptions?.data);
        sb.writeln("Request Headers:");
        for (final entry in (option.reqOptions?.headers ?? {})
            .entries
            .toList(growable: false)) {
          sb.writeln("${entry.key}=${entry.value}");
        }
      }

      if (option.resOptions != null) {
        sb.writeln("Response (ID ${option.resOptions?.id}): ");
        sb.writeln(
            "Response HTTP Status Code: ${option.resOptions?.statusCode}");
        sb.writeln("Response Time: ${option.resOptions?.responseTime}");
        sb.writeln("Response Headers:");
        for (final entry in (option.resOptions?.headers ?? {})
            .entries
            .toList(growable: false)) {
          sb.writeln("${entry.key}=${entry.value}");
        }
        sb.writeln("Response Data:");
        sb.writeln(option.resOptions?.data);
      }

      if (option.errOptions != null) {
        sb.writeln("Error occurred during request.");
        sb.writeln("Error (ID ${option.errOptions?.id}): ");
        sb.writeln(option.errOptions?.errorMsg);
      }
      sb.writeln(
          "=============================== END OF $key ===============================");
      sb.writeln();
      return sb.toString();
    }

    final confirm = await Noticing.showConfirmationDialog(context,
        S.of(context).export_log_confirmation);
    if (confirm != true || !mounted) return;
    final progDialog =
        showProgressDialog(context: context, loadingText: S.of(context).export_log_exporting);
    final Archive archive = Archive();
    StringBuffer sb = StringBuffer();
    try {
      final dioLogger = LogPoolManager.getInstance();
      for (final key in dioLogger.keys) {
        sb.writeln(requestRepresentation(key, dioLogger.logMap[key]!));
      }
      archive.add(ArchiveFile.string("dio_requests.log", sb.toString()));
    } catch (e, st) {
      archive.add(ArchiveFile.string("dio_requests.log", sb.toString()));
      archive.add(ArchiveFile.string("dio_requests.log.err",
          "Met error when exporting dio logs! Error is: $e\n$st"));
    }

    archive
        .add(ArchiveFile.string("diagnostic_console.log", _console.toString()));
    archive.comment = "Exported by DanXi App version ${Constant.version}";

    final dateFormat = DateFormat("yyyyMMdd_HHmmss");
    final fileName =
        "DanXi_Log_Archive_${dateFormat.format(DateTime.now().toUtc())}.zip";
    try {
      final zipData = ZipEncoder().encodeBytes(archive);
      if (PlatformX.isLinux) {
        // On Linux, share_plus does not support sharing files yet.
        // So we just write to a temporary file and show the path to user.
        final tempDir = await Directory.systemTemp.createTemp("danxi_log_");
        final tempFile = File("${tempDir.path}/$fileName");
        await tempFile.writeAsBytes(zipData);
        if (!mounted) return;
        await Noticing.showModalNotice(context,
            message: S.of(context).export_log_to_path(tempFile.path),
            selectable: true,
            title: S.of(context).export_log_success);
      } else {
        await SharePlus.instance.share(ShareParams(files: [
          XFile.fromData(zipData, mimeType: "application/zip", name: fileName),
        ]));
      }
    } catch (e, st) {
      if (!mounted) return;
      Noticing.showErrorDialog(context, e, trace: st);
    } finally {
      progDialog.dismiss(showAnim: false);
    }
  }

  Future<void> changePassword() async {
    if (!ForumRepository.getInstance().isAdmin) return;
    String? email = await Noticing.showInputDialog(context, "Input email");
    if (!mounted) return;
    String? password =
        await Noticing.showInputDialog(context, "Input password");
    if ((email ?? "").isEmpty || (password ?? "").isEmpty) return;

    int? result = await ForumRepository.getInstance()
        .adminChangePassword(email!, password!);
    if (result != null && result < 300 && mounted) {
      Noticing.showModalNotice(context,
          message: S.of(context).operation_successful);
    }
  }

  Future<void> changeHoleBaseUrl() async {
    String? forumBaseUrl = await Noticing.showInputDialog(context,
        "Input new base url (leave empty to reset to ${Constant.FORUM_BASE_URL})");
    if (forumBaseUrl == null || !mounted) return;
    if (forumBaseUrl.isEmpty) {
      SettingsProvider.getInstance().forumBaseUrl = Constant.FORUM_BASE_URL;
    } else {
      SettingsProvider.getInstance().forumBaseUrl = forumBaseUrl;
    }
    Noticing.showNotice(context, "Restart app to take effects");
  }

  Future<void> changeBaseAuthUrl() async {
    String? baseAuthUrl = await Noticing.showInputDialog(context,
        "Input new base auth url (leave empty to reset to ${Constant.AUTH_BASE_URL})");
    if (baseAuthUrl == null || !mounted) return;
    if (baseAuthUrl.isEmpty) {
      SettingsProvider.getInstance().authBaseUrl = Constant.AUTH_BASE_URL;
    } else {
      SettingsProvider.getInstance().authBaseUrl = baseAuthUrl;
    }
    Noticing.showNotice(context, "Restart app to take effects");
  }

  Future<void> changeImageBaseUrl() async {
    String? imageBaseUrl = await Noticing.showInputDialog(context,
        "Input new image base url (leave empty to reset to ${Constant.IMAGE_BASE_URL}))");
    if (imageBaseUrl == null || !mounted) return;
    if (imageBaseUrl.isEmpty) {
      SettingsProvider.getInstance().imageBaseUrl = Constant.IMAGE_BASE_URL;
    } else {
      SettingsProvider.getInstance().imageBaseUrl = imageBaseUrl;
    }
    Noticing.showNotice(context, "Restart app to take effects");
  }

  Future<void> changeDankeBaseUrl() async {
    String? dankeBaseUrl = await Noticing.showInputDialog(context,
        "Input new danke base url (leave empty to reset to ${Constant.DANKE_BASE_URL}))");
    if (dankeBaseUrl == null || !mounted) return;
    if (dankeBaseUrl.isEmpty) {
      SettingsProvider.getInstance().dankeBaseUrl = Constant.DANKE_BASE_URL;
    } else {
      SettingsProvider.getInstance().dankeBaseUrl = dankeBaseUrl;
    }
    Noticing.showNotice(context, "Restart app to take effects");
  }

  Future<void> sendMessage() async {
    if (!ForumRepository.getInstance().isAdmin) return;
    String? message = await Noticing.showInputDialog(context, "Input Message");
    if (!mounted) return;
    String? ids = await Noticing.showInputDialog(context, "Input Id List",
        hintText: "e.g. 123 or 123,456");
    if ((message ?? "").isEmpty || (ids ?? "").isEmpty) return;

    final idList = (jsonDecode("[$ids]") as List<dynamic>)
        .map<int>((e) => e as int)
        .toList(growable: false);
    int? result =
        await ForumRepository.getInstance().adminSendMessage(message!, idList);
    if (result != null && result < 300 && mounted) {
      Noticing.showModalNotice(context,
          message: S.of(context).operation_successful);
    }
  }

  Future<void> setUserAgent() async {
    String? ua = await Noticing.showInputDialog(context, "Input user agent");
    if (ua == null || !mounted) return;
    if (ua.isEmpty) {
      context.read<SettingsProvider>().customUserAgent = null;
    } else {
      context.read<SettingsProvider>().customUserAgent = ua;
    }
    Noticing.showNotice(context, "Restart app to take effects");
  }

  Future<void> deleteAllPushToken() async {
    try {
      final ret =
          await ForumRepository.getInstance().deleteAllPushNotificationToken();
      Noticing.showNotice(context, "Status code $ret");
    } catch (e) {
      Noticing.showNotice(context, "$e");
    }
  }

  @override
  Widget build(BuildContext context) => PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar:
            PlatformAppBarX(title: Text(S.of(context).diagnostic_information)),
        body: WithScrollbar(
          controller: PrimaryScrollController.of(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            primary: true,
            child: Column(
              children: [
                PlatformElevatedButton(
                  onPressed: exportLogArchive,
                  child: const Text("Export Log Archive"),
                ),
                PlatformElevatedButton(
                  onPressed: changePassword,
                  child: const Text("Password Change [Only ADMIN]"),
                ),
                PlatformElevatedButton(
                  onPressed: sendMessage,
                  child: const Text("Send Message [Only ADMIN]"),
                ),
                PlatformElevatedButton(
                  onPressed: setUserAgent,
                  child: const Text("Set User Agent"),
                ),
                PlatformElevatedButton(
                  onPressed: deleteAllPushToken,
                  child: const Text("Delete All Push Token"),
                ),
                PlatformElevatedButton(
                  child: const Text("Copy Everything"),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _console.toString()));
                    if (mounted) {
                      Noticing.showMaterialNotice(context, "Copied.");
                    }
                  },
                ),
                PlatformElevatedButton(
                  child: const Text("Clear Cookies"),
                  onPressed: () async {
                    await BaseRepositoryWithDio.clearAllCookies();
                    await FudanSession.clearSession();
                    await inappwebview.CookieManager.instance()
                        .deleteAllCookies();
                  },
                ),
                PlatformElevatedButton(
                  child: const Text("Set _BASE_URL"),
                  onPressed: () async {
                    await changeHoleBaseUrl();
                  },
                ),
                PlatformElevatedButton(
                  child: const Text("Set  _BASE_AUTH_URL"),
                  onPressed: () async {
                    await changeBaseAuthUrl();
                  },
                ),
                PlatformElevatedButton(
                  child: const Text("Set _IMAGE_BASE_URL"),
                  onPressed: () async {
                    await changeImageBaseUrl();
                  },
                ),
                PlatformElevatedButton(
                  child: const Text("Set _DANKE_BASE_URL"),
                  onPressed: () async {
                    await changeDankeBaseUrl();
                  },
                ),
                ChangeNotifierProvider.value(
                    value: _console,
                    child: Consumer<StringBufferNotifier>(
                        builder: (context, value, child) =>
                            SelectableText(value.toString()))),
              ],
            ),
          ),
        ),
      );
}

typedef DiagnosticMethod = Future<void> Function();

/// A mixin of [StringBuffer] with [ChangeNotifier].
class StringBufferNotifier with ChangeNotifier {
  final StringBuffer _buffer = StringBuffer();

  int get length => _buffer.length;

  /// Returns whether the buffer is empty. This is a constant-time operation.
  bool get isEmpty => length == 0;

  /// Returns whether the buffer is not empty. This is a constant-time
  /// operation.
  bool get isNotEmpty => !isEmpty;

  /// Adds the string representation of [object] to the buffer.
  void write(Object? object) {
    _buffer.write(object);
    notifyListeners();
  }

  /// Adds the string representation of [charCode] to the buffer.
  ///
  /// Equivalent to `write(String.fromCharCode(charCode))`.
  void writeCharCode(int charCode) {
    _buffer.writeCharCode(charCode);
    notifyListeners();
  }

  /// Writes all [objects] separated by [separator].
  ///
  /// Writes each individual object in [objects] in iteration order,
  /// and writes [separator] between any two objects.
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _buffer.writeAll(objects, separator);
    notifyListeners();
  }

  void writeln([Object? obj = ""]) {
    _buffer.writeln(obj);
    notifyListeners();
  }

  /// Clears the string buffer.
  void clear() {
    _buffer.clear();
    notifyListeners();
  }

  /// Returns the contents of buffer as a single string.
  @override
  String toString() => _buffer.toString();
}
