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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DiagnosticConsole extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const DiagnosticConsole({Key? key, this.arguments}) : super(key: key);

  @override
  _DiagnosticConsoleState createState() => _DiagnosticConsoleState();
}

class _DiagnosticConsoleState extends State<DiagnosticConsole> {
  final StringBufferNotifier _console = StringBufferNotifier();

  @override
  void initState() {
    super.initState();
    diagnoseFDUHole();
  }

  Future<void> diagnoseFDUHole() async {
    _console.writeln(
        "FDUHole is user initialized: ${OpenTreeHoleRepository.getInstance().isUserInitialized}");
    _console.writeln(
        "FDUHole is user admin: ${OpenTreeHoleRepository.getInstance().isAdmin}");
    _console.writeln(
        "FDUHole Push Token last uploaded on this device: ${OpenTreeHoleRepository.getInstance().lastUploadToken}");
    _console.writeln(
        "FDUHole Token stored: ${context.read<SettingsProvider>().fduholeToken}");

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

  @override
  Widget build(BuildContext context) => PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar:
            PlatformAppBarX(title: Text(S.of(context).diagnostic_information)),
        body: WithScrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            primary: true,
            child: ChangeNotifierProvider.value(
                value: _console,
                child: Consumer<StringBufferNotifier>(
                    builder: (context, value, child) =>
                        Text(value.toString()))),
          ),
          controller: PrimaryScrollController.of(context),
        ),
      );
}

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
  String toString() => _buffer.toString();
}
