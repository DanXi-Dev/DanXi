// GENERATED CODE - DO NOT MODIFY BY HAND

part of bmobrole;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BmobRole _$BmobRoleFromJson(Map<String, dynamic> json) {
  return BmobRole()
    ..createdAt = json['createdAt'] as String
    ..updatedAt = json['updatedAt'] as String
    ..objectId = json['objectId'] as String
    ..ACL = json['ACL'] as Map<String, dynamic>
    ..name = json['name'] as String
    ..roles = json['roles'] as Map<String, dynamic>
    ..users = json['users'] as Map<String, dynamic>;
}

Map<String, dynamic> _$BmobRoleToJson(BmobRole instance) => <String, dynamic>{
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'objectId': instance.objectId,
      'ACL': instance.ACL,
      'name': instance.name,
      'roles': instance.roles,
      'users': instance.users
    };
