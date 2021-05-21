import '../bmob_dio.dart';
import 'dart:convert';
import '../bmob.dart';
import '../response/bmob_saved.dart';
import '../response/bmob_error.dart';
import '../response/bmob_handled.dart';
import '../response/bmob_updated.dart';
import '../type/bmob_acl.dart';
import '../bmob_utils.dart';
import '../type/bmob_geo_point.dart';
import '../type/bmob_date.dart';
import '../type/bmob_file.dart';
import '../type/bmob_relation.dart';

///Bmob对象基本类型
abstract class BmobObject {
  //创建时间
  String createdAt;

  void setCreatedAt(String createdAt) {
    this.createdAt = createdAt;
  }

  String getCreatedAt() {
    return this.createdAt;
  }

  //更新时间
  String updatedAt;

  void setUpdatedAt(String updatedAt) {
    this.updatedAt = updatedAt;
  }

  String getUpdatedAt() {
    return this.updatedAt;
  }

  //唯一标志
  String objectId;

  void setObjectId(String objectId) {
    this.objectId = objectId;
  }

  String getObjectId() {
    return this.objectId;
  }

  //访问控制权限
  // ignore: non_constant_identifier_names
  Map<String, Object> ACL;

  void setAcl(BmobAcl bmobAcl) {
    this.ACL = bmobAcl.acl;
  }

  BmobAcl getAcl() {
    BmobAcl bmobAcl = BmobAcl();
    bmobAcl.acl = this.ACL;
    return bmobAcl;
  }

  BmobObject();

  Map getParams();

  ///新增一条数据
  Future<BmobSaved> save() async {
    Map<String, dynamic> map = getParams();
    String params = getParamsJsonFromParamsMap(map);
    String tableName = BmobUtils.getTableName(this);
    switch (tableName) {
      case "BmobInstallation":
        tableName = "_Installation";
        break;
    }
    Map responseData = await BmobDio.getInstance()
        .post(Bmob.BMOB_API_CLASSES + tableName, data: params);
    BmobSaved bmobSaved = BmobSaved.fromJson(responseData);
    return bmobSaved;
  }

  ///修改一条数据
  Future<BmobUpdated> update() async {
    Map<String, dynamic> map = getParams();
    String objectId = map[Bmob.BMOB_PROPERTY_OBJECT_ID];
    if (objectId.isEmpty || objectId == null) {
      BmobError bmobError =
          new BmobError(Bmob.BMOB_ERROR_CODE_LOCAL, Bmob.BMOB_ERROR_OBJECT_ID);
      throw bmobError;
    } else {
      String params = getParamsJsonFromParamsMap(map);
      String tableName = BmobUtils.getTableName(this);
      Map responseData = await BmobDio.getInstance().put(
          Bmob.BMOB_API_CLASSES + tableName + Bmob.BMOB_API_SLASH + objectId,
          data: params);
      BmobUpdated bmobUpdated = BmobUpdated.fromJson(responseData);
      return bmobUpdated;
    }
  }

  ///删除一条数据
  Future<BmobHandled> delete() async {
    Map<String, dynamic> map = getParams();
    String objectId = map[Bmob.BMOB_PROPERTY_OBJECT_ID];
    if (objectId.isEmpty || objectId == null) {
      BmobError bmobError =
          new BmobError(Bmob.BMOB_ERROR_CODE_LOCAL, Bmob.BMOB_ERROR_OBJECT_ID);
      throw bmobError;
    } else {
      String tableName = BmobUtils.getTableName(this);
      Map responseData = await BmobDio.getInstance().delete(
          Bmob.BMOB_API_CLASSES + tableName + Bmob.BMOB_API_SLASH + objectId);
      BmobHandled bmobHandled = BmobHandled.fromJson(responseData);
      return bmobHandled;
    }
  }

  ///删除某条数据的某个字段的值
  Future<BmobUpdated> deleteFieldValue(String fieldName) async {
    Map<String, dynamic> map = getParams();
    String objectId = map[Bmob.BMOB_PROPERTY_OBJECT_ID];
    if (objectId.isEmpty || objectId == null) {
      BmobError bmobError =
          new BmobError(Bmob.BMOB_ERROR_CODE_LOCAL, Bmob.BMOB_ERROR_OBJECT_ID);
      throw bmobError;
    } else {
      String tableName = BmobUtils.getTableName(this);
      Map<String, String> delete = Map();
      delete['__op'] = 'Delete';
      Map<String, dynamic> params = Map();
      params[fieldName] = delete;
      String body = json.encode(params);
      Map responseData = await BmobDio.getInstance().put(
          Bmob.BMOB_API_CLASSES + tableName + Bmob.BMOB_API_SLASH + objectId,
          data: "$body");
      BmobUpdated bmobUpdated = BmobUpdated.fromJson(responseData);
      return bmobUpdated;
    }
  }

  ///获取请求参数，去掉服务器生成的字段值，将对象类型修改成pointer结构，去掉空值
  String getParamsJsonFromParamsMap(map) {
    Map<String, dynamic> data = new Map();
    //去除由服务器生成的字段值
    if (map == null) {
      print("请先在继承类中实现BmobObject中的Map getParams()方法！");
    }
    map.remove(Bmob.BMOB_PROPERTY_OBJECT_ID);
    map.remove(Bmob.BMOB_PROPERTY_CREATED_AT);
    map.remove(Bmob.BMOB_PROPERTY_UPDATED_AT);
    map.remove(Bmob.BMOB_PROPERTY_SESSION_TOKEN);

    map.forEach((key, value) {
      //去除空值
      if (value != null) {
        if (value is BmobObject) {
          //Pointer类型
          BmobObject bmobObject = value;
          String objectId = bmobObject.objectId;
          if (objectId == null) {
            data.remove(key);
          } else {
            Map pointer = new Map();
            pointer[Bmob.BMOB_PROPERTY_OBJECT_ID] = objectId;
            pointer[Bmob.BMOB_KEY_TYPE] = Bmob.BMOB_TYPE_POINTER;
            pointer[Bmob.BMOB_KEY_CLASS_NAME] = BmobUtils.getTableName(value);
            data[key] = pointer;
          }
        } else if (value is BmobGeoPoint) {
          BmobGeoPoint bmobGeoPoint = value;
          data[key] = bmobGeoPoint.toJson();
        } else if (value is BmobDate) {
          BmobDate bmobDate = value;
          data[key] = bmobDate.toJson();
        } else if (value is BmobFile) {
          BmobFile bmobFile = value;
          Map map = bmobFile.toJson();
          map["group"] = map["cdn"];
          map.remove("cdn");
          map["__type"] = "File";
          data[key] = map;
        } else if (value is BmobRelation) {
          BmobRelation bmobRelation = value;
          data[key] = bmobRelation.toJson();
        } else {
          //非Pointer类型
          data[key] = value;
        }
      }
    });
    //dart:convert，Map转String
    String params = json.encode(data);
    return params;
  }
}
