import 'package:dan_xi/model/claw/claw_message.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';
import 'package:dan_xi/util/claw/ws_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

sealed class ChatError {
  const ChatError();
}

class NoError extends ChatError {
  const NoError();
}

class SomeError extends ChatError {
  final Object error;

  const SomeError(this.error);
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

  Future<void> loadMessages(int channelId) async {
    state = state.copyWith(loading: true, error: const NoError());
    try {
      // TODO: Load from end and expand in need.
      final msgs = <ClawMessage>[];
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
      state = ClawChatState(
        messages: msgs.reversed.toList(growable: false),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: SomeError(e));
    }
  }

  void sendMessage(int channelId, String text) {
    state = state.copyWith(sending: true);

    final messageId =
        'msg_${DateTime.now().millisecondsSinceEpoch}_${_msgCounter++}';

    ClawWebSocketService.getInstance().sendMessage(
      channelId: channelId,
      content: text,
      messageId: messageId,
    );

    final userMsg = ClawMessage(
      id: 0,
      type: 'message',
      from: 'user',
      content: text,
      messageId: messageId,
      channelId: channelId,
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
