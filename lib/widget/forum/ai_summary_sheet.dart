/*
 *     Copyright (C) 2026  DanXi-Dev
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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/ai_summary.dart';
import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_summary_sheet.g.dart';

class AiSummaryApiException implements Exception {
  final int code;
  final String? message;

  AiSummaryApiException(this.code, this.message);
}

class AiSummaryTimeoutException implements Exception {}

@riverpod
Future<AiSummaryData> aiSummary(Ref ref, int holeId) async {
  const pollInterval = Duration(seconds: 2);
  const maxPollAttempts = 60;

  bool disposed = false;
  ref.onDispose(() => disposed = true);

  for (int attempt = 0; attempt <= maxPollAttempts; attempt++) {
    if (disposed) throw StateError('disposed');

    final response =
        await ForumRepository.getInstance().loadAiSummary(holeId);
    if (disposed) throw StateError('disposed');

    final code = response.code;
    if (code == 1000) return response.data ?? AiSummaryData();
    if (code != 1001 && code != 1002) {
      throw AiSummaryApiException(code, response.message);
    }
    if (attempt < maxPollAttempts) {
      await Future.delayed(pollInterval);
    }
  }
  throw AiSummaryTimeoutException();
}

class AiSummarySheet extends ConsumerWidget {
  final int holeId;
  final int? totalFloors;
  final Future<OTFloor?> Function(int floorNumber)? floorResolver;

  const AiSummarySheet({
    super.key,
    required this.holeId,
    this.totalFloors,
    this.floorResolver,
  });

  static String _resolveError(BuildContext context, Object error) {
    if (error is AiSummaryApiException) {
      final trimmed = error.message?.trim();
      switch (error.code) {
        case 2001:
          return trimmed?.isNotEmpty == true
              ? trimmed!
              : S.of(context).ai_summary_empty;
        case 2002:
          return S.of(context).no_summary;
        default:
          break;
      }
    }
    if (error is AiSummaryTimeoutException) {
      return S.of(context).ai_summary_server_error;
    }
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final code = (data['code'] as num?)?.toInt();
        final message = data['message'] as String?;
        if (code != null) {
          return _resolveError(context, AiSummaryApiException(code, message));
        }
      }
      final status = error.response?.statusCode;
      if (status != null) {
        if (status == 403) return S.of(context).ai_summary_no_permission;
      }
    }
    return ErrorPageWidget.generateUserFriendlyDescription(
        S.of(context), error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(aiSummaryProvider(holeId));

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildHeader(context),
                _buildDisclaimer(context),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: switch (summary) {
                        AsyncData(:final value) =>
                          _buildContentWidgets(context, value),
                        AsyncError(:final error) => [
                            _buildError(context, ref, error),
                          ],
                        _ => [_buildLoading(context)],
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContentWidgets(
      BuildContext context, AiSummaryData data) {
    final hasContent = data.summary.trim().isNotEmpty ||
        data.branches.isNotEmpty ||
        data.interactions.isNotEmpty ||
        data.keywords.isNotEmpty;

    if (!hasContent) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(S.of(context).ai_summary_empty),
        ),
      ];
    }

    return [
      _buildKeywords(context, data),
      _buildSummary(context, data),
      _buildBranches(context, data),
      _buildInteractions(context, data),
      _FeedbackBar(holeId: holeId, data: data),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              S.of(context).ai_summary_title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              PlatformX.isMaterial(context)
                  ? Icons.close
                  : CupertinoIcons.xmark,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        S.of(context).ai_summary_disclaimer,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            totalFloors != null && totalFloors! > 0
                ? S
                    .of(context)
                    .ai_summary_loading_with_count(totalFloors!)
                : S.of(context).ai_summary_loading,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildSkeletonLine(context, widthFactor: 0.9),
          const SizedBox(height: 8),
          _buildSkeletonLine(context, widthFactor: 0.75),
          const SizedBox(height: 8),
          _buildSkeletonLine(context, widthFactor: 0.6),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine(BuildContext context,
      {double widthFactor = 1}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, AiSummaryData data) {
    final summary = data.summary.trim();
    if (summary.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      context,
      icon: PlatformX.isMaterial(context)
          ? Icons.summarize
          : CupertinoIcons.doc_text,
      title: S.of(context).ai_summary_core,
      child: Text(summary, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildBranches(BuildContext context, AiSummaryData data) {
    final branches = data.branches;
    if (branches.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      context,
      icon: PlatformX.isMaterial(context)
          ? Icons.fork_right
          : CupertinoIcons.arrow_branch,
      title: S.of(context).ai_summary_branches,
      child: Column(
        children: branches.map((branch) {
          final color = _parseHexColor(context, branch.color);
          return _LazyBranchTile(
            branch: branch,
            color: color,
            floorResolver: floorResolver,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractions(BuildContext context, AiSummaryData data) {
    final interactions = data.interactions;
    if (interactions.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      context,
      icon: PlatformX.isMaterial(context)
          ? Icons.forum
          : CupertinoIcons.chat_bubble_2,
      title: S.of(context).ai_summary_interactions,
      child: Column(
        children: interactions.map((interaction) {
          final style =
              _interactionStyle(context, interaction.interaction_type);
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(style.icon, size: 16, color: style.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: interaction.from_user,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: " ${style.verb} "),
                              TextSpan(
                                text: interaction.to_user,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (interaction.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      interaction.content,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (interaction.from_floor > 0)
                        _buildFloorChip(context, interaction.from_floor),
                      if (interaction.to_floor > 0)
                        _buildFloorChip(context, interaction.to_floor),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeywords(BuildContext context, AiSummaryData data) {
    final keywords = data.keywords;
    if (keywords.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      context,
      icon:
          PlatformX.isMaterial(context) ? Icons.label : CupertinoIcons.tag,
      title: S.of(context).ai_summary_keywords,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: keywords
            .map((kw) => RectangularChip(label: kw, color: kw.hashColor()))
            .toList(),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final subtitleColor = Theme.of(context).hintColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 14, color: subtitleColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip(BuildContext context, int floorNumber) {
    return ActionChip(
      label: Text(
        "#$floorNumber",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onPressed: () async {
        final resolved = floorResolver != null
            ? await floorResolver!(floorNumber)
            : await ForumRepository.getInstance()
                .loadFloorById(floorNumber);
        if (resolved != null && context.mounted) {
          OTFloorMentionWidget.showFloorDetail(context, resolved);
        }
      },
    );
  }

  Widget _buildError(
      BuildContext context, WidgetRef ref, Object error) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _resolveError(context, error),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              try {
                await ForumRepository.getInstance()
                    .loadAiSummary(holeId, forceRefresh: true);
              } catch (_) {}
              ref.invalidate(aiSummaryProvider(holeId));
            },
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }

  static Color _parseHexColor(BuildContext context, String value) {
    if (value.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) hex = "FF$hex";
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return Theme.of(context).colorScheme.primary;
    return Color(parsed);
  }

  static _InteractionStyle _interactionStyle(
      BuildContext context, String type) {
    final normalized = type.toLowerCase();
    switch (normalized) {
      case "support":
        return _InteractionStyle(
          icon: PlatformX.isMaterial(context)
              ? Icons.favorite
              : CupertinoIcons.heart_fill,
          color: Colors.redAccent,
          verb: S.of(context).ai_summary_interaction_support,
        );
      case "rebuttal":
        return _InteractionStyle(
          icon: PlatformX.isMaterial(context)
              ? Icons.gavel
              : CupertinoIcons.exclamationmark_triangle_fill,
          color: Colors.orange,
          verb: S.of(context).ai_summary_interaction_rebuttal,
        );
      case "supplement":
        return _InteractionStyle(
          icon: PlatformX.isMaterial(context)
              ? Icons.add_circle
              : CupertinoIcons.add_circled_solid,
          color: Colors.green,
          verb: S.of(context).ai_summary_interaction_supplement,
        );
      case "question":
        return _InteractionStyle(
          icon: PlatformX.isMaterial(context)
              ? Icons.help
              : CupertinoIcons.question_circle_fill,
          color: Colors.orangeAccent,
          verb: S.of(context).ai_summary_interaction_question,
        );
      case "reply":
      default:
        return _InteractionStyle(
          icon: PlatformX.isMaterial(context)
              ? Icons.arrow_right_alt
              : CupertinoIcons.arrow_right,
          color: Colors.grey,
          verb: S.of(context).ai_summary_interaction_reply,
        );
    }
  }
}

class _FeedbackBar extends HookWidget {
  final int holeId;
  final AiSummaryData data;

  const _FeedbackBar({required this.holeId, required this.data});

  @override
  Widget build(BuildContext context) {
    final feedbackType = useState<String?>(null);
    final submittingFeedback = useState(false);
    final feedbackTapCount = useState(0);
    final showTraceId = useState(false);

    final selected = feedbackType.value;
    final disabled = submittingFeedback.value || selected != null;
    final upSelected = selected == "upvote";
    final downSelected = selected == "downvote";
    final isMaterial = PlatformX.isMaterial(context);
    final iconColor = Theme.of(context).hintColor;

    Future<void> submitFeedback(String type) async {
      if (submittingFeedback.value || feedbackType.value != null) return;

      String? reason;
      if (type == "downvote") {
        reason = await Noticing.showInputDialog(
          context,
          S.of(context).input_reason,
          maxLines: 3,
        );
        if (!context.mounted || reason == null) return;
      }

      submittingFeedback.value = true;
      try {
        await ForumRepository.getInstance().submitAiSummaryFeedback(
          holeId,
          feedbackType: type,
          reason: reason,
        );
        if (!context.mounted) return;
        submittingFeedback.value = false;
        feedbackType.value = type;
        unawaited(
            Noticing.showNotice(context, S.of(context).request_success));
      } catch (_) {
        if (!context.mounted) return;
        submittingFeedback.value = false;
        unawaited(
            Noticing.showNotice(context, S.of(context).operation_failed));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              feedbackTapCount.value++;
              if (feedbackTapCount.value >= 5 && !showTraceId.value) {
                showTraceId.value = true;
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      disabled ? null : () => submitFeedback("upvote"),
                  icon: Icon(
                    isMaterial
                        ? (upSelected
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined)
                        : (upSelected
                            ? CupertinoIcons.hand_thumbsup_fill
                            : CupertinoIcons.hand_thumbsup),
                    color: upSelected ? Colors.green : iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed:
                      disabled ? null : () => submitFeedback("downvote"),
                  icon: Icon(
                    isMaterial
                        ? (downSelected
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined)
                        : (downSelected
                            ? CupertinoIcons.hand_thumbsdown_fill
                            : CupertinoIcons.hand_thumbsdown),
                    color: downSelected ? Colors.redAccent : iconColor,
                  ),
                ),
              ],
            ),
          ),
          if (showTraceId.value && data.trace_id.isNotEmpty)
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: data.trace_id));
                Noticing.showNotice(
                  context,
                  S.of(context).ai_summary_trace_copied,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Trace: ${data.trace_id}",
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        Theme.of(context).hintColor.withValues(alpha: 0.6),
                    fontFamily: "monospace",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LazyBranchTile extends StatefulWidget {
  final AiSummaryBranch branch;
  final Color color;
  final Future<OTFloor?> Function(int floorNumber)? floorResolver;

  const _LazyBranchTile({
    required this.branch,
    required this.color,
    this.floorResolver,
  });

  @override
  State<_LazyBranchTile> createState() => _LazyBranchTileState();
}

class _LazyBranchTileState extends State<_LazyBranchTile> {
  List<Future<OTFloor?>>? _futures;

  void _onExpansionChanged(bool expanded) {
    if (expanded && _futures == null) {
      setState(() {
        _futures =
            widget.branch.representative_floors.map((floor) {
          return widget.floorResolver != null
              ? widget.floorResolver!(floor)
              : ForumRepository.getInstance().loadFloorById(floor);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        onExpansionChanged: _onExpansionChanged,
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          widget.branch.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: widget.branch.content.isNotEmpty
            ? Text(
                widget.branch.content,
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        children: _futures != null
            ? _futures!
                .map(
                  (future) => OTFloorMentionWidget(
                    future: future,
                    hasBackgroundImage: false,
                  ),
                )
                .toList()
            : const [],
      ),
    );
  }
}

class _InteractionStyle {
  final IconData icon;
  final Color color;
  final String verb;

  const _InteractionStyle({
    required this.icon,
    required this.color,
    required this.verb,
  });
}
