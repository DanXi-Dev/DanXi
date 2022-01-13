import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_date.g.dart';

@JsonSerializable()
class BmobDate {
  String? iso;
  @JsonKey(name: '__type')
  String? type = "Date";

  BmobDate();

  void setDate(DateTime dateTime) {
    iso = dateTime.toString();
  }

  //此处与类名一致，由指令自动生成代码
  factory BmobDate.fromJson(Map<String, dynamic> json) =>
      _$BmobDateFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobDateToJson(this);
}
