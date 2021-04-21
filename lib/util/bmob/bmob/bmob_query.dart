import 'bmob_dio.dart';
import 'response/bmob_results.dart';
import 'table/bmob_installation.dart';
import 'table/bmob_role.dart';
import 'package:dio/dio.dart';

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'bmob.dart';
import 'table/bmob_user.dart';
import 'table/bmob_object.dart';
import 'type/bmob_pointer.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_query.g.dart';

///查询数据，包括单条数据查询和多条数据查询
@JsonSerializable()
class BmobQuery<T> {
  String include;
  int limit;
  int skip;
  String order;
  int count;

  String c;

  Map<String, dynamic> where;

  Map<String, dynamic> having;

  /// 统计查询
  String groupby;
  String sum;
  String average;
  String max;
  String min;
  bool groupcount;

  BmobQuery() {
    where = Map();
    having = Map();
  }

  //添加等于条件查询
  BmobQuery addWhereEqualTo(String key, Object value) {
    addCondition(key, null, value);
    return this;
  }

  //添加不等于查询
  BmobQuery addWhereNotEqualTo(String key, Object value) {
    addCondition(key, "\$ne", value);
    return this;
  }

  //添加小于查询
  BmobQuery addWhereLessThan(String key, Object value) {
    addCondition(key, "\$lt", value);
    return this;
  }

  //添加小于等于查询
  BmobQuery addWhereLessThanOrEqualTo(String key, Object value) {
    addCondition(key, "\$lte", value);
    return this;
  }

  //添加大于查询
  BmobQuery addWhereGreaterThan(String key, Object value) {
    addCondition(key, "\$gt", value);
    return this;
  }

  //添加大于等于查询
  BmobQuery addWhereGreaterThanOrEqualTo(String key, Object value) {
    addCondition(key, "\$gte", value);
    return this;
  }

  //复合查询条件or
  BmobQuery or(List<BmobQuery<T>> queries) {
    List<Map<String, dynamic>> list = List();
    for (BmobQuery<T> bmobQuery in queries) {
      list.add(bmobQuery.where);
    }
    addCondition("\$or", null, list);
    return this;
  }

  //复合查询条件and
  BmobQuery and(List<BmobQuery<T>> queries) {
    List<Map<String, dynamic>> list = List();
    for (BmobQuery<T> bmobQuery in queries) {
      list.add(bmobQuery.where);
    }
    addCondition("\$and", null, list);
    return this;
  }

  BmobQuery addWhereContains(String key, Object value) {
    String regex = "\\Q" + value + "\\E";
    addWhereMatches(key, regex);
    return this;
  }

  void addWhereMatches(String key, String regex) {
    addCondition(key, "\$regex", regex);
  }

  BmobQuery addWhereExists(String key) {
    addCondition(key, "\$exists", true);
    return this;
  }

  BmobQuery addWhereDoesNotExists(String key) {
    addCondition(key, "\$exists", false);
    return this;
  }

  ///是否返回统计的记录个数
  BmobQuery hasGroupCount(bool has) {
    this.groupcount = has;
    return this;
  }

  ///分组 多个分组的列名
  BmobQuery groupByKeys(String keys) {
    this.groupby = keys;
    return this;
  }

  ///求和  多个求和的列名
  BmobQuery sumKeys(String keys) {
    this.sum = keys;
    return this;
  }

  ///求均值 多个求平均值的列名
  BmobQuery averageKeys(String keys) {
    this.average = keys;
    return this;
  }

  ///求最大值 多个求最大值的列名
  BmobQuery maxKeys(String keys) {
    this.max = keys;
    return this;
  }

  ///求最小值 多个求最小值的列名
  BmobQuery minKeys(String keys) {
    this.min = keys;
    return this;
  }

  ///获取数据个数
  Future<int> queryCount() async {
    this.count = 1;
    this.limit = 0;

    String tableName = T.toString();
    if (T.runtimeType is BmobUser) {
      tableName = "_User";
    } else if (T.runtimeType is BmobInstallation) {
      tableName = "_Installation";
    }
    String url = Bmob.BMOB_API_CLASSES + tableName;
    url = url + "?";
    if (where.isNotEmpty) {
      url = url + "where=" + json.encode(where);
    }
    Map map = await BmobDio.getInstance().get(url, data: getParams());
    print(map);
    BmobResults bmobResults = BmobResults.fromJson(map);
    return bmobResults.count;
  }

  ///添加分组过滤条件
  BmobQuery havingFilter(Map<String, dynamic> having) {
    this.having = having;
    return this;
  }

  String addStatistics(String key, Object value) {
    if (value == null) {
      return "";
    }
    String params = "";
    if (value is String) {
      String str = value;
      params = key + "=" + str + "&";
    } else if (value is Map) {
      Map map = value;
      if (map.isNotEmpty) {
        params = key + "=" + json.encode(map) + "&";
      }
    }
    return params;
  }

