import '../response/bmob_error.dart';

import 'change.dart';
import 'client.dart';

import 'dart:async';

class RealTimeDataManager {
  static RealTimeDataManager? instance;

  RealTimeDataManager();

  ///单例
  static RealTimeDataManager? getInstance() {
    if (instance == null) {
      instance = new RealTimeDataManager();
    }
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
