import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_handled.g.dart';

@JsonSerializable()
class BmobHandled {
  String? msg;

  BmobHandled();

  //此处与类名一致，由指令自动生成代码
  factory BmobHandled.fromJson(Map<String, dynamic> json) =>
      _$BmobHandledFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobHandledToJson(this);
}
