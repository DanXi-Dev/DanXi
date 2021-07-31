[中文版](README.md) English Version  
[Official Website(Chinese Only)](https://danxi-dev.github.io)  
# DanXi
![Dart](https://github.com/w568w/DanXi/workflows/Dart/badge.svg)    
  
> **CAUTION**   
> The English version of README may not be synchronized with [the Chinese one](README.md).

日月光华，旦复旦兮.(The sun and the moon are shining, full of glory. And the morning sun rises, again and again.)   
  
Maybe the best all-rounded service app for Fudan University students!    
 
**Only support Chinese (Simplified) and English language at the moment. Come on to help us!**    

- Campus card balance and transactions
- Dining hall traffic
- Automatic COVID-19 Safety Check-in
- Shortcut for Fudan QR Code (with support for Apple Watch)
- View empty classrooms
- Tree Hole
- View compulsory-exercise records
- View timetable and export as .ics file
- Show Notices from Academic Affairs Office
- View exam schedule and export as .ics file
- View final exam GPA and ranking

This application is still at active development stage, welcome to join the development and donation~

# Install
Note: This application is still in early development and may have unpredictable bugs.   
If you meet abnormal behavior in this application，Please [create an issue](https://github.com/w568w/DanXi/issues/new/choose) or [create a new pull request](https://github.com/w568w/DanXi/compare).
## Windows
Go to [release page](https://github.com/w568w/DanXi/releases), just download the zip file and unzip it.   

## Android
Go to [release page](https://github.com/w568w/DanXi/releases), just download the apk file and install it.   
(Depending on the device, you may need to allow "Install apps from unknown sources" in the settings.)  

## iOS/iPadOS (Via [AltStore](https://altstore.io) )
Download from [App Store](https://apps.apple.com/us/app/旦夕/id1568629997)

## macOS 
Distributions for macOS are uncontinued now because of very few users. If necessary, consider using the iOS/iPadOS version instead.

# Compile
## Flutter version that we're using
```shell script
$ flutter --version
Flutter 2.2.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision b22742018b (9 weeks ago) • 2021-05-14 19:12:57 -0700
Engine • revision a9d88a4d18
Tools • Dart 2.13.0
```
## Notes on compilation
The app is compiled with [Dart](https://dart.dev/) and [Flutter](https://flutter.dev/).  
  
To build this app, you need to [download Flutter SDK](https://flutter.dev/docs/get-started/install) and install it.    
  
If you are building for `Windows`, you should also [install and configure](https://visualstudio.microsoft.com/downloads/) `Visual Studio`.    
  
If you are building for `Android`, you should also [install and configure](https://developer.android.com/studio) `Android Command Line Tools`.   

If you are building for `iOS/iPadOS`, you should also [install and configure](https://apps.apple.com/cn/app/xcode/id497799835) `Xcode`.  
Run the command `flutter run [ios/android]` to start the app.