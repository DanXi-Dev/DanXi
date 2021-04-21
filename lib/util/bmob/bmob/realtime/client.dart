import 'package:dan_xi/util/bmob/bmob/response/bmob_error.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:io';

import '../bmob.dart';
import '../bmob_dio.dart';
import 'change.dart';
import 'message.dart';

import 'dart:convert';

class Client {
  ///更新表
  static const String ACTION_UPDATE_TABLE = "updateTable";

  ///删除表
  static const String ACTION_DELETE_TABLE = "deleteTable";

  ///更新行
  static const String ACTION_UPDATE_ROW = "updateRow";

  ///删除行
  static const String ACTION_DELETE_ROW = "deleteRow";

  /// 数据监听服务器主机地址
  static const String DEFAULT_REAL_TIME_DATA_HOST_HTTP =
      "http://io.bmob.cn:3010/socket.io/1/";

  static const String DEFAULT_REAL_TIME_DATA_HOST_WS =
      "ws://io.bmob.cn:3010/socket.io/1/";

  static const String DEFAULT_REAL_TIME_DATA_HOST_WSS =
      "wss://io.bmob.cn:3010/socket.io/1/";

  /// 数据监听websocket协议路径
  static const String DEFAULT_REAL_TIME_DATA_PATH_WEBSOCKET = "websocket/";

  /// websocket协议
  static const String PROTOCOL_WEBSOCKET = "websocket";

  /// await关键字必须在async函数内部使用。
  /// 调用async函数必须使用await关键字。
  /// Future最主要的功能就是提供了链式调用。
  Future<dynamic> getServerConfiguration() async {
    return BmobDio.getInstance().getByUrl(DEFAULT_REAL_TIME_DATA_HOST_HTTP);
  }

  WebSocket webSocket;

  ///监听
  Future listen(
      {connectedCallback,
      disconnectedCallback,
      dataChangedCallback,
      errorCallback}) async {
    getServerConfiguration().then((data) {
      /**
       * 规则：冒号分割
       */
      String result = data.toString();
      List<String> parts = result.split(":");
      /**
       * 会话
       */
      String session = parts[0];
      /**
       * 心跳
       */
      String heartbeat = parts[1];
      /**
       * 传输
       */
      String transportsLine = parts[3];
      /**
       * 心跳，默认为0，规则：/2*1000
       */
      int heartbeatInt = 0;
      if (heartbeat.isNotEmpty) {
        int hb = int.parse(heartbeat);
        heartbeatInt = (hb * 1000);
      }

      /**
       * 传输协议，判断是否包含websocket协议传输，规则：逗号分割
       */
      List<String> transports = transportsLine.split(",");
      if (!transports.contains(PROTOCOL_WEBSOCKET)) {
        errorCallback(new BmobError(9015, "websocket not supported"));
      } else {
        ///获取配置信息成功后开始进行连接
        connect(session, heartbeatInt, onConnected: (Client client) {
          connectedCallback(client);
        }, onDisconnected: (Client client) {
          disconnectedCallback();
        }, onDataChanged: (Change change) {
          dataChangedCallback(change);
        }, onError: (BmobError error) {
          errorCallback(error);
        });
      }
    }).catchError((e) {
      errorCallback(e);
    });
  }

  /// 开始连接
  void connect(String session, int heartbeat,
      {onConnected, onDisconnected, onDataChanged, onError}) async {
    String requestUrl =
        "$DEFAULT_REAL_TIME_DATA_HOST_WS$DEFAULT_REAL_TIME_DATA_PATH_WEBSOCKET$session";
    Map<String, String> map = Map();

    map["GET"] = "HTTP/1.1";
    map["Upgrade"] = "websocket";
    map["Connection"] = "Upgrade";
    map["Host"] = "io.bmob.cn";
    map["Origin"] = "http://io.bmob.cn";
    map["User-Agent"] = "android-websockets-2.0";
    map["Sec-WebSocket-Version"] = "13";

    webSocket = await WebSocket.connect(requestUrl, headers: map);
    webSocket.listen((event) {
      String data = event.toString();

      List<String> parts = data.split(":");

      int code = int.parse(parts[0]);

      switch (code) {
        case 0:
          // disconnect
          onDisconnected(this);

          webSocket.add("0::");
          break;
        case 1:
          // connect
          onConnected(this);

          webSocket.add("1::");
          break;
        case 2:
          // heartbeat
          webSocket.add("2::");
          break;
        case 3:
          {
            // string message
            break;
          }
        case 4:
          {
            // json message
            String json = "";
            int i = 0;
            for (String string in parts) {
              if (i >= 3) {
                json = json + string;
              }
              i++;
            }
            break;
          }
        case 5:
          {
            //data change message

            String data = "";
            int i = 0;
            for (String string in parts) {
              if (i == 3) {
                data = data + string;
              }
              if (i > 3) {
                data = data + ":" + string;
              }
              i++;
            }

            ///5:::{"name":"server_pub","args":["{\"appKey\":\"12784168944a56ae41c4575686b7b332\",\"tableName\":\"Blog\",\"objectId\":\"\",\"action\":\"updateTable\",\"data\":{\"author\":\"7c7fd3afe1\",\"content\":\"博客内容\",\"createdAt\":\"2019-04-26 15:55:12\",\"like\":77,\"objectId\":\"8913e0b65f\",\"title\":\"博客标题\",\"updatedAt\":\"2019-04-26 15:55:12\"}}"]}
            Map<String, dynamic> map = json.decode(data);
            Message message = Message.fromJson(map);

            ///{"appKey":"12784168944a56ae41c4575686b7b332","tableName":"Blog","objectId":"","action":"updateTable","data":{"author":"7c7fd3afe1","content":"博客内容","createdAt":"2019-04-26 15:55:12","like":77,"objectId":"8913e0b65f","title":"博客标题","updatedAt":"2019-04-26 15:55:12"}}
            ///服务端发送消息给客户端，数据变化
            if (message.name.isNotEmpty && message.name == "server_pub") {
              String arg = message.args[0];
              Map<String, dynamic> map = json.decode(arg);
              Change change = Change.fromJson(map);
              onDataChanged(change);
            }
            break;
          }
        case 6:
          // ack
          final List<String> ackParts = parts[3].split("\\+");
          List<String> arguments = List();
          if (ackParts.length == 2) {
            arguments[1] = ackParts[1];
          }
          String data = "";
          if (arguments != null) {
            data += "+" + arguments.toString();
          }
          String part = parts[1];
          String ack = "6::$part$data";
          webSocket.add(ack);
          break;
        case 7:
          // error
          onError(new BmobError(int.parse(parts[2]), parts[3]));
          break;
        case 8:
          // noop
          break;
        default:
          throw new Exception("unknown code");
      }
    }, onDone: () {
      webSocket.add("1::");
      webSocket.add("2::");
    }, onError: (error) {
      onError(new BmobError(9015, error.toString()));
    }, cancelOnError: true);
  }

