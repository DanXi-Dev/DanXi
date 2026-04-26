# HarmonyOS Build Guide

This repository builds HarmonyOS from a dedicated OpenHarmony Flutter 3.35 lane. The flow is:

1. build Flutter HAR artifacts with the OHOS Flutter fork
2. build the ArkUI host HAP in `Harmony/`
3. optionally install and launch the built app on a connected device

## Toolchain

- Flutter OHOS SDK: `https://gitcode.com/openharmony-tpc/flutter_flutter.git`
- Branch: `oh-3.35.7-release`
- Verified SDK line: Flutter OHOS `3.35.8-ohos-0.0.3`, Dart `3.9.2`
- DevEco Studio command line tools with `ohpm` and `hvigorw`
- JDK 17
- `hdc` for install / launch / screenshot workflow

The scripts default to:

```powershell
$env:DANXI_OHOS_FLUTTER_ROOT = "$env:LOCALAPPDATA\DanXi\flutter_flutter-oh-3.35.7-release"
```

If you keep the SDK elsewhere, point the env var to that checkout before building.

## Environment

The build scripts set these defaults for the current process when missing:

```powershell
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:FLUTTER_OHOS_STORAGE_BASE_URL = "https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
```

Make sure these commands work first:

```powershell
ohpm --version
hvigorw --version
hdc --version
java -version
```

`java -version` must be JDK 17.

## One-Command Build

Build the Flutter HARs and the Harmony HAP:

```powershell
.\build_ohos.ps1 -BuildMode debug -SkipFlutterSdkUpdate
```

Release build:

```powershell
.\build_ohos.ps1 -BuildMode release -SkipFlutterSdkUpdate
```

Using `-SkipFlutterSdkUpdate` keeps the local OHOS Flutter SDK fixed at your current checkout state, which is recommended for reproducible builds across CI and local runs.

Useful switches:

```powershell
.\build_ohos.ps1 -BuildMode debug -SkipHar
.\build_ohos.ps1 -BuildMode debug -SkipFlutterSdkUpdate
.\build_ohos.ps1 -BuildMode debug -FlutterSdkPath "D:\tools\flutter_flutter-oh-3.35.7-release"
```

## HAR Build Details

The HAR builder does the following:

1. clones or updates the OHOS Flutter SDK
2. activates `pubspec_overrides.ohos.yaml` as the temporary root override file
3. injects Flutter module metadata required by `flutter build har`
4. runs:

```powershell
flutter pub get
dart run intl_utils:generate
flutter build har --debug
```

5. syncs local OHOS plugin SDK HAR dependencies into `.vendor_ohos/*/ohos/libs/`
6. repacks `danxi_flutter_module.har` with missing Flutter debug assets
7. overlays repository `assets/` into the packaged `flutter_assets/assets/` tree so static icons, fonts, and graphics are present in the final HAR
8. writes final outputs to:

```text
har/danxi_flutter.har
har/danxi_flutter_module.har
har/danxi_harmony_entry-default-signed.hap
har/plugins/flutter_native_arm64_v8a.har
har/plugins/flutter_native_x86_64.har
har/plugins/*.har
```

## Install And Launch

After building, install and launch the latest signed HAP:

```powershell
.\run_ohos.ps1
```

Install only:

```powershell
.\run_ohos.ps1 -InstallOnly
```

Skip reinstall and only relaunch:

```powershell
.\run_ohos.ps1 -SkipInstall
```

## Outputs

- HARs: `har/`
- Harmony HAP: `Harmony/entry/build/default/outputs/default/entry-default-signed.hap`

## OHOS-Specific Notes

- `pubspec_overrides.ohos.yaml` is the single place for Harmony dependency overrides and pins.
- `build_har_from_override.ps1` is an internal helper. `build_ohos.ps1` is the public OHOS entry point.
- `build_har_from_override.ps1` intentionally tolerates the current OHOS Flutter toolchain printing:

```text
Oops! Failed to find ...\ohos\flutter_module...
```

  as long as the real module HAR was generated under `.ohos` and can be repacked correctly.
- `XSharedPreferences` uses a pure Dart file-backed fallback on OHOS so startup does not depend on unavailable `shared_preferences` plugin registration.
- Some icon families still need runtime visual verification on OHOS. The build now packages `assets/fonts/iconfont.ttf`, `assets/fonts/MaterialIcons-Regular.otf`, and the full `assets/graphics/` tree, so remaining gaps are more likely runtime rendering or usage-path issues than missing files in the archive.
- The current validation device is a HarmonyOS tablet, so layout and startup verification should always be done on a large-screen device before merging.

## PR Checklist

- `.\build_har_from_override.ps1 -BuildMode debug` succeeds.
- `.\build_ohos.ps1 -BuildMode debug` succeeds.
- `.\run_ohos.ps1` installs and launches the app on a connected device.
- `ohos/` shell-project sources are committed (excluding local caches and tool folders via `ohos/.gitignore`).
- Final signed HAP binary `har/danxi_harmony_entry-default-signed.hap` is updated when releasing a new OHOS build.
- Static assets in `assets/graphics/` and `assets/fonts/` are present in `har/danxi_flutter_module.har`.
- No local SDK paths, signing credentials, `.ohos/`, `Harmony/oh_modules/`, or scratch files are committed.
