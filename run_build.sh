#!/bin/bash

#
#     Copyright (C) 2024  DanXi-Dev
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

echo "Warning: Before building task, ensure that you have uncommented"
echo "the line \"signingConfig signingConfigs.release\" in android/app/build.gradle,"
echo "and choose your signing key in android/key.properties."
echo
read -p "Input your version name to continue: " version_code
echo "Start building..."

# get current hash
git_hash=$(git rev-parse --short HEAD)

ENV_FLAG="--dart-define=GIT_HASH=$git_hash"

exec_build_runner() {
    echo "Executing build runner..."
    dart run build_runner build --delete-conflicting-outputs
}

build_android() {
    echo "Build for Android..."
    echo "Clean old files..."
    rm -f build/app/DanXi-$version_code-release.android.apk
    flutter build apk --release $ENV_FLAG
    echo "Copy file..."
    cp build/app/outputs/flutter-apk/app-release.apk build/app/DanXi-$version_code-release.android.apk
    echo
}

build_windows() {
    echo "Build for Windows..."
    flutter build windows --release $ENV_FLAG
    echo "Clean old files..."
    rm -f build/app/DanXi-$version_code-release.windows-x64.zip
    pushd build/windows/runner/Release/
    echo "Copy file..."
    7z a -r -sse ../../../../build/app/DanXi-$version_code-release.windows-x64.zip *
    popd
    echo
}

build_bundle() {
    echo "Build for Android App Bundle..."
    echo "Clean old files..."
    rm -f build/app/DanXi-$version_code-release.android.aab
    flutter build appbundle --release $ENV_FLAG
    echo "Copy file..."
    cp build/app/outputs/bundle/release/app-release.aab build/app/DanXi-$version_code-release.android.aab
    echo
}

exec_build_runner

if [ "$1" == "android" ]; then
    build_android
elif [ "$1" == "windows" ]; then
    build_windows
elif [ "$1" == "aab" ]; then
    build_bundle
else
    build_android
    build_windows
    build_bundle
fi