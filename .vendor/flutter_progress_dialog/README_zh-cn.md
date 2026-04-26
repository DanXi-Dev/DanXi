# Flutter Progress Dialog

[[pub packages]](https://pub.dartlang.org/packages/flutter_progress_dialog)

Flutter 的加载提示对话框，支持 Android 和 iOS 平台。

***同一时间只会显示一个 ProgressDialog。***

实现方案参考了项目：[OpenFlutter/flutter_oktoast](https://github.com/OpenFlutter/flutter_oktoast)

![Example][1]

## 用法

#### 1\. 依赖库

在项目的 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_progress_dialog: ^0.1.0
```

#### 2\. 获取包

执行命令：

```bash
$ flutter packages get
```

#### 3\. 导入库文件

导入 flutter_progress_dialog

```dart
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
```

#### 4\. 显示 ProgressDialog

支持两种方式显示加载中的对话框。

##### Wrap app widget

1) 在 MaterialApp 外层添加 ProgressDialog

```dart
ProgressDialog(
  child: MaterialApp(),
);
```

2) 可以在任何页面执行 `showProgressDialog()、dismissProgressDialog()` 方法，不需要传递任何参数。

```dart
showProgressDialog();
//dismissProgressDialog();
```

##### 直接执行 showProgressDialog() 方法

可以直接执行 `showProgressDialog()` 方法，此时需要指定参数 `context: BuildContext`。

```dart
var dialog = showProgressDialog(context: context);
//dismissProgressDialog();
```

#### 5\. 参数

ProgressDialog 有默认的样式，同时还可以根据需求自定义样式，或者指定自定义的加载布局。

示例代码中使用 [flutter_spinkit](https://github.com/jogboms/flutter_spinkit) 显示自定义的加载布局，可以进行参考。

|Name           |Type                |Desc                                |
|:--------------|:-------------------|:-----------------------------------|
|loading        |Widget              |如果指定了布局，不再显示默认的布局         |
|loadingText    |String              |提示的文字，只有在显示默认布局时生效       |
|textStyle      |TextStyle           |提示文字的样式，只有在显示默认布局时生效    |
|backgroundColor|Color               |对话框的背景色                         |
|radius         |double              |对话框背景的圆角值                      |
|onDismiss      |Function            |对话框消失时的回调                      |
|textDirection  |TextDirection       |提示文字的排列方向                      |
|orientation    |ProgressOrientation |加载图标和文字的排列方向(从左到右/从上到下) |

## 示例

[示例代码](https://github.com/wuzhendev/flutter_progress_dialog/tree/master/example)

[示例APK](https://raw.githubusercontent.com/wuzhendev/assets/master/flutter_progress_dialog/flutter_progress_dialog_v0.1.0.apk)

![Example APK Download](https://github.com/wuzhendev/assets/blob/master/flutter_progress_dialog/flutter_progress_dialog_v0.1.0.png?raw=true)

[1]:https://github.com/wuzhendev/assets/blob/master/flutter_progress_dialog/flutter_progress_dialog_1.jpg?raw=true
