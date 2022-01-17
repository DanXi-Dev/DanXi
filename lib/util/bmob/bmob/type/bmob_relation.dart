import 'package:json_annotation/json_annotation.dart';
import 'bmob_pointer.dart';
import '../table/bmob_object.dart';
import '../bmob_utils.dart';

part 'bmob_relation.g.dart';

@JsonSerializable()
class BmobRelation {
  factory BmobRelation.fromJson(Map<String, dynamic> json) =>
      _$BmobRelationFromJson(json);

  Map<String, dynamic> toJson() => _$BmobRelationToJson(this);

  @JsonKey(name: "__op")
  String? op;

  //关联关系列表
  List<Map<String, dynamic>>? objects;

  BmobRelation() {
    objects = [];
  }

  //添加某个关联关系
  void add(BmobObject value) {
    op = "AddRelation";
    BmobPointer bmobPointer = BmobPointer();
    bmobPointer.className = BmobUtils.getTableName(value);
    bmobPointer.objectId = value.objectId;
    objects!.add(bmobPointer.toJson());
  }

  //移除某个关联关系
  void remove(BmobObject value) {
    op = "RemoveRelation";
    BmobPointer bmobPointer = BmobPointer();
    bmobPointer.className = BmobUtils.getTableName(value);
    bmobPointer.objectId = value.objectId;
    objects!.add(bmobPointer.toJson());
  }
}
