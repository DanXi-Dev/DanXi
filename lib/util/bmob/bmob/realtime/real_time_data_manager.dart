import 'dart:async';

import '../response/bmob_error.dart';
import 'change.dart';
import 'client.dart';

class RealTimeDataManager {
  static RealTimeDataManager? instance;

  RealTimeDataManager();

  ///单例
  static RealTimeDataManager? getInstance() {
    instance ??= RealTimeDataManager();
    return instance;
  }

  ///数据监听
  Future listen({onConnected, onDisconnected, onDataChanged, onError}) async {
    Client client = Client();
    client.listen(connectedCallback: (Client client) {
      onConnected(client);
    }, disconnectedCallback: (Client client) {
      onDisconnected(client);
    }, dataChangedCallback: (Change change) {
      onDataChanged(change);
    }, errorCallback: (BmobError error) {
      onError(error);
    });
  }
}
