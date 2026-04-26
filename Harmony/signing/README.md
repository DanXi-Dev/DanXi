# Harmony Debug Signing

This directory is intentionally local-only.

Before running `build_ohos.ps1`, open `Harmony/` in DevEco Studio and finish the app signing setup on your own machine.

Export or generate the debug signing materials, then place them here:

- `debug.cer`
- `debug.p12`
- `debug.p7b`

`Harmony/build-profile.json5` already points to these relative paths.

Do not commit these files to git.
