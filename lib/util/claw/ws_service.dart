import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dan_xi/model/claw/claw_message.dart';
import 'package:dan_xi/model/claw/claw_ws_frame.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';

class ClawWebSocketService {
  static const String _wsUrl = 'ws://127.0.0.1:8000/api/claw/ws';

  WebSocket? _ws;

  final StreamController<ClawMessage> _messageController =
      StreamController.broadcast();

  Stream<ClawMessage> get messages => _messageController.stream;

  bool _connected = false;

  bool get isConnected => _connected;

  static final _instance = ClawWebSocketService._();

  factory ClawWebSocketService.getInstance() => _instance;

  ClawWebSocketService._();

  Future<void> connect() async {
    if (_connected) return;
    final ws = await WebSocket.connect(_wsUrl).timeout(
      const Duration(milliseconds: 16384),
      onTimeout: () =>
          throw TimeoutException('DantaClaw WebSocket connection timed out'),
    );
    _ws = ws;

    ws.listen(
      (data) {
        try {
          final frame = ClawWsInFrame.fromJson(
            jsonDecode(data as String) as Map<String, dynamic>,
          );
          switch (frame) {
            case WsAuthSuccess():
              _connected = true;
            case WsMessageReceived(:final message):
              _messageController.add(message);
            case WsPing(:final version):
              send(
                WsPong(
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  version: version ?? ClawWsOutFrame.kVersion,
                ),
              );
            case WsError():
            case WsUnknown():
              // Ignore errors for now.
              break;
          }
        } catch (_) {}
      },
      onDone: () {
        _connected = false;
        _ws = null;
      },
      onError: (e) {
        _connected = false;
        _ws = null;
      },
    );

    final token = ClawRepository.getInstance().token;
    send(
      WsAuth(token: token, timestamp: DateTime.now().millisecondsSinceEpoch),
    );
  }

  void sendMessage({
    required int channelId,
    required String content,
    required String messageId,
  }) {
    send(
      WsSendMessage(
        channelId: channelId,
        content: content,
        messageId: messageId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void send(ClawWsOutFrame frame) {
    _ws?.add(jsonEncode(frame.toJson()));
  }

  void disconnect() {
    _ws?.close();
    _ws = null;
    _connected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
