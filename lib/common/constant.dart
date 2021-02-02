import 'package:event_bus/event_bus.dart';

class Constant {
  static const campusArea = ['邯郸校区', '枫林校区', '江湾校区', '张江校区'];
  static EventBus eventBus = EventBus();
}

enum ConnectionStatus { NONE, CONNECTING, DONE, FAILED, FATAL_ERROR }
