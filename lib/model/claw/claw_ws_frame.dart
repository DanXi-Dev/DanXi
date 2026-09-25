import 'package:dan_xi/model/claw/claw_message.dart';

sealed class ClawWsInFrame {
  const ClawWsInFrame._();

  factory ClawWsInFrame.fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'auth_success' => WsAuthSuccess(),
      'message' => WsMessageReceived(ClawMessage.fromJson(json)),
      'ping' => WsPing(
        timestamp: json['timestamp'] as int,
        version: json['version'] as String?,
      ),
      'error' => WsError(json['message'] as String? ?? 'Unknown error'),
      _ => WsUnknown(json['type'] as String? ?? '(null)'),
    };
  }
}

class WsAuthSuccess extends ClawWsInFrame {
  const WsAuthSuccess() : super._();
}

class WsMessageReceived extends ClawWsInFrame {
  final ClawMessage message;

  const WsMessageReceived(this.message) : super._();
}

class WsPing extends ClawWsInFrame {
  final int timestamp;
  final String? version;

  const WsPing({required this.timestamp, this.version}) : super._();
}

class WsError extends ClawWsInFrame {
  final String message;

  const WsError(this.message) : super._();
}

class WsUnknown extends ClawWsInFrame {
  final String type;

  const WsUnknown(this.type) : super._();
}

sealed class ClawWsOutFrame {
  static const String kVersion = '1.0';

  const ClawWsOutFrame._();

  Map<String, dynamic> toJson();
}

class WsAuth extends ClawWsOutFrame {
  final String token;
  final int timestamp;
  final String version;

  const WsAuth({
    required this.token,
    required this.timestamp,
    this.version = ClawWsOutFrame.kVersion,
  }) : super._();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'auth',
    'token': token,
    'timestamp': timestamp,
    'version': version,
  };
}

class WsSendMessage extends ClawWsOutFrame {
  final int channelId;
  final String content;
  final String messageId;
  final int timestamp;
  final String version;

  const WsSendMessage({
    required this.channelId,
    required this.content,
    required this.messageId,
    required this.timestamp,
    this.version = ClawWsOutFrame.kVersion,
  }) : super._();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'message',
    'from': 'user',
    'content': content,
    'message_id': messageId,
    'channel_id': channelId,
    'timestamp': timestamp,
    'media': {},
    'version': version,
  };
}

class WsPong extends ClawWsOutFrame {
  final int timestamp;
  final String version;

  const WsPong({
    required this.timestamp,
    this.version = ClawWsOutFrame.kVersion,
  }) : super._();

  @override
  Map<String, dynamic> toJson() => {
    'type': 'pong',
    'timestamp': timestamp,
    'version': version,
  };
}
