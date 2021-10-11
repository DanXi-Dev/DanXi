import 'dart:async';

import 'bmob_dio.dart';
import 'bmob.dart';
import 'response/server_time.dart';

class BmobDateManager {
  ///查询服务器时间
  static Future<ServerTime> getServerTimestamp() async {
    Map data = await (BmobDio.getInstance()!
            .get(Bmob.BMOB_API_VERSION + Bmob.BMOB_API_TIMESTAMP)
        as FutureOr<Map<dynamic, dynamic>>);
    ServerTime serverTime = ServerTime.fromJson(data as Map<String, dynamic>);
    return serverTime;
  }
}
