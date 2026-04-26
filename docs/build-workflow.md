# 构建流程说明

这份说明把当前仓库里分散的构建入口整理成一条可复现的本地流程。

## 我们现在的构建分层

1. 依赖与代码生成
2. 平台打包
3. 平台专属发布后处理

其中，桌面和移动端的通用 Flutter 构建走 [build_release.ps1](../build_release.ps1)，OHOS 走 [build_ohos.ps1](../build_ohos.ps1) 的独立链路。

## 通用 Flutter 构建

当前探索出来的标准前置步骤已经内联到 [build_release.ps1](../build_release.ps1) 里，不再需要手工分开执行。

它会自动完成依赖同步（默认开启 `--enforce-lockfile`）、`intl_utils` 本地化生成，然后再进入真正的平台打包。`build_runner` 由 `build_release.dart` 在同一条链路内执行。

## 发布打包

`build_release.dart` 负责真正的发布产物封装：

- 读取 git 提交号并注入 `GIT_HASH`
- 根据 `--target` 选择 `android`、`android-armv8`、`windows`、`aab` 或 `linux`
- 生成并重命名最终产物到 `build/app/`
- Windows 和 Linux 最终产物会再次压缩成 zip

推荐直接使用脚本入口：

```powershell
.\build_release.ps1 -Target windows -VersionCode 349
```

如果你希望精确复用脚本里的执行语义，也可以直接调用：

```powershell
flutter pub get --enforce-lockfile
dart run intl_utils:generate
dart run build_release.dart --target windows --versionCode 349
```

## 可复现脚本

### 1. 发布脚本

```powershell
.\build_release.ps1 -Target android -VersionCode 349
```

这个脚本会先完成代码生成，再调用 `build_release.dart` 完成最终打包，适合本地和 CI 对齐。

如果你在临时调试依赖解析（不建议在正式发布链路中使用），可以显式关闭锁文件约束：

```powershell
.\build_release.ps1 -Target windows -VersionCode 349 -NoEnforceLockfile
```

## 现有约束

- Android release 需要先恢复 `android/app/build.gradle` 里的 release 签名配置，并准备好 `android/key.properties`。
- `VersionCode` 是发布产物命名的一部分，不建议留空。
- 从 git 仓库根目录执行时，产物会携带当前 commit hash。

## OHOS 单独说明

OHOS 不是这条通用 Flutter 发布链路的一部分，它仍然使用独立脚本：

- [build_ohos.ps1](../build_ohos.ps1)

这条链路先构建 HAR，再构建 Harmony HAP，不能和上面的通用打包流程混用。HAR 构建目前仍由 `build_ohos.ps1` 内部调用，不作为对外入口展示。