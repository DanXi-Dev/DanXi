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
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/claw/ws_service.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class ClawChatPage extends HookConsumerWidget {
  final Map<String, dynamic>? arguments;

  const ClawChatPage({super.key, this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelId = useState(
      arguments?['channel_id'] as ChannelId? ?? const NewChannelId(),
    );
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    final chatState = ref.watch(clawChatProvider);
    final chatNotifier = ref.read(clawChatProvider.notifier);
    final selectedMsgId = useState<String?>(null);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await chatNotifier.loadMessages(channelId.value);
      });
      return null;
    }, [channelId.value]);

    useEffect(() {
      final ws = ClawWebSocketService.getInstance();
      ws.connect();
      final subscription = ws.messages.listen((msg) {
        final currChannelId = channelId.value;
        final msgChannelId = ChannelId.fromIntOrNull(msg.channelId);
        if (currChannelId is NewChannelId) {
          channelId.value = msgChannelId;
        }
        if (msgChannelId != currChannelId) return;
        chatNotifier.onWsMessage(msg);
      });
      return subscription.cancel;
    }, [channelId.value]);

    final backgroundImage = SettingsProvider.getInstance().backgroundImage;
    return PlatformScaffold(
      appBar: PlatformAppBarX(
        // TODO: Use i18n.
        title: Text(switch (channelId.value) {
          NewChannelId() => 'New Chat',
          SomeChannelId(:final id) => 'DantaClaw Chat $id',
        }),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(
              PlatformX.isMaterial(context) ? Icons.add : CupertinoIcons.add,
            ),
            onPressed: () => channelId.value = const NewChannelId(),
          ),
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
      body: Container(
        decoration: backgroundImage == null
            ? null
            : BoxDecoration(
                image: DecorationImage(
                  image: backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
        child: Column(
          children: [
            Expanded(
              child: _buildBody(
                context,
                channelId,
                chatState,
                chatNotifier,
                scrollController,
                selectedMsgId,
              ),
            ),
            _buildInputBar(context, textController, chatState.sending, (text) {
              chatNotifier.sendMessage(channelId.value, text);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ValueNotifier<ChannelId> channelId,
    ClawChatState state,
    ClawChatNotifier notifier,
    ScrollController scrollController,
    ValueNotifier<String?> selectedMsgId,
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
    if (state.httpMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PlatformX.isMaterial(context)
                  ? Icons.chat_bubble_outline
                  : CupertinoIcons.chat_bubble,
              size: 128,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'DantaClaw',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    final mergedMsgs = state.mergedMessages;
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: mergedMsgs.length,
      itemBuilder: (context, index) {
        final msg = mergedMsgs[index];
        final isUser = msg.isUser;
        final isSelected = msg.messageId == selectedMsgId.value;
        final msgOnTap = () =>
            selectedMsgId.value = isSelected ? null : msg.messageId;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: msgOnTap,
                    onSecondaryTap: msgOnTap,
                    onDoubleTap: isUser
                        ? null
                        : () => notifier.sendMessage(
                            channelId.value,
                            '*Pokes DantaClaw*',
                          ),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(msg.content),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 256),
                curve: Curves.easeInOut,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.yMMMd().add_Hms().format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  msg.timestamp,
                                ),
                              ),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: msg.content),
                                );
                                selectedMsgId.value = null;
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      // TODO: Use i18n.
                                      content: Text('Copied'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
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
          Material(
            type: MaterialType.transparency,
            shape: CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : () => onSendWrapper(controller.text),
              child: Ink(
                decoration: BoxDecoration(
                  color: sending
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  PlatformX.isMaterial(context)
                      ? Icons.send
                      : CupertinoIcons.paperplane_fill,
                  color: sending ? Colors.white38 : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchChannel(
    BuildContext context,
    ValueNotifier<ChannelId> channelId,
  ) async {
    final selected = await smartNavigatorPush(
      context,
      '/claw/channels',
      arguments: {
        'current_channel_id': channelId.value is SomeChannelId
            ? channelId.value
            : null,
      },
    );
    if (selected is ChannelId && selected != channelId.value) {
      channelId.value = selected;
    }
  }
}
