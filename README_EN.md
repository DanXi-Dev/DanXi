[中文版](README.md) English Version
[Official Website(Chinese Only)](https://danxi.fduhole.com)

# Danta

[![CI](https://github.com/DanXi-Dev/DanXi/actions/workflows/ci_ios.yml/badge.svg)](https://github.com/DanXi-Dev/DanXi/actions/workflows/ci_ios.yml)
[![Deploy to GitHub Pages](https://github.com/DanXi-Dev/DanXi/actions/workflows/deploy_to_gh-pages.yml/badge.svg)](https://github.com/DanXi-Dev/DanXi/actions/workflows/deploy_to_gh-pages.yml)

> **CAUTION**
> The English version of README may not be synchronized with [the Chinese one](README.md).

日月光华，旦复旦兮.(The sun and the moon are shining, full of glory. And the morning sun rises, again and
again.)

Maybe the best all-rounded service app for Fudan University students!

**Danta only support Chinese (Simplified) and English language at the moment. Come to help us!**

- Campus card balance and transactions
- Dining hall traffic
- Shortcut for Fudan QR Code (with support for Apple Watch)
- View empty classrooms
- Student forum
- View compulsory-exercise records
- View timetable and export as .ics file
- Show Notices from Academic Affairs Office
- View exam schedule and export as .ics file
- View final exam GPA and ranking
- View school bus schedule

This application is still at active development stage, we will be happy if you can join the development or make a donation!

# Install

If you meet abnormal behavior in
Danta, Please [create an issue](https://github.com/DanXi-Dev/DanXi/issues/new/choose)
or [create a new pull request](https://github.com/DanXi-Dev/DanXi/compare).

## Windows

Go to [release page](https://github.com/DanXi-Dev/DanXi/releases), just download the zip file and
unzip it.

## Android

Go to [release page](https://github.com/DanXi-Dev/DanXi/releases), just download the apk file and
install it.
(Depending on the device, you may need to allow "Install apps from unknown sources" in the
settings.)

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/io.github.danxi_dev.dan_xi/)
[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get it on Google Play"
     height="80">](https://play.google.com/store/apps/details?id=io.github.danxi_dev.dan_xi)

## iOS/iPadOS

Download from [App Store](https://apps.apple.com/us/app/旦夕/id1568629997)

## macOS

Go to [release page](https://github.com/DanXi-Dev/DanXi/releases), just download the dmg file and
mount it.

## Linux

### Arch Linux

You can install it from [AUR](https://aur.archlinux.org/danxi-git.git) or [archlinuxcn](https://github.com/archlinuxcn/repo/tree/master/archlinuxcn/danxi-git).

#### AUR

```shell
[yay/paru] -S danxi-git
```

#### archlinuxcn

```shell
sudo pacman -S danxi-git
```

### Other Linux distributions

Go to [release page](https://github.com/DanXi-Dev/DanXi/releases), just download the zip file and
unzip it.

#### Dependencies

Running Danta on Linux requires the following dependencies:

- **libsecret** and **gnome-keyring**: For securely storing the master key used to encrypt configuration files.
  - libsecret: [Website](https://gnome.pages.gitlab.gnome.org/libsecret/) | [Packages](https://repology.org/project/libsecret/versions)
  - gnome-keyring: [Website](https://gitlab.gnome.org/GNOME/gnome-keyring) | [Packages](https://repology.org/project/gnome-keyring/versions)
- **gtk3**: For displaying GTK3 windows.
  - [Website](https://gtk.org/) | [Packages](https://repology.org/project/gtk/versions)
- **wpewebkit**: For displaying in-app WebViews.
  - [Website](https://wpewebkit.org/) | [Packages](https://repology.org/project/wpewebkit/versions)

### Known Issues

On some GPUs (e.g. AMD graphics cards), the in-app WebView may render as a black screen. This is a WPE WebKit hardware rendering compatibility issue. You can work around it by forcing software rendering via an environment variable:

```shell
LIBGL_ALWAYS_SOFTWARE=1 ./danxi
```

See [flutter_inappwebview#460](https://github.com/pichillilorenzo/flutter_inappwebview/issues/460#issuecomment-3798706399) for details.

# Compile

## Flutter version that we're using

```shell
$ flutter --version
Flutter 3.41.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 44a626f4f0 (2 days ago) • 2026-02-10 10:16:12 -0800
Engine • hash cc8e596aa65130a0678cc59613ed1c5125184db4 (revision 3452d735bd) (2 days ago) • 2026-02-09 22:03:17.000Z
Tools • Dart 3.11.0 • DevTools 2.54.1
```

## Notes on compilation

The app is compiled with [Dart](https://dart.dev/) and [Flutter](https://flutter.dev/).

To build this app, you need to [download Flutter SDK](https://flutter.dev/docs/get-started/install) and install it.

If you are building for `Windows`, you should also [install and configure](https://visualstudio.microsoft.com/downloads/) `Visual Studio`.

If you are building for `Android`, you should also [install and configure](https://developer.android.com/studio) `Android Command Line Tools`.

If you are building for `iOS/iPadOS`, you should also [install and configure](https://apps.apple.com/cn/app/xcode/id497799835) `Xcode`.

Run the command 

```
flutter pub get
flutter pub global activate intl_utils
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
```

and then  `flutter run [ios/android]` to start the app.
