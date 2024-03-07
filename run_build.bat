@echo off
setlocal enabledelayedexpansion

echo.
echo Warning: Before building task, ensure that you have uncommented
echo the line "signingConfig signingConfigs.release" in android/app/build.gradle,
echo and choose your signing key in android/key.properties.
echo.
if "%~2"=="" (
    set /p version_code=Input your version name to continue:
) else (
    set version_code=%~2
)
echo Start building...

for /f %%i in ('git rev-parse --short HEAD') do set GIT_HASH=%%i

:exec_build_runner
echo Executing build runner...
echo.
start /WAIT cmd /C dart run build_runner build --delete-conflicting-outputs

if "%~1"=="android" (
    goto build_android
) else if "%~1"=="windows" (
    goto build_windows
) else if "%~1"=="aab" (
    goto build_app_bundle
) else (
    printf "A valid target is required: android, windows, aab\n"
    exit /b 1
)

:build_android
echo Build for Android...
echo.
echo Clean old files...
del /Q build\app\DanXi-%version_code%-release.android.apk
start /WAIT cmd /C flutter build apk --release --dart-define=GIT_HASH=!GIT_HASH!
echo Copy file...
copy build\app\outputs\flutter-apk\app-release.apk build\app\DanXi-%version_code%-release.android.apk
echo.
goto end_success

:build_windows
echo Build for Windows...
echo.
start /WAIT cmd /C flutter build windows --release --dart-define=GIT_HASH=!GIT_HASH!
echo Clean old files...
del /Q build\app\DanXi-%version_code%-release.windows-x64.zip
cd build\windows\runner\Release\
echo Copy file...
7z a -r -sse ..\..\..\..\build\app\DanXi-%version_code%-release.windows-x64.zip *
cd ..\..\..\..\
echo.
goto end_success

:build_app_bundle
echo Build for App Bundle (Google Play Distribution)...
echo.
echo Clean old files...
del /Q build\app\DanXi-%version_code%-release.android.aab
start /WAIT cmd /C flutter build appbundle --release --dart-define=GIT_HASH=!GIT_HASH!
echo Copy file...
copy build\app\outputs\bundle\release\app-release.aab build\app\DanXi-%version_code%-release.android.aab
goto end_success

:end_success
echo Build success.
