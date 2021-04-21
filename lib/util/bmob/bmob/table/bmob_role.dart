library bmobrole;

import 'package:json_annotation/json_annotation.dart';

import '../table/bmob_object.dart';

import '../type/bmob_relation.dart';

import '../type/bmob_pointer.dart';

part 'bmob_role.g.dart';

@JsonSerializable()
class BmobRole extends BmobObject {
  factory BmobRole.fromJson(Map<String, dynamic> json) =>
      _$BmobRoleFromJson(json);

  Map<String, dynamic> toJson(BmobRole instance) => _$BmobRoleToJson(instance);

  String name;
  Map<String, dynamic> roles;
  Map<String, dynamic> users;

  BmobRole();

  @override
  Map getParams() {
    // TODO: implement getParams
    return toJson(this);
  }

  ///设置角色
  void setRoles(BmobRelation bmobRelation) {
    roles = bmobRelation.toJson();
  }

  ///设置用户
  void setUsers(BmobRelation bmobRelation) {
    users = bmobRelation.toJson();
  }
}
