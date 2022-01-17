import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_updated.g.dart';

@JsonSerializable()
class BmobUpdated {
  String? updatedAt;

  BmobUpdated();

  //此处与类名一致，由指令自动生成代码
  factory BmobUpdated.fromJson(Map<String, dynamic> json) =>
      _$BmobUpdatedFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobUpdatedToJson(this);
}
