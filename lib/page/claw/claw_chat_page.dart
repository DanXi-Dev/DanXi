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

import 'package:dan_xi/model/claw/claw_message.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';
import 'package:dan_xi/util/claw/ws_service.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ClawChatPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ClawChatPage({super.key, this.arguments});

  @override
  State<ClawChatPage> createState() => _ClawChatPageState();
}

class _ClawChatPageState extends State<ClawChatPage> {
  late int _channelId = (widget.arguments?['channel_id'] as int?) ?? 2;
  final List<ClawMessage> _messages = [];
  Object? _error;
  bool _loading = true;
  bool _sending = false;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<ClawMessage>? _wsSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectWs() async {
    final ws = ClawWebSocketService.getInstance();
    await ws.connect();
    _wsSub?.cancel();
    _wsSub = ws.messages.listen(_onWsMessage);
  }

  void _onWsMessage(ClawMessage msg) {
    if (msg.channelId != _channelId || !mounted) return;
    setState(() {
      _messages.add(msg);
      _sending = false;
    });
    _scrollToBottom();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
      _messages.clear();
    });
    try {
      final msgs = await ClawRepository.getInstance().getMessages(
        channelId: _channelId,
        sort: 'asc',
        size: 64,
      );
      if (!mounted) return;
      setState(() {
        _messages.addAll(msgs);
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    _textController.clear();
    setState(() => _sending = true);

    final messageId =
        'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

    ClawWebSocketService.getInstance().sendMessage(
      channelId: _channelId,
      content: text,
      messageId: messageId,
    );

    final userMsg = ClawMessage(
      id: 0,
      type: 'message',
      from: 'user',
      content: text,
      messageId: messageId,
      channelId: _channelId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      media: {},
    );
    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 256),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _switchChannel() async {
    final selected = await smartNavigatorPush(context, '/claw/channels');
    if (selected is int && selected != _channelId && mounted) {
      setState(() => _channelId = selected);
      // Keep WS connection alive, just reload history for new channel.
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBarX(
        title: Text('DantaClaw Channel $_channelId'),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? Icons.list
                  : CupertinoIcons.list_bullet,
            ),
            onPressed: _switchChannel,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: PlatformCircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorPageWidget.buildWidget(context, _error, onTap: _loadMessages);
    }
    if (_messages.isEmpty) {
      return Center(child: Text('No messages in channel $_channelId.'));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
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

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: PlatformTextField(
              controller: _textController,
              // TODO: Use i18n.
              hintText: 'Type a message...',
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          PlatformIconButton(
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? Icons.send
                  : CupertinoIcons.paperplane_fill,
            ),
            onPressed: _sending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
