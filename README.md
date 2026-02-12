中文版 [English Version](README_EN.md)
[官方网站](https://danxi.fduhole.com)

# 旦挞

[![CI](https://github.com/DanXi-Dev/DanXi/actions/workflows/ci_ios.yml/badge.svg)](https://github.com/DanXi-Dev/DanXi/actions/workflows/ci_ios.yml)
[![Deploy to GitHub Pages](https://github.com/DanXi-Dev/DanXi/actions/workflows/deploy_to_gh-pages.yml/badge.svg)](https://github.com/DanXi-Dev/DanXi/actions/workflows/deploy_to_gh-pages.yml)

（原名旦夕、旦兮）

日月光华，旦复旦兮.

可能是为 FDUer 准备的,最好的一站式服务 APP!

- 校园卡余额和消费记录
- 食堂消费人数
- 快速显示复活码（支持 Apple Watch 显示）
- 空教室查询
- 刷锻次数查询
- 茶楼
- 课表查阅与导出至系统日历等
- 显示教务处通知
- 查询期中/期末考试日程与导出至系统日历等
- 查询期末绩点和专业排名
- 查询校车班次

欢迎各位大佬加入开发~

# 安装

如果您遇到了本应用中不符合预期的行为，欢迎 [新建 Issue](https://github.com/DanXi-Dev/DanXi/issues/new/choose) 或 [发起 Pull request](https://github.com/DanXi-Dev/DanXi/compare)。

## iOS(watchOS)/iPadOS

从 [App Store](https://apps.apple.com/app/id1568629997) 下载

## Android

打开 [release 页面](https://github.com/DanXi-Dev/DanXi/releases/latest) 下载最新版 apk 安装包，安装即可。
（依据设备差异，您可能需要在设置中允许「安装来自未知来源的应用」）

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/io.github.danxi_dev.dan_xi/)
[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get it on Google Play"
     height="80">](https://play.google.com/store/apps/details?id=io.github.danxi_dev.dan_xi)

## Windows

打开 [release 页面](https://github.com/DanXi-Dev/DanXi/releases/latest) 下载最新版 zip 压缩包，解压运行即可。

## macOS

使用 Apple Silicon 的用户可以直接从 [App Store](https://apps.apple.com/app/id1568629997) 下载。

Apple Intel 用户请打开 [release 页面](https://github.com/DanXi-Dev/DanXi/releases/latest) 下载最新版
dmg 硬盘映像，挂载拷贝即可。

## Linux

### Arch Linux

从 [AUR](https://aur.archlinux.org) 或 [archlinuxcn](https://github.com/archlinuxcn/repo) 安装。

#### AUR

```shell
[yay/paru] -S danxi # 最新稳定版
[yay/paru] -S danxi-git # 最新 Git 版
```

#### archlinuxcn

```shell
sudo pacman -S danxi # 最新稳定版
sudo pacman -S danxi-git # 最新 Git 版
```

### 其他 Linux 发行版

打开 [release 页面](https://github.com/DanXi-Dev/DanXi/releases/latest) 下载最新版 zip 压缩包，解压运行即可。

#### 依赖项

在 Linux 上运行旦挞需要以下依赖项：

- **libsecret** 和 **gnome-keyring**：用于安全存储加密配置文件所用的主密钥。
  - libsecret：[官网](https://gnome.pages.gitlab.gnome.org/libsecret/) | [安装源](https://repology.org/project/libsecret/versions)
  - gnome-keyring：[官网](https://gitlab.gnome.org/GNOME/gnome-keyring) | [安装源](https://repology.org/project/gnome-keyring/versions)
- **gtk3**：用于显示 GTK3 窗口。
  - [官网](https://gtk.org/) | [安装源](https://repology.org/project/gtk/versions)
- **wpewebkit**：用于显示应用内 WebView。
  - [官网](https://wpewebkit.org/) | [安装源](https://repology.org/project/wpewebkit/versions)

### 已知问题

部分 GPU（如 AMD 显卡）上，应用内 WebView 可能显示为黑屏。这是 WPE WebKit 硬件渲染的兼容性问题。可通过设置环境变量强制使用软件渲染来解决：

```shell
LIBGL_ALWAYS_SOFTWARE=1 ./danxi
```

详见 [flutter_inappwebview#460](https://github.com/pichillilorenzo/flutter_inappwebview/issues/460#issuecomment-3798706399)。

# 构建

## 我们当前使用的 Flutter 编译版本

```shell
$ flutter --version
Flutter 3.41.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 44a626f4f0 (2 天前) • 2026-02-10 10:16:12 -0800
Engine • hash cc8e596aa65130a0678cc59613ed1c5125184db4 (revision 3452d735bd) (2 days ago) • 2026-02-09 22:03:17.000Z
Tools • Dart 3.11.0 • DevTools 2.54.1
```

## 编译说明

本应用使用 [Dart](https://dart.cn/) 和 [Flutter](https://flutter.cn/) 开发。

为了构建本应用，您需要按照 `Flutter` 官网的要求[配置国内镜像源](https://flutter.cn/community/china)，然后[下载](https://flutter.cn/docs/get-started/install)并安装 `Flutter SDK`。

如果您正在为 `Windows` 平台构建，您还需要[安装并配置](https://visualstudio.microsoft.com/zh-hans/downloads/) `Visual Studio`。

如果您正在为 `Android` 平台构建，您还需要[安装并配置](https://developer.android.google.cn/studio) `Android Command Line Tools`。

如果你正在为 `iOS/iPadOS/macOS` 平台构建，您还需要[安装并配置](https://apps.apple.com/app/id497799835) `Xcode`。

确定配置正确后，你需要首先在项目根目录下运行 

```
flutter pub get
flutter pub global activate intl_utils
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
```

然后运行  `flutter run [ios/android]`即可运行应用。

## 赞助

由于 Apple Developer Program 费用（发布应用至 App Store 和 TestFlight 所必需）费用较高，如果您希望赞助我们，请通过邮件联系我们！

我们的邮箱：[dev@danta.tech](mailto:dev@danta.tech)
