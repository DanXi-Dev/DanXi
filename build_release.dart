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
import 'package:args/args.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as p;

String flutterExecutable = 'flutter';
String dartExecutable = 'dart';

void main(List<String> arguments) async {
  var parser = ArgParser()
    ..addOption("target",
        allowed: ['android', 'android-armv8', 'windows', 'aab', 'linux'],
        help: "The target to build for.",
        mandatory: true)
    ..addOption("versionCode",
        help:
            "The version code to use. If not provided, the user will be prompted.",
        mandatory: false)
    ..addOption("flutterPath",
        help: "The path to the flutter executable.",
        mandatory: false,
        defaultsTo: "flutter")
    ..addOption("dartPath",
        help: "The path to the dart executable.",
        mandatory: false,
        defaultsTo: "dart");
  final args = parser.parse(arguments);
  print('Warning: Before building task, ensure that you have uncommented');
  print(
      'the line "signingConfig signingConfigs.release" in android/app/build.gradle,');
  print('and choose your signing key in android/key.properties.');

  String? versionCode = args['versionCode'];
  flutterExecutable = args['flutterPath'];
  dartExecutable = args['dartPath'];

  if (versionCode != null) {
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
  await runFlutterProcess(
      ['pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs']);

  switch (args['target']) {
    case 'android':
      await buildAndroid(versionCode, gitHash);
      break;
    case 'android-armv8':
      await buildAndroid(versionCode, gitHash, target: 'android-arm64');
      break;
    case 'windows':
      await buildWindows(versionCode, gitHash);
      break;
    case 'aab':
      await buildAppBundle(versionCode, gitHash);
      break;
    case 'linux':
      await buildLinux(versionCode, gitHash);
      break;
  }
}

Future<int> runFlutterProcess(List<String> args) async {
  final buildProcess =
      await Process.start(flutterExecutable, args, runInShell: true);
  stdout.addStream(buildProcess.stdout);
  stderr.addStream(buildProcess.stderr);
  return await buildProcess.exitCode;
}

Future<int> runDartProcess(List<String> args) async {
  final buildProcess =
      await Process.start(dartExecutable, args, runInShell: true);
  stdout.addStream(buildProcess.stdout);
  stderr.addStream(buildProcess.stderr);
  return await buildProcess.exitCode;
}

Future<void> buildAndroid(String? versionCode, String gitHash,
    {String? target}) async {
  print('Build for Android...');
  await runFlutterProcess([
    'build',
    'apk',
    '--release',
    '--dart-define=GIT_HASH=$gitHash',
    if (target != null) '--target-platform=$target',
  ]);

  print('Clean old files...');
  String targetPath =
      'build/app/DanXi-$versionCode-${target != null ? "$target-" : ""}release.android.apk';
  File oldFile = File(targetPath);
  if (oldFile.existsSync()) {
    oldFile.deleteSync();
  }
  print('Copy file...');
  File newFile = File(targetPath);
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
  Directory sourceDir = Directory('build/windows/x64/runner/Release');
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

Future<void> buildLinux(String? versionCode, String gitHash) async {
  print('Build for Linux...');
  await runFlutterProcess([
    'build',
    'linux',
    '--release',
    '--dart-define=GIT_HASH=$gitHash',
  ]);

  print('Clean old files...');
  File oldFile = File('build/app/DanXi-$versionCode-release.linux-x64.zip');
  if (oldFile.existsSync()) {
    oldFile.deleteSync();
  }
  print('Compress file...');
  var encoder = ZipFileEncoder();
  File newFile = File('build/app/DanXi-$versionCode-release.linux-x64.zip');
  Directory sourceDir = Directory('build/linux/x64/release/bundle');
  encoder.zipDirectory(sourceDir, filename: newFile.path);
  print('Build success.');
}
