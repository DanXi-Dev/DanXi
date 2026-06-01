import 'dart:convert';

import 'package:dan_xi/model/claw/claw_message.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';
import 'package:dan_xi/util/claw/ws_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

sealed class ChannelId {
  const ChannelId._();

  int get asInt;

  factory ChannelId.fromIntOrNull(int? id) =>
      (id != null && id > 0) ? SomeChannelId(id) : const NewChannelId();

  @override
  bool operator ==(Object other) => switch ((this, other)) {
    (NewChannelId(), NewChannelId()) => true,
    (SomeChannelId(id: final id0), SomeChannelId(id: final id1)) => id0 == id1,
    _ => false,
  };

  @override
  int get hashCode => asInt.hashCode;
}

class NewChannelId extends ChannelId {
  const NewChannelId() : super._();

  /// The backend uses channel_id 0 to indicate a new channel.
  @override
  int get asInt => 0;
}

class SomeChannelId extends ChannelId {
  final int id;

  const SomeChannelId(this.id) : assert(id > 0), super._();

  @override
  int get asInt => id;
}

sealed class ChatError {
  const ChatError._();
}

class NoError extends ChatError {
  const NoError() : super._();
}

class SomeError extends ChatError {
  final Object error;

  const SomeError(this.error) : super._();
}

class ClawChatState {
  final List<ClawMessage> messages;
  final bool loading;
  final ChatError error;
  final bool sending;

  const ClawChatState({
    this.messages = const [],
    this.loading = false,
    this.error = const NoError(),
    this.sending = false,
  });

  ClawChatState copyWith({
    List<ClawMessage>? messages,
    bool? loading,
    ChatError? error,
    bool? sending,
  }) {
    return ClawChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      sending: sending ?? this.sending,
    );
  }
}

class ClawChatNotifier extends Notifier<ClawChatState> {
  int _msgCounter = 0;

  @override
  ClawChatState build() => const ClawChatState();

  Future<void> loadMessages(ChannelId channelId) async {
    state = state.copyWith(loading: true, error: const NoError());
    try {
      // TODO: Load from end and expand in need.
      final msgs = <ClawMessage>[];
      if (channelId case SomeChannelId(id: final channelId)) {
        while (true) {
          final msgsSlice = await ClawRepository.getInstance().getMessages(
            channelId: channelId,
            sort: 'asc',
            offset: msgs.length,
          );
          if (msgsSlice.isEmpty) {
            break;
          }
          msgs.addAll(msgsSlice);
        }
      }
      state = ClawChatState(
        messages: msgs.reversed.toList(growable: false),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: SomeError(e));
    }
  }

  void sendMessage(ChannelId channelId, String text) {
    state = state.copyWith(sending: true);

    final messageId =
        'msg_${DateTime.now().millisecondsSinceEpoch}_${_msgCounter++}';

    ClawWebSocketService.getInstance().sendMessage(
      channelId: channelId.asInt,
      content: text,
      messageId: messageId,
    );

    final userMsg = ClawMessage(
      id: 0,
      type: 'message',
      from: 'user',
      content: text,
      messageId: messageId,
      channelId: channelId.asInt,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      media: {},
    );
    state = state.copyWith(messages: [userMsg, ...state.messages]);
  }

  void onWsMessage(ClawMessage msg) {
    state = state.copyWith(messages: [msg, ...state.messages], sending: false);
  }
}

final clawChatProvider = NotifierProvider<ClawChatNotifier, ClawChatState>(
  ClawChatNotifier.new,
);
