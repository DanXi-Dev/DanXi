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

import 'package:collection/collection.dart';
import 'package:dan_xi/model/claw/claw_channel.dart';
import 'package:dan_xi/repository/claw/claw_repository.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

final _channelsProvider = FutureProvider<List<ClawChannel>>((ref) async {
  return await ClawRepository.getInstance().getChannels();
});

class ClawChannelListPage extends ConsumerWidget {
  final Map<String, dynamic>? arguments;

  const ClawChannelListPage({super.key, this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(_channelsProvider);
    final currentChannelId = arguments?['current_channel_id'] as int?;

    return PlatformScaffold(
      // TODO: Use i18n.
      appBar: PlatformAppBarX(title: const Text('DantaClaw Channels')),
      body: switch (channels) {
        AsyncData(:final value) => _buildList(context, value, currentChannelId),
        AsyncError(:final error, :final stackTrace) =>
          ErrorPageWidget.buildWidget(
            context,
            error,
            stackTrace: stackTrace,
            onTap: () => ref.invalidate(_channelsProvider),
          ),
        _ => const Center(child: PlatformCircularProgressIndicator()),
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ClawChannel> channels,
    int? currentChannelId,
  ) {
    if (channels.isEmpty) {
      // TODO: Use i18n.
      return const Center(child: Text('No channels.'));
    }
    final sortedChannels = channels.sorted(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedChannels.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final channel = sortedChannels[index];
        final timeCreated = DateTime.tryParse(channel.createdAt);
        final formatted =
            timeCreated?.apply(
              (date) => DateFormat.yMMMd().add_Hms().format(date),
            ) ??
            channel.createdAt;
        final isActive = currentChannelId == channel.userSessionId;
        return ListTile(
          leading: CircleAvatar(child: Text('${channel.userSessionId}')),
          // TODO: Use i18n.
          title: Text('Session ${channel.userSessionId}'),
          subtitle: Text(formatted),
          trailing: isActive
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () => Navigator.pop(context, channel.userSessionId),
        );
      },
    );
  }
}
