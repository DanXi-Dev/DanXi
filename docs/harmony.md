# HarmonyOS Build Guide

This repository builds HarmonyOS from a dedicated OpenHarmony Flutter 3.35 lane. The flow is:

1. build Flutter HAR artifacts with the OHOS Flutter fork
2. build the ArkUI host HAP in `Harmony/`
3. optionally install and launch the built app on a connected device

## Toolchain

- Flutter OHOS SDK: `https://gitcode.com/openharmony-tpc/flutter_flutter.git`
- Branch: `oh-3.35.7-release`
- Verified local checkout on 2026-04-26: Flutter OHOS `3.35.8-ohos-0.0.3`, Dart `3.8.1`
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

## Signing

Before building the Harmony host app, open the `Harmony/` project in DevEco Studio and complete local signing on your own machine.

Recommended flow:

1. open `Harmony/` in DevEco Studio
2. go to Project Structure or the signing configuration page
3. sign in with your Huawei / DevEco account if required
4. generate or export the local debug signing materials
5. place them under `Harmony/signing/` as:

```text
Harmony/signing/debug.cer
Harmony/signing/debug.p12
Harmony/signing/debug.p7b
```

The repository does not provide signing materials. They must be generated locally and must not be committed.

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
flutter pub global activate intl_utils
dart run intl_utils:generate
flutter build har --debug
```

Recent device validation changed this conclusion:

- The local default OHOS SDK checkout was actually `oh-3.32.0-release` (`Flutter 3.32.4-ohos-0.0.1`, Dart `3.8.1`), not a 3.35 SDK.
- A separate 3.35 worktree was created at `C:\Users\xy\flutter_flutter_3_35_7` and resolves to `Flutter 3.35.8-ohos-0.0.2`, Dart `3.9.2`.
- On the MatePad test device, the `debug` HAP built against the 3.32 SDK still crashes before Flutter UI startup with:
  - `FlutterEngine failed to attach to its native Object reference.`
  - stack top in `FlutterEngine.attachToNapi()` / `FlutterEntry.aboutToAppear()`
- This matches the upstream `flutter_flutter` README note for OHOS debug-mode startup crashes on newer ROMs. In practice, we must validate startup with a 3.35 SDK and prefer `release/profile` for real-device verification when debug hits this attach failure.

Also note:

- The current custom OHOS script still strips `build_runner` / `riverpod_generator` / `json_serializable`, but the upstream project build flow requires:
  - `flutter pub get`
  - `flutter pub global activate intl_utils`
  - `dart run intl_utils:generate`
  - `dart run build_runner build --delete-conflicting-outputs`
- The 3.35 lane currently fails before HAP generation because the repo still carries old OHOS-specific dependency overrides and missing generated files, for example:
  - `flutter_progress_dialog` from `master` now declares Dart `3.11`
  - `flutter_platform_widgets: 7.0.1` override is too old for the current source
  - `ai_summary*.g.dart` and related generated providers are not present in the repository

5. syncs local OHOS plugin SDK HAR dependencies into `.vendor_ohos/*/ohos/libs/`
6. overlays repository `assets/` into the packaged `flutter_assets/assets/` tree so static icons, fonts, and graphics are present in the final HAR
7. injects `rawfile/buildinfo.json5` and `rawfile/framesconfig.json` into the module HAR so a debug HAP launched directly on-device can initialize the Flutter loader correctly
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
- `Harmony/signing/README.md` documents the local debug signing files expected by `Harmony/build-profile.json5`.
- `build_har_from_override.ps1` intentionally tolerates the current OHOS Flutter toolchain printing:

```text
Oops! Failed to find ...\ohos\flutter_module...
```

  as long as the real module HAR was generated under `.ohos` and can be repacked correctly.
 - `XSharedPreferences` now bypasses the encrypted `flutter_secure_storage` + `encrypt_shared_preferences` stack on OHOS and uses a pure Dart file-backed fallback instead.
 - This fallback is intentional: the encrypted storage path was the historical root cause for broken runtime preference / cookie reads on OHOS, which in turn could break image-related flows that depend on persisted config or session state.
 - The OHOS fallback stores data in a local JSON file under the app-accessible runtime directory and keeps the synchronous read semantics expected by `SettingsProvider`, cookie restore, and image-loading code paths.
- Some icon families still need runtime visual verification on OHOS. The build now packages `assets/fonts/iconfont.ttf`, `assets/fonts/MaterialIcons-Regular.otf`, and the full `assets/graphics/` tree, so remaining gaps are more likely runtime rendering or usage-path issues than missing files in the archive.
- The current validation device is a HarmonyOS tablet, so layout and startup verification should always be done on a large-screen device before merging.

## PR Checklist

- `.\build_har_from_override.ps1 -BuildMode debug` succeeds.
- `.\build_ohos.ps1 -BuildMode debug` succeeds.
- `.\run_ohos.ps1` installs and launches the app on a connected device.
- `ohos/` shell-project sources are committed (excluding local caches and tool folders via `ohos/.gitignore`).
- No HAP binaries are committed (`.hap` is gitignored).
- No generated HAR artifacts under `har/` are committed.
- No plugin runtime HAR blobs under `.vendor_ohos/**/libs/` are committed.
- Static assets in `assets/graphics/` and `assets/fonts/` are present in the generated `har/danxi_flutter_module.har`.
- No local SDK paths, signing credentials, `.ohos/`, `Harmony/oh_modules/`, `Harmony/signing/debug.*`, `*-lock.json5` under `.vendor_ohos/`, or scratch files are committed.
