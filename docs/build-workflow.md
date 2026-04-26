# Build Workflow

This repository now keeps the release build flow and the HarmonyOS build flow separate on purpose.

## Standard Flutter release flow

Use `build_release.ps1` for Android, Windows, Linux, and other normal Flutter release targets.

It runs the upstream preparation steps in order:

```powershell
flutter pub get --enforce-lockfile
flutter pub global activate intl_utils
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
dart run build_release.dart --target windows --versionCode 349
```

Equivalent wrapper:

```powershell
.\build_release.ps1 -Target windows -VersionCode 349
```

## HarmonyOS flow

Before running the OHOS scripts, complete local signing for `Harmony/` in DevEco Studio and place the generated debug signing files under `Harmony/signing/`.

Use the dedicated OHOS scripts only:

```powershell
.\build_ohos.ps1 -BuildMode debug -SkipFlutterSdkUpdate
.\run_ohos.ps1
```

The OHOS flow is intentionally isolated because it:

1. activates `pubspec_overrides.ohos.yaml`
2. builds Flutter HAR artifacts with the OHOS Flutter SDK
3. builds the ArkUI host project in `Harmony/`

The OHOS lane also carries a storage-specific runtime fix:

- `XSharedPreferences` does not use the encrypted storage plugin stack on OHOS.
- It falls back to a pure Dart file-backed store because encrypted preference initialization was the historical cause of broken persisted config / cookie reads on HarmonyOS, which can surface as image-loading failures at runtime.

The current OHOS Flutter `oh-3.35.7-release` checkout on this machine resolves to Dart `3.8.1`, so the OHOS lane reuses committed generated files instead of rerunning the full `build_runner` generator stack.

See `docs/harmony.md` for the full OHOS setup, signing layout, and reproducibility checklist.

## Repository policy

- Commit scripts, source patches, and docs.
- Do not commit generated `hap` or `har` outputs.
- Do not commit local signing files under `Harmony/signing/`.
