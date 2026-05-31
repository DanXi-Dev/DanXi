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

import 'package:dan_xi/model/claw/claw_message.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ClawChatPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ClawChatPage({super.key, this.arguments});

  @override
  State<ClawChatPage> createState() => _ClawChatPageState();
}

class _ClawChatPageState extends State<ClawChatPage> {
  static const int _channelId = 2;

  @override
  void initState() {
    super.initState();
  }

  Future<List<ClawMessage>> _loadMessages() {
    return ClawRepository.getInstance().getMessages(
      channelId: _channelId,
      sort: 'asc',
      size: 64,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      // TODO: Use i18n.
      appBar: PlatformAppBarX(title: Text('DantaClaw Channel $_channelId')),
      body: FutureWidget<List<ClawMessage>>(
        future: _loadMessages(),
        loadingBuilder: const Center(
          child: PlatformCircularProgressIndicator(),
        ),
        errorBuilder:
            (BuildContext context, AsyncSnapshot<List<ClawMessage>> snapshot) {
              return ErrorPageWidget.buildWidget(
                context,
                snapshot.error,
                stackTrace: snapshot.stackTrace,
                onTap: () => setState(() {}),
              );
            },
        successBuilder:
            (BuildContext context, AsyncSnapshot<List<ClawMessage>> snapshot) {
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return Center(
                  child: Text('No messages in channel $_channelId.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg.isUser;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          // TODO: Use i18n.
                          isUser ? 'You' : 'Claw',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
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
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
      ),
    );
  }
}
