import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_sent.g.dart';

@JsonSerializable()
class BmobSent {
  int? smsId;

  BmobSent();

  //此处与类名一致，由指令自动生成代码
  factory BmobSent.fromJson(Map<String, dynamic> json) =>
      _$BmobSentFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobSentToJson(this);
}