  String getStatistics() {
    String statistics = "";
    statistics += addStatistics("sum", this.sum);
    statistics += addStatistics("max", this.max);
    statistics += addStatistics("min", this.min);
    statistics += addStatistics("average", this.average);
    statistics += addStatistics("groupby", this.groupby);
    statistics += addStatistics("having", this.having);
    statistics += addStatistics("groupcount", this.groupcount);
    return statistics;
  }

  void addCondition(String key, String condition, Object value) {
    if (condition == null) {
      if (value is BmobUser) {
        BmobUser bmobUser = value;
        Map<String, dynamic> map = new Map();
        map["__type"] = "Pointer";
        map["objectId"] = bmobUser.objectId;
        map["className"] = "_User";
        where[key] = map;
      } else if (value is BmobObject) {
        BmobObject bmobObject = value;
        Map<String, dynamic> map = new Map();
        map["__type"] = "Pointer";
        map["objectId"] = bmobObject.objectId;
        map["className"] = value.runtimeType.toString();
        where[key] = map;
      } else if (value is BmobPointer) {
        Map<String, dynamic> map = new Map();
        map["object"] = value;
        where[key] = map;
      } else {
        where[key] = value;
      }
    } else {
      if (value is BmobUser) {
        BmobUser bmobUser = value;
        Map<String, dynamic> map = new Map();
        map["__type"] = "Pointer";
        map["objectId"] = bmobUser.objectId;
        map["className"] = "_User";

        Map<String, dynamic> map1 = new Map();
        map1[condition] = map;
        where[key] = map1;
      } else if (value is BmobObject) {
        BmobObject bmobObject = value;
        Map<String, dynamic> map = new Map();
        map["__type"] = "Pointer";
        map["objectId"] = bmobObject.objectId;
        map["className"] = value.runtimeType.toString();

        Map<String, dynamic> map1 = new Map();
        map1[condition] = map;
        where[key] = map1;
      } else {
        Map<String, dynamic> map = new Map();
        map[condition] = value;
        where[key] = map;
      }
    }
  }

  //查询关联字段
  BmobQuery setInclude(String value) {
    include = value;
    return this;
  }

  //按字段排序
  BmobQuery setOrder(String value) {
    order = value;
    return this;
  }

  //返回条数
  BmobQuery setLimit(int value) {
    limit = value;
    return this;
  }

  //忽略条数
  BmobQuery setSkip(int value) {
    skip = value;
    return this;
  }

  ///查询单条数据
  Future<dynamic> queryUser(objectId) async {
    return queryObjectByTableName(objectId, "_User");
  }

  ///查询单条数据
  Future<dynamic> queryInstallation(objectId) async {
    return queryObjectByTableName(objectId, "_Installation");
  }

  ///查询单条数据
  Future<dynamic> queryObject(objectId) async {
    String tableName = T.toString();
    return queryObjectByTableName(objectId, tableName);
  }

  ///查询单条数据
  Future<dynamic> queryObjectByTableName(objectId, String tableName) async {
//    String tableName = T.toString();
//    if (T.runtimeType is BmobUser) {
//      tableName = "_User";
//    } else if (T.runtimeType is BmobInstallation) {
//      tableName = "_Installation";
//    }
    return BmobDio.getInstance().get(
        Bmob.BMOB_API_CLASSES + tableName + Bmob.BMOB_API_SLASH + objectId,
        data: getParams());
  }

  ///查询多条数据
  Future<List<dynamic>> queryUsers() async {
    return queryObjectsByTableName("_User");
  }

  ///查询多条数据
  Future<List<dynamic>> queryInstallations() async {
    return queryObjectsByTableName("_Installation");
  }

  ///查询多条数据
  Future<List<dynamic>> queryObjects() async {
    String tableName = T.toString();
    return queryObjectsByTableName(tableName);
  }

  ///查询多条数据
  Future<List<dynamic>> queryObjectsByTableName(String tableName) async {
//    String tableName = T.toString();
//    if (T.runtimeType is BmobUser) {
//      tableName = "_User";
//    } else if (T.runtimeType is BmobInstallation) {
//      tableName = "_Installation";
//    }
    String url = Bmob.BMOB_API_CLASSES + tableName;
    if (where.isNotEmpty) {
      url = url + "?";
      url = url + "where=" + json.encode(where);
    }
    url = url + getStatistics();
    Map map = await BmobDio.getInstance().get(url, data: getParams());
    BmobResults bmobResults = BmobResults.fromJson(map);
    print(bmobResults.results);
    return bmobResults.results;
  }

  ///此处与类名一致，由指令自动生成代码
  factory BmobQuery.fromJson(Map<String, dynamic> json) =>
      _$BmobQueryFromJson(json);

  ///此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobQueryToJson(this);

  ///获取请求参数
  Map getParams() {
    Map map = toJson();
    Map params = toJson();
    map.forEach((k, v) {
      if (v == null) {
        params.remove(k);
      }
    });
    return params;
  }
}
