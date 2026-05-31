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

import 'package:dan_xi/model/claw/claw_channel.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ClawChannelListPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ClawChannelListPage({super.key, this.arguments});

  @override
  State<ClawChannelListPage> createState() => _ClawChannelListPageState();
}

class _ClawChannelListPageState extends State<ClawChannelListPage> {
  Future<List<ClawChannel>> _loadChannels() {
    return ClawRepository.getInstance().getChannels();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBarX(title: const Text('DantaClaw Channels')),
      body: FutureWidget<List<ClawChannel>>(
        future: _loadChannels(),
        loadingBuilder: const Center(
          child: PlatformCircularProgressIndicator(),
        ),
        errorBuilder:
            (BuildContext context, AsyncSnapshot<List<ClawChannel>> snapshot) {
              return ErrorPageWidget.buildWidget(
                context,
                snapshot.error,
                stackTrace: snapshot.stackTrace,
                onTap: () => setState(() {}),
              );
            },
        successBuilder:
            (BuildContext context, AsyncSnapshot<List<ClawChannel>> snapshot) {
              final channels = snapshot.data!;
              if (channels.isEmpty) {
                return const Center(child: Text('No channels.'));
              }
              // Show newest first.
              final sorted = List<ClawChannel>.from(channels)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sorted.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  final ch = sorted[index];
                  final createdAt = ch.createdAt.isNotEmpty
                      ? ch.createdAt.substring(0, 19).replaceFirst('T', ' ')
                      : '';
                  return ListTile(
                    leading: CircleAvatar(child: Text('${ch.userSessionId}')),
                    title: Text('Session ${ch.userSessionId}'),
                    subtitle: Text(createdAt),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      smartNavigatorPush(
                        context,
                        '/claw/chat',
                        arguments: {'channel_id': ch.userSessionId},
                      );
                    },
                  );
                },
              );
            },
      ),
    );
  }
}
