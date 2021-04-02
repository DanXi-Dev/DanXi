中文版 [English Version](README_EN.md)
# 旦兮
![Dart](https://github.com/w568w/DanXi/workflows/Dart/badge.svg)  
  
日月光华，旦复旦兮.  
  
可能是为 FDUer 准备的,最好的一站式服务 APP!  

- 饭卡余额和消费记录
- 食堂消费人数
- 一键平安复旦
- 快速显示复活码
- 课表查阅和导出为.ICS
  
(复旦于2021年元旦前后大批量修改了API接口，导致某些功能失效，正在逐个修复中)  
目前这款应用仍处于最初的开发阶段,欢迎各位大佬加入开发~

# 安装
注意：本应用仍处于早期开发阶段，也许会有不可预料的 Bug 发生。  
如果您遇到了本应用中不符合预期的行为，欢迎 [新建 Issue](https://github.com/w568w/DanXi/issues/new/choose) 或 [发起 Pull request](https://github.com/w568w/DanXi/compare)。
## Windows
打开 [release 页面](https://github.com/w568w/DanXi/releases) 下载 zip 压缩包，解压运行即可。  

## Android
打开 [release 页面](https://github.com/w568w/DanXi/releases) 下载 apk 安装包，安装即可。  
（依据设备差异，您可能需要在设置中允许「安装来自未知来源的应用」）

## iOS/iPadOS（使用 [AltStore](https://altstore.io) 安装）
  
由于开发团队没有能力支持高额的 Apple 开发者计划费用（疯狂暗示.jpg），本应用难以上架 AppStore 或使用其他简便的方式供用户安装。
  
此处提供一种特殊的使用方法，需要准备同一局域网下的一台电脑（ macOS/Windows ）
  
1. 在电脑上安装 [AltServer](https://altstore.io)
2. 使用 AltServer 在设备上安装 AltStore。
3. 在设备上使用 Safari 浏览器前往 [release 页面](https://github.com/w568w/DanXi/releases) 下载 ipa 安装包。
4. 在设备上打开于第二步中安装好的 AltStore，选择底部的 My Apps 标签页，再点击左上角的”+“号，在弹出的文件窗口中选择您下载好的 ipa 安装包进行安装。
5. 每 7 天（应用旁显示的 Expire 时间）内需要在 AltStore 中刷新一次，否则 AltStore 与本应用均无法运行。
  
有关 AltStore 的常见问题你可以在[这里](https://altstore.io/faq/)(英文)得到解答。  
有关 AltStore 的技术细节参见其[项目首页](https://github.com/rileytestut/AltStore)(英文)。
  
感谢理解与支持！

# 构建
## 我们当前使用的 Flutter 编译版本
```shell script
$ flutter --version
Flutter 2.1.0-12.1.pre • channel dev • https://github.com/flutter/flutter.git
Framework • revision 8264cb3e8a (3 weeks ago) • 2021-03-10 12:37:57 -0800
Engine • revision 711ab3fda0
Tools • Dart 2.13.0 (build 2.13.0-116.0.dev)
```
## 编译说明
本应用使用 [Dart](https://dart.cn/) 和 [Flutter](https://flutter.cn/) 开发。  
  
为了构建本应用，您需要按照`Flutter`官网的要求[配置国内镜像源](https://flutter.cn/community/china)，然后[下载](https://flutter.cn/docs/get-started/install)并安装`Flutter SDK`。    
  
如果您正在为`Windows`平台构建，您还需要[安装并配置](https://visualstudio.microsoft.com/zh-hans/downloads/)`Visual Studio`。  
  
如果您正在为`Android`平台构建，您还需要[安装并配置](https://developer.android.google.cn/studio)`Android Command Line Tools`。
   
如果你正在为`iOS/iPadOS`平台构建，您还需要[安装并配置](https://apps.apple.com/cn/app/xcode/id497799835)`Xcode`。
  
确定配置正确后，在项目根目录下运行`flutter run [ios/android]`即可运行应用。
