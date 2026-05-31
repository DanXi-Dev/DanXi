/*
 *     Copyright (C) 2025  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:dan_xi/provider/claw/claw_chat_provider.dart';
import 'package:dan_xi/util/claw/ws_service.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ClawChatPage extends HookConsumerWidget {
  final Map<String, dynamic>? arguments;

  const ClawChatPage({super.key, this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelId = useState((arguments?['channel_id'] as int?) ?? 502);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    final chatState = ref.watch(clawChatProvider);
    final chatNotifier = ref.read(clawChatProvider.notifier);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => chatNotifier.loadMessages(channelId.value),
      );
      return null;
    }, [channelId.value]);

    useEffect(() {
      final ws = ClawWebSocketService.getInstance();
      ws.connect();
      final sub = ws.messages.listen((msg) {
        if (msg.channelId != channelId.value) return;
        chatNotifier.onWsMessage(msg);
        _scrollToBottomAnimated(scrollController);
      });
      return sub.cancel;
    }, [channelId.value]);

    useEffect(() {
      _scrollToBottom(scrollController);
      return null;
    }, [chatState.messages.length, channelId.value]);

    return PlatformScaffold(
      appBar: PlatformAppBarX(
        title: Text('DantaClaw Channel ${channelId.value}'),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? Icons.list
                  : CupertinoIcons.list_bullet,
            ),
            onPressed: () => _switchChannel(context, channelId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(
              context,
              channelId,
              chatState,
              chatNotifier,
              scrollController,
            ),
          ),
          _buildInputBar(context, textController, chatState.sending, (text) {
            chatNotifier.sendMessage(channelId.value, text);
          }),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ValueNotifier<int> channelId,
    ClawChatState state,
    ClawChatNotifier notifier,
    ScrollController scrollController,
  ) {
    if (state.loading) {
      return const Center(child: PlatformCircularProgressIndicator());
    }
    if (state.error case SomeError(:final error)) {
      return ErrorPageWidget.buildWidget(
        context,
        error,
        onTap: () => notifier.loadMessages(channelId.value),
      );
    }
    if (state.messages.isEmpty) {
      return Center(
        child: Text(
          'No messages in channel ${channelId.value}. This might be an internal error.',
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final msg = state.messages[index];
        final isUser = msg.isUser;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'Me' : 'DantaClaw',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(msg.content),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    TextEditingController controller,
    bool sending,
    void Function(String) onSend,
  ) {
    final onSendWrapper = (String text) {
      text = text.trim();
      if (text.isNotEmpty) {
        controller.clear();
        onSend(text);
      }
    };
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: PlatformTextField(
              controller: controller,
              hintText: 'Type a message...',
              onSubmitted: sending ? null : onSendWrapper,
            ),
          ),
          const SizedBox(width: 8),
          PlatformIconButton(
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? Icons.send
                  : CupertinoIcons.paperplane_fill,
            ),
            onPressed: sending ? null : () => onSendWrapper(controller.text),
          ),
        ],
      ),
    );
  }

  Future<void> _switchChannel(
    BuildContext context,
    ValueNotifier<int> channelId,
  ) async {
    final selected = await smartNavigatorPush(
      context,
      '/claw/channels',
      arguments: {'current_channel_id': channelId.value},
    );
    if (selected is int && selected != channelId.value) {
      channelId.value = selected;
    }
  }

  void _scrollToBottom(ScrollController controller) {
    void scroll() {
      if (!controller.hasClients) return;
      final target = controller.position.maxScrollExtent;
      if ((controller.position.pixels - target).abs() > 0.5) {
        controller.jumpTo(target);
        // ListView.builder may not have fully laid out all items yet.
        // Retry on next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
  }

  void _scrollToBottomAnimated(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 256),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