  /// 关闭连接
  void close() {
    if (webSocket != null) {
      webSocket.close();
    }
  }

  /// 监听表数据更新
  ///
  /// @param tableName 监听的表名
  Future subTableUpdate(String tableName) async {
    List<String> args = List();
    args.add(getArgs(tableName, "", ACTION_UPDATE_TABLE));
    emit("client_sub", args);
  }

  /// 取消监听表数据更新
  ///
  /// @param tableName 取消监听的表名
  Future unsubTableUpdate(String tableName) async {
    List<String> args = List();
    args.add(getArgs(tableName, "", "unsub_updateTable"));
    emit("client_unsub", args);
  }

  /// 监听表删除
  ///
  /// @param tableName 监听的表名
  Future subTableDelete(String tableName) async {
    List<String> args = List();
    args.add(getArgs(tableName, "", ACTION_DELETE_TABLE));
    emit("client_sub", args);
  }

  /// 取消监听表删除
  ///
  /// @param tableName 取消监听的表名
  Future unsubTableDelete(String tableName) async {
    List<String> args = List();
    args.add(getArgs(tableName, "", "unsub_deleteTable"));
    emit("client_unsub", args);
  }

  /// 监听行数据更新
  ///
  /// @param tableName 监听的表名
  /// @param objectId  监听的行Id
  Future subRowUpdate(String tableName, String objectId) async {
    List<String> args = List();
    args.add(getArgs(tableName, objectId, ACTION_UPDATE_ROW));
    emit("client_sub", args);
  }

  /// 取消监听行数据更新
  ///
  /// @param tableName 取消监听的表名
  /// @param objectId  取消监听的行Id
  Future unsubRowUpdate(String tableName, String objectId) async {
    List<String> args = List();
    args.add(getArgs(tableName, objectId, "unsub_updateRow"));
    emit("client_unsub", args);
  }

  /// 监听数据行删除
  ///
  /// @param tableName 监听的表名
  /// @param objectId  监听的行Id
  Future subRowDelete(String tableName, String objectId) async {
    List<String> args = List();
    args.add(getArgs(tableName, objectId, ACTION_DELETE_ROW));
    emit("client_sub", args);
  }

  /// 取消监听数据行删除
  ///
  /// @param tableName 取消监听的表名
  /// @param objectId  取消监听的行Id
  Future unsubRowDelete(String tableName, String objectId) async {
    List<String> args = List();
    args.add(getArgs(tableName, objectId, "unsub_deleteRow"));
    emit("client_unsub", args);
  }

  String getArgs(String tableName, String objectId, String action) {
    Map<String, dynamic> map = Map();
    map["appKey"] = Bmob.bmobAppId;
    map["tableName"] = tableName;
    map["objectId"] = objectId;
    map["action"] = action;
    String args = json.encode(map);
    return args;
  }

  Future emit(String name, List<String> args) async {
    Map<String, dynamic> data = Map();

    data["name"] = name;
    data["args"] = args;
    String send = json.encode(data);
    emitRaw(5, send);
  }

  int ackCount = 0;

  Future emitRaw(int type, String message) async {
    String id = "$ackCount";
    String ack = id + "+";
    String data = "$type:$ack::$message";
    //5:0+::{"name":"client_sub","args":["{\"appKey\":\"d59c62906f447317e41cea2fe47ef856\",\"tableName\":\"Category\",\"objectId\":\"\",\"action\":\"updateTable\"}"]}
    webSocket.add(data);
    ackCount++;
  }
}
