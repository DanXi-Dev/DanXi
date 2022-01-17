import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_registered.g.dart';

@JsonSerializable()
class BmobRegistered {
  String createdAt;
  String objectId;
  String sessionToken;

  BmobRegistered();

  //此处与类名一致，由指令自动生成代码
  factory BmobRegistered.fromJson(Map<String, dynamic> json) =>
      _$BmobRegisteredFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobRegisteredToJson(this);
}
