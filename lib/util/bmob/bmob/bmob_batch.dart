import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bmob.dart';
import 'table/bmob_object.dart';
import 'table/bmob_user.dart';

class BmobBatch {
  Future<List> insertBatch(List<BmobObject> bmobObjects) async {
    return process("POST", bmobObjects);
  }

  Future<List> deleteBatch(List<BmobObject> bmobObjects) async {
    return process("DELETE", bmobObjects);
  }

  Future<List> updateBatch(List<BmobObject> bmobObjects) async {
    return process("PUT", bmobObjects);
  }

  Future<List> process(String method, List<BmobObject> bmobObjects) async {
    List list = [];
    Map params = {};

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.get("user") as String?;
    BmobUser? bmobUser;
    if (userJson != null) {
      bmobUser = json.decode(userJson);
    }

    for (BmobObject bmobObject in bmobObjects) {
      if (bmobObject is BmobUser) {
        //过滤BmobUser类型的处理，因为批处理操作不支持对User表的操作
        debugPrint("BmobUser does not support batch operations");
      } else {
        Map single = {};
        single["method"] = method;
        if (method == "PUT" || method == "DELETE") {
          //批量更新和批量删除
          if (userJson != null) {
            single["token"] = bmobUser!.sessionToken;
          }
          single["path"] = Bmob.BMOB_API_CLASSES +
              bmobObject.runtimeType.toString() +
              "/" +
              bmobObject.objectId!;
        } else {
          //批量添加
          single["path"] =
              Bmob.BMOB_API_CLASSES + bmobObject.runtimeType.toString();
        }

        Map body = bmobObject.getParams();
        Map tmp = bmobObject.getParams();
        tmp.forEach((key, value) {
          if (value == null) {
            body.remove(key);
          }
        });
        single["body"] = body;

        body.remove("objectId");
        body.remove("createdAt");
        body.remove("updatedAt");

        list.add(single);
      }
    }
    params["requests"] = list;

    return list;
  }
}
