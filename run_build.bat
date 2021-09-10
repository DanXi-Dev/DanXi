@echo off
echo.
echo Warning: Before building task, ensure that you have uncommented
echo the line "signingConfig signingConfigs.release" in android/app/build.gradle,
echo and choose your signing key in android/key.properties.
echo.
set /P version_code=Input your version name to continue:
echo Start building...

:exec_build_runner
echo Executing build runner...
echo.
start /WAIT cmd /C flutter pub run build_runner build --delete-conflicting-outputs

:build_android
echo Build for Android...
echo.
echo Clean old files...
del /Q build\app\DanXi-%version_code%-release.android.apk
start /WAIT cmd /C flutter build apk
echo Move file...
move build\app\outputs\flutter-apk\app-release.apk build\app\DanXi-%version_code%-release.android.apk
echo.

:build_windows
echo Build for Windows...
echo.
start /WAIT cmd /C flutter build windows
echo Clean old files...
del /Q build\app\DanXi-%version_code%-release.windows-x64.zip
cd build\windows\runner\Release\
echo Move file...
7z a -r -sse ..\..\..\..\build\app\DanXi-%version_code%-release.windows-x64.zip *
cd ..\..\..\..\
echo.

:build_app_bundle
echo Build for App Bundle (Google Play Distribution)...
echo.
echo Ensure that you have choose your signing key in android/key.properties.
echo.
echo Press any key to continue.
pause
echo Clean old files...
del /Q build\app\DanXi-%version_code%-release.android.aab
start /WAIT cmd /C flutter build appbundle
echo Move file...
move build\app\outputs\bundle\release\app-release.aab build\app\DanXi-%version_code%-release.android.aab

:end_success
echo Build success.