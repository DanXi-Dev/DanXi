# Flutter Progress Dialog

[[pub packages]](https://pub.dartlang.org/packages/flutter_progress_dialog)
| [中文说明](./README_zh-cn.md)

Flutter progress dialog. Support both Android and iOS platform.

The progress dialog just display one at the same time.

The usage inspired by [OpenFlutter/flutter_oktoast](https://github.com/OpenFlutter/flutter_oktoast)

![Example][1]

## Usage

#### 1\. Depend

Add this to you package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_progress_dialog: ^0.1.0
```

#### 2\. Install

Run command:

```bash
$ flutter packages get
```

#### 3\. Import

Import in Dart code:

```dart
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
```

#### 4\. Display Progress Dialog

Support two ways to display a progress dialog.

##### Wrap app widget

1) Wrap your app widget

```dart
ProgressDialog(
  child: MaterialApp(),
);
```

2) Exec `showProgressDialog()` and `dismissProgressDialog()` without parameters.

```dart
showProgressDialog();
//dismissProgressDialog();
```

##### Exec showProgressDialog() directly

You can exec `showProgressDialog()` without wrap app widget, should specify the param: `context: BuildContext`.

```dart
var dialog = showProgressDialog(context: context);
//dismissProgressDialog();
```

#### 5\. Properties

ProgressDialog have default style, and you also can custom style or other behavior.

|Name           |Type                |Desc                                       |
|:--------------|:-------------------|:------------------------------------------|
|loading        |Widget              |If specified, default widget will not show |
|loadingText    |String              |Hint text, just for default widget         |
|textStyle      |TextStyle           |Hint text's style, just for default widget |
|backgroundColor|Color               |Background color of the progress dialog    |
|radius         |double              |Radius of the progress dialog              |
|onDismiss      |Function            |Callback for dismissed                     |
|textDirection  |TextDirection       |Loading hint text's direction              |
|orientation    |ProgressOrientation |The direction of spin kit and hint text    |

## Example

[Example sources](https://github.com/wuzhendev/flutter_progress_dialog/tree/master/example)

[Example APK](https://raw.githubusercontent.com/wuzhendev/assets/master/flutter_progress_dialog/flutter_progress_dialog_v0.1.0.apk)

![Example APK Download](https://github.com/wuzhendev/assets/blob/master/flutter_progress_dialog/flutter_progress_dialog_v0.1.0.png?raw=true)

[1]:https://github.com/wuzhendev/assets/blob/master/flutter_progress_dialog/flutter_progress_dialog_1.jpg?raw=true
