import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_saved.g.dart';

@JsonSerializable()
class BmobSaved {
  String? createdAt;
  String? objectId;

  BmobSaved();

  //此处与类名一致，由指令自动生成代码
  factory BmobSaved.fromJson(Map<String, dynamic> json) =>
      _$BmobSavedFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobSavedToJson(this);
}
