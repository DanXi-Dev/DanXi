// ignore_for_file: avoid_print

/*
 *     Copyright (C) 2024  DanXi-Dev
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

import 'package:archive/archive_io.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  if (arguments.isEmpty ||
      !['android', 'windows', 'aab'].contains(arguments[0])) {
    print('A valid target is required: android, windows, aab');
    exit(1);
  }

  print('Warning: Before building task, ensure that you have uncommented');
  print(
      'the line "signingConfig signingConfigs.release" in android/app/build.gradle,');
  print('and choose your signing key in android/key.properties.');

  String? versionCode;
  if (arguments.length > 1) {
    versionCode = arguments[1];
    print('Version code: $versionCode');
  } else {
    print('Please enter the version code:');
    versionCode = stdin.readLineSync();
  }

  String gitHash;
  if (await GitDir.isGitDir(p.current)) {
    final gitDir = await GitDir.fromExisting(p.current);
    final head = await gitDir.currentBranch();
    gitHash = head.sha.substring(0, 7);
  } else {
    print(
        'This script must be run in a directory containing a git repository.');
    exit(1);
  }

  print('Start building...');

  print('Run build_runner...');
  await runDartProcess(
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);

  switch (arguments[0]) {
    case 'android':
      await buildAndroid(versionCode, gitHash);
      break;
    case 'windows':
      await buildWindows(versionCode, gitHash);
      break;
    case 'aab':
      await buildAppBundle(versionCode, gitHash);
      break;
  }
}

Future<int> runFlutterProcess(List<String> args) async {
  final buildProcess = await Process.start('flutter', args, runInShell: true);
  stdout.addStream(buildProcess.stdout);
  stderr.addStream(buildProcess.stderr);
  return await buildProcess.exitCode;
}

Future<int> runDartProcess(List<String> args) async {
  final buildProcess = await Process.start('dart', args, runInShell: true);
  stdout.addStream(buildProcess.stdout);
  stderr.addStream(buildProcess.stderr);
  return await buildProcess.exitCode;
}

Future<void> buildAndroid(String? versionCode, String gitHash) async {
  print('Build for Android...');
  await runFlutterProcess([
    'build',
    'apk',
    '--release',
    '--dart-define=GIT_HASH=$gitHash',
  ]);

  print('Clean old files...');
  File oldFile = File('build/app/DanXi-$versionCode-release.android.apk');
  if (oldFile.existsSync()) {
    oldFile.deleteSync();
  }
  print('Copy file...');
  File newFile = File('build/app/DanXi-$versionCode-release.android.apk');
  File sourceFile = File('build/app/outputs/flutter-apk/app-release.apk');
  sourceFile.copySync(newFile.path);
  print('Build success.');
}

Future<void> buildWindows(String? versionCode, String gitHash) async {
  print('Build for Windows...');
  await runFlutterProcess([
    'build',
    'windows',
    '--release',
    '--dart-define=GIT_HASH=$gitHash',
  ]);

  print('Clean old files...');
  File oldFile = File('build/app/DanXi-$versionCode-release.windows-x64.zip');
  if (oldFile.existsSync()) {
    oldFile.deleteSync();
  }
  print('Compress file...');
  var encoder = ZipFileEncoder();
  File newFile = File('build/app/DanXi-$versionCode-release.windows-x64.zip');
  Directory sourceDir = Directory('build/windows/runner/Release');
  encoder.zipDirectory(sourceDir, filename: newFile.path);
  print('Build success.');
}

Future<void> buildAppBundle(String? versionCode, String gitHash) async {
  print('Build for App Bundle (Google Play Distribution)...');
  await runFlutterProcess([
    'build',
    'appbundle',
    '--release',
    '--dart-define=GIT_HASH=$gitHash',
  ]);

  print('Clean old files...');
  File oldFile = File('build/app/DanXi-$versionCode-release.android.aab');
  if (oldFile.existsSync()) {
    oldFile.deleteSync();
  }
  print('Copy file...');
  File newFile = File('build/app/DanXi-$versionCode-release.android.aab');
  File sourceFile = File('build/app/outputs/bundle/release/app-release.aab');
  sourceFile.copySync(newFile.path);
  print('Build success.');
}
