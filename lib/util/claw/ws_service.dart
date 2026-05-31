import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dan_xi/model/claw/claw_message.dart';
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
    final ws = await WebSocket.connect(_wsUrl);
    _ws = ws;

    ws.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final type = json['type'] as String?;

          switch (type) {
            case 'auth_success':
              _connected = true;
            case 'message':
              _messageController.add(ClawMessage.fromJson(json));
            case 'ping':
              _send({
                'type': 'pong',
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'version': '1.0',
              });
            case 'error':
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
    _send({
      'type': 'auth',
      'token': token,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0',
    });
  }

  void sendMessage({
    required int channelId,
    required String content,
    required String messageId,
  }) {
    _send({
      'type': 'message',
      'from': 'user',
      'content': content,
      'message_id': messageId,
      'channel_id': channelId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'media': {},
      'version': '1.0',
    });
  }

  void _send(Map<String, dynamic> message) {
    _ws?.add(jsonEncode(message));
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
