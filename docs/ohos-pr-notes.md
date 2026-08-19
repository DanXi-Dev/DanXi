# OHOS PR Notes

This document explains why the OHOS pull request is large, what each added block is for, and how the compatibility layer works without permanently rewriting the upstream Flutter application source tree.

## Why the diff is large

Most of the added lines are not random app-code edits. They come from four buckets:

1. `Harmony/`
   - The ArkUI host project that produces the final signed HAP.
   - This is the native HarmonyOS shell app.
   - It contains app metadata, entry ability code, resources, and hvigor project files.

2. `ohos/`
   - The Flutter OHOS module shell used by `flutter build har`.
   - It provides the hvigor / ohpm / package structure expected by the OHOS Flutter toolchain.
   - It is not the final app host. It exists so the Flutter HAR build can run reproducibly outside the IDE.

3. `.vendor/` and `.vendor_ohos/`
   - Pinned local dependency inputs needed by the OHOS lane.
   - These are committed because upstream package heads are no longer stable enough for reproducible OHOS builds.
   - In practice, a large part of the line count comes from vendored plugin code rather than changes to DanXi itself.

4. `build_ohos.ps1`, `build_har_from_override.ps1`, `patches/ohos-build/*`
   - The automation and temporary patch layer.
   - These files are the actual adaptation logic.
   - They let us keep the normal Flutter code path and the OHOS path separate.

## What is actually adapted

The OHOS lane has three kinds of adaptation.

### 1. Dependency and toolchain adaptation

The build activates `pubspec_overrides.ohos.yaml` only for the OHOS lane.

This is used to:

- pin OHOS-compatible dependency versions
- redirect selected packages to committed local vendor copies
- keep the standard upstream release flow separate from the HarmonyOS flow

The HAR builder also writes temporary OHOS-specific package metadata such as:

- `pubspec_overrides.yaml`
- `ohos/package.json`
- `.ohos/local.properties`

These are generated or patched during build and then restored or discarded.

### 2. Build-time source overlays

Some runtime fixes are required on OHOS, but we do not want to keep those edits as permanent in-place modifications to upstream source files.

Instead, the build uses:

- `patches/ohos-build/file-overlays.psd1`
- `patches/ohos-build/overlays/...`
- `patches/ohos-build/source-replacements.psd1`
- `patches/ohos-build/pubspec-replacements.psd1`

During the HAR build, `build_har_from_override.ps1`:

1. backs up the original file contents
2. writes temporary OHOS overlays and string replacements
3. runs `flutter pub get`, i18n generation, and `build_runner`
4. builds the HAR artifacts
5. restores the original files afterward

This means the compatibility changes take effect for the OHOS build, but the normal upstream code layout remains the default repository state.

### 3. Packaging adaptation

The OHOS build needs more than a plain `flutter build har`.

The script also:

- generates a lightweight `lib/common/pubspec.yaml.g.dart` shim for the OHOS lane
- installs and materializes `flutter-hvigor-plugin` into `ohos/node_modules/`
- injects native runtime HAR references for arm64 and x86_64
- copies vendored plugin HARs from `.vendor_ohos`
- repacks the generated module HAR to include:
  - `assets/graphics/*`
  - `assets/fonts/*`
  - `rawfile/buildinfo.json5`
  - `rawfile/framesconfig.json`

Without these steps, the output is not reliably portable to a clean checkout.

## Why there are app-source overlays at all

The source overlays are narrow and deliberate. They exist because OHOS runtime behavior is not identical to Android / iOS / desktop Flutter.

The most important case is storage:

- `XSharedPreferences` cannot rely on the encrypted storage stack used on other platforms.
- On OHOS, that path was the historical cause of broken persisted settings and cookie reads.
- The OHOS lane therefore uses a file-backed fallback so persisted runtime state remains readable.

Other overlays are similarly targeted at runtime compatibility in code paths that blocked the OHOS build or launch flow.

## Why this is still considered non-invasive

Although the PR is large in added lines, the design tries to avoid broad upstream intrusion:

- no permanent OHOS-only edits are required in the normal release flow
- the standard Flutter release scripts remain separate
- most source changes are applied only during the OHOS build and then restored
- generated outputs such as `.hap`, `har/`, `oh_modules/`, `.hvigor/`, and signing artifacts are excluded from the committed result

So the size mainly reflects:

- a new native host project
- a new module shell project
- vendored reproducibility inputs
- the build automation needed to glue them together

not a wholesale rewrite of the existing application.

## Build flow summary

The public OHOS entrypoint is:

```powershell
.\build_ohos.ps1 -BuildMode release -SkipFlutterSdkUpdate
```

At a high level it does this:

1. call `build_har_from_override.ps1`
2. activate OHOS overrides
3. apply temporary overlays and replacements
4. run Flutter dependency resolution and code generation
5. build Flutter HAR artifacts with the OHOS Flutter SDK
6. repack the module HAR with required assets and metadata
7. build the ArkUI host app in `Harmony/`
8. emit final artifacts under `har/`

## Reviewer guidance

When reviewing this PR, it is most useful to separate it into:

- host shell files: `Harmony/`
- Flutter module shell files: `ohos/`
- vendored dependency inputs: `.vendor/`, `.vendor_ohos/`
- build logic: `build_ohos.ps1`, `build_har_from_override.ps1`, `patches/ohos-build/*`
- documentation: `docs/*.md`

The files most likely to contain actual adaptation logic are the scripts and patch manifests, not the bulk vendor directories.
