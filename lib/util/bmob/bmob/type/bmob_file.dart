import 'dart:io';

import '../bmob.dart';
import '../bmob_dio.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bmob_file.g.dart';

@JsonSerializable()
class BmobFile {
  @JsonKey(name: "__type")
  String type;
  String cdn;
  String url;
  String filename;

  BmobFile() {
    type = "File";
  }

  //此处与类名一致，由指令自动生成代码
  factory BmobFile.fromJson(Map<String, dynamic> json) =>
      _$BmobFileFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobFileToJson(this);
}
