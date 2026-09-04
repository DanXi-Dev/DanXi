import 'dart:collection';
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

class BidiList<T> extends ListBase<T> {
  final List<T> backward; // Newest first.
  final List<T> forward; // Oldest first.

  BidiList(this.backward, this.forward);

  @override
  int get length => forward.length + backward.length;

  @override
  set length(int value) => throw UnsupportedError('Read-only view');

  @override
  T operator [](int index) => index < forward.length
      ? forward[forward.length - index - 1]
      : backward[index - forward.length];

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Read-only view');
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
  final List<ClawMessage> httpMessages; // Extended towards the past.
  final List<ClawMessage> wsMessages; // Extended towards the future.
  final bool loading;
  final ChatError error;
  final bool sending;

  const ClawChatState({
    this.httpMessages = const [],
    this.wsMessages = const [],
    this.loading = false,
    this.error = const NoError(),
    this.sending = false,
  });

  BidiList<ClawMessage> get mergedMessages =>
      BidiList(httpMessages, wsMessages);

  ClawChatState copyWith({
    List<ClawMessage>? httpMessages,
    List<ClawMessage>? wsMessages,
    bool? loading,
    ChatError? error,
    bool? sending,
  }) {
    return ClawChatState(
      httpMessages: httpMessages ?? this.httpMessages,
      wsMessages: wsMessages ?? this.wsMessages,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      sending: sending ?? this.sending,
    );
  }
}

class ClawChatNotifier extends Notifier<ClawChatState> {
  int _msgCounter = 0;
  ClawMessage? _pendingMsg;

  BidiList<ClawMessage> get mergedMessages =>
      BidiList(state.httpMessages, state.wsMessages);

  @override
  ClawChatState build() => const ClawChatState();

  Future<void> loadMessages(ChannelId channelId) async {
    state = state.copyWith(loading: true, error: const NoError());
    try {
      // TODO: Load from end and expand in need.
      final loadedMsgs = <ClawMessage>[];
      if (channelId case SomeChannelId(id: final channelId)) {
        while (true) {
          final msgsSlice = await ClawRepository.getInstance().getMessages(
            channelId: channelId,
            sort: 'asc',
            offset: loadedMsgs.length,
          );
          if (msgsSlice.isEmpty) {
            break;
          }
          loadedMsgs.addAll(msgsSlice);
        }
      }
      state = ClawChatState(
        httpMessages: loadedMsgs.reversed.toList(growable: false),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: SomeError(e));
    }
  }

  void sendMessage(
    ChannelId channelId,
    String text, {
    bool shouldPreserve = false,
  }) {
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
    if (shouldPreserve) {
      _pendingMsg = userMsg;
    }
    debugPrint("#### sendMessage ${jsonEncode(userMsg)}");
    state = state.copyWith(wsMessages: [...state.wsMessages, userMsg]);
  }

  Future<ClawMessage?> cancelSending(ChannelId channelId) async {
    if (!state.sending) return null;
    await loadMessages(channelId);
    return _pendingMsg;
  }

  void onWsMessage(ClawMessage msg) {
    _pendingMsg = null;
    state = state.copyWith(
      wsMessages: [...state.wsMessages, msg],
      sending: false,
    );
  }
}

final clawChatProvider = NotifierProvider<ClawChatNotifier, ClawChatState>(
  ClawChatNotifier.new,
);
