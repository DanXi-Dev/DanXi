中文版 [English Version](README_EN.md)  
[官方网站](https://danxi-dev.github.io)  

# 旦夕
![Dart](https://github.com/w568w/DanXi/workflows/Dart/badge.svg)  
  
（原名旦兮）

日月光华，旦复旦兮.
  
可能是为 FDUer 准备的,最好的一站式服务 APP!  

- 校园卡余额和消费记录
- 食堂消费人数
- 提示并快速平安复旦打卡
- 快速显示复活码（支持 Apple Watch 显示）
- 空教室查询
- 刷锻次数查询
- FDU Hole 树洞
- 课表查阅与导出至系统日历等
- 显示教务处通知
- 查询期中/期末考试日程与导出至系统日历等
- 查询期末绩点和专业排名
- 查询校车班次

欢迎各位大佬加入开发~

# 安装
如果您遇到了本应用中不符合预期的行为，欢迎 [新建 Issue](https://github.com/w568w/DanXi/issues/new/choose) 或 [发起 Pull request](https://github.com/w568w/DanXi/compare)。

## iOS(watchOS)/iPadOS

从 [App Store](https://apps.apple.com/us/app/旦夕/id1568629997) 下载

## Android
打开 [release 页面](https://github.com/w568w/DanXi/releases/latest) 下载最新版 apk 安装包，安装即可。  
（依据设备差异，您可能需要在设置中允许「安装来自未知来源的应用」）

## Windows
打开 [release 页面](https://github.com/w568w/DanXi/releases/latest) 下载最新版 zip 压缩包，解压运行即可。  

## macOS
由于 macOS 用户基数太少，专用于 macOS 的发行版本现在已经停止发布。如果有必要使用，可以考虑用iOS/iPadOS版本代替。

# 构建
## 我们当前使用的 Flutter 编译版本

```shell script
$ flutter --version
Flutter 2.2.3 • channel stable • https://github.com/flutter/flutter.git
Framework • revision f4abaa0735 (5 weeks ago) • 2021-07-01 12:46:11 -0700
Engine • revision 241c87ad80
Tools • Dart 2.13.4
```
## 编译说明
本应用使用 [Dart](https://dart.cn/) 和 [Flutter](https://flutter.cn/) 开发。  
  
为了构建本应用，您需要按照`Flutter`官网的要求[配置国内镜像源](https://flutter.cn/community/china)，然后[下载](https://flutter.cn/docs/get-started/install)并安装`Flutter SDK`。    
  
如果您正在为`Windows`平台构建，您还需要[安装并配置](https://visualstudio.microsoft.com/zh-hans/downloads/)`Visual Studio`。  
  
如果您正在为`Android`平台构建，您还需要[安装并配置](https://developer.android.google.cn/studio)`Android Command Line Tools`。
   
如果你正在为`iOS/iPadOS/macOS`平台构建，您还需要[安装并配置](https://apps.apple.com/cn/app/xcode/id497799835)`Xcode`。
  
确定配置正确后，在项目根目录下运行`flutter run [ios/android]`即可运行应用。

## 赞助
由于 Apple Developer Program 费用（发布应用至 App Store 和 TestFlight 所必需）费用较高，如果您希望赞助我们，您可以通过爱发电平台赞助我们 https://afdian.net/@danxi-dev  
然而爱发电平台会抽成，所以有赞助希望能直接通过邮件联系我们！
我们的邮箱：[danxi_dev@protonmail.com](mailto:danxi_dev@protonmail.com)
