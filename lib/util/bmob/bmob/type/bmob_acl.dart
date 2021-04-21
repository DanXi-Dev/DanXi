import '../response/bmob_error.dart';

class BmobAcl {
  static const String READ = "read";
  static const String WRITE = "write";

  Map<String, dynamic> acl = Map();

  BmobAcl();

  void addAccess(String accessType, String userIdOrRoleName, bool allowed) {
    if (userIdOrRoleName == null || userIdOrRoleName.isEmpty) {
      throw BmobError(1001, "The userId is null or empty.");
    }
    if (acl.containsKey(userIdOrRoleName)) {
      Map<String, dynamic> map = acl[userIdOrRoleName];
      map[accessType] = allowed;
      acl[userIdOrRoleName] = map;
    } else {
      Map<String, dynamic> map = Map();
      map[accessType] = allowed;
      acl[userIdOrRoleName] = map;
    }
  }

  //添加某用户对该数据的读取权限规则
  void addUserReadAccess(String userId, bool allowed) {
    addAccess(READ, userId, allowed);
  }

  //添加某用户对该数据的写入权限规则
  void addUserWriteAccess(String userId, bool allowed) {
    addAccess(WRITE, userId, allowed);
  }

  //添加某角色对该数据的读取权限规则
  void addRoleReadAccess(String roleName, bool allowed) {
    addAccess(READ, "role:$roleName", allowed);
  }

  //添加某角色对该数据的写入权限规则
  void addRoleWriteAccess(String roleName, bool allowed) {
    addAccess(WRITE, "role:$roleName", allowed);
  }

  //设置所有用户对该数据的读取权限规则
  void setPublicWriteAccess(bool allowed) {
    addUserReadAccess("*", allowed);
  }

  //设置所有用户对该数据的写入权限规则
  void setPublicReadAccess(bool allowed) {
    addUserWriteAccess("*", allowed);
  }
}
