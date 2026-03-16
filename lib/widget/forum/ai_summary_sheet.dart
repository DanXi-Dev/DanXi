/*
 *     Copyright (C) 2021  DanXi-Dev
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
import 'package:dio/dio.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiSummarySheet extends StatefulWidget {
  final int holeId;
  final int? totalFloors;
  final Future<OTFloor?> Function(int floorNumber)? floorResolver;

  const AiSummarySheet({
    super.key,
    required this.holeId,
    this.totalFloors,
    this.floorResolver,
  });

  @override
  State<AiSummarySheet> createState() => _AiSummarySheetState();
}

class _AiSummarySheetState extends State<AiSummarySheet> {
  AiSummaryData? _data;
  String? _error;
  bool _loading = true;
  bool _submittingFeedback = false;
  String? _feedbackType;
  Timer? _pollTimer;
  int _feedbackTapCount = 0;
  bool _showTraceId = false;
  static const Duration _pollInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _resolveErrorMessage(int? code, String? backendMessage) {
    final trimmed = backendMessage?.trim();
    switch (code) {
      case 2001:
        return trimmed?.isNotEmpty == true
            ? trimmed!
            : S.of(context).ai_summary_empty;
      case 2002:
        // Unavailable by policy/content type. Prefer stable local copy.
        return S.of(context).no_summary;
      case 3001:
      case 3002:
        return S.of(context).operation_failed;
      default:
        return S.of(context).operation_failed;
    }
  }

  Future<void> _loadSummary({bool? forceRefresh}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ForumRepository.getInstance().loadAiSummary(
        widget.holeId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final data = response.data;
      final code = response.code;

      if (code == 1001 || code == 1002) {
        if (data != null) _data = data;
        _schedulePoll();
        // _loading is already true from the setState above; no need to set again
        return;
      }
      if (code == 1000) {
        _data = data;
        setState(() => _loading = false);
        _pollTimer?.cancel();
        return;
      }
      setState(() {
        _loading = false;
        _error = _resolveErrorMessage(code, response.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _submitFeedback(String feedbackType) async {
    if (_submittingFeedback || _feedbackType != null) return;

    String? reason;
    if (feedbackType == "downvote") {
      reason = await Noticing.showInputDialog(
        context,
        S.of(context).input_reason,
        maxLines: 3,
      );
      if (!mounted || reason == null) return;
    }

    setState(() => _submittingFeedback = true);
    try {
      await ForumRepository.getInstance().submitAiSummaryFeedback(
        widget.holeId,
        feedbackType: feedbackType,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _submittingFeedback = false;
        _feedbackType = feedbackType;
      });
      unawaited(Noticing.showNotice(context, S.of(context).request_success));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submittingFeedback = false);
      unawaited(Noticing.showNotice(context, S.of(context).operation_failed));
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      // Try to parse a structured JSON body from the error response.
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final code = (data['code'] as num?)?.toInt();
        final message = data['message'] as String?;
        if (code != null) {
          return _resolveErrorMessage(code, message);
        }
      }
      // Fall back to HTTP-status–based messages.
      final status = e.response?.statusCode;
      if (status != null) {
        if (status == 403) return S.of(context).ai_summary_no_permission;
        if (status >= 500) return S.of(context).ai_summary_server_error;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return S.of(context).ai_summary_network_error;
      }
    }
    return S.of(context).operation_failed;
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(_pollInterval, () {
      if (!mounted) return;
      _loadSummary();
    });
  }

  Color _parseHexColor(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return Theme.of(context).colorScheme.primary;
    }
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) hex = "FF$hex";
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return Theme.of(context).colorScheme.primary;
    return Color(parsed);
  }

  _InteractionStyle _interactionStyle(BuildContext context, String? type) {
    final normalized = (type ?? "").toLowerCase();
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              S.of(context).ai_summary_title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            widget.totalFloors != null && widget.totalFloors! > 0
                ? S
                    .of(context)
                    .ai_summary_loading_with_count(widget.totalFloors!)
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

  Widget _buildSkeletonLine(BuildContext context, {double widthFactor = 1}) {
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

  Widget _buildSummary(BuildContext context) {
    final summary = _data?.summary?.trim();
    if (summary == null || summary.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildSectionCard(
      context,
      icon: PlatformX.isMaterial(context)
          ? Icons.summarize
          : CupertinoIcons.doc_text,
      title: S.of(context).ai_summary_core,
      child: Text(summary, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildBranches(BuildContext context) {
    final branches = _data?.branches ?? const [];
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
            floorResolver: widget.floorResolver,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractions(BuildContext context) {
    final interactions = _data?.interactions ?? const [];
    if (interactions.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      context,
      icon: PlatformX.isMaterial(context)
          ? Icons.forum
          : CupertinoIcons.chat_bubble_2,
      title: S.of(context).ai_summary_interactions,
      child: Column(
        children: interactions.map((interaction) {
          final style = _interactionStyle(context, interaction.interactionType);
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                                text: interaction.fromUser ?? "-",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: " ${style.verb} "),
                              TextSpan(
                                text: interaction.toUser ?? "-",
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
                  if (interaction.content != null &&
                      interaction.content!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      interaction.content!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (interaction.fromFloor != null)
                        _buildFloorChip(context, interaction.fromFloor!),
                      if (interaction.toFloor != null)
                        _buildFloorChip(context, interaction.toFloor!),
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

  Widget _buildKeywords(BuildContext context) {
    final keywords = _data?.keywords ?? const [];
    if (keywords.isEmpty) return const SizedBox.shrink();
    return _buildSectionCard(
      context,
      icon: PlatformX.isMaterial(context) ? Icons.label : CupertinoIcons.tag,
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
        final resolved = widget.floorResolver != null
            ? await widget.floorResolver!(floorNumber)
            : await ForumRepository.getInstance().loadFloorById(floorNumber);
        if (resolved != null && context.mounted) {
          OTFloorMentionWidget.showFloorDetail(context, resolved);
        }
      },
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _loadSummary(forceRefresh: true),
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }

  void _onFeedbackAreaTap() {
    _feedbackTapCount++;
    if (_feedbackTapCount >= 5 && !_showTraceId) {
      setState(() => _showTraceId = true);
    }
  }

  Widget _buildFeedbackBar(BuildContext context) {
    final selected = _feedbackType;
    final disabled = _submittingFeedback || selected != null;
    final upSelected = selected == "upvote";
    final downSelected = selected == "downvote";
    final isMaterial = PlatformX.isMaterial(context);
    final iconColor = Theme.of(context).hintColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: _onFeedbackAreaTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: disabled ? null : () => _submitFeedback("upvote"),
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
                      disabled ? null : () => _submitFeedback("downvote"),
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
          if (_showTraceId && _data?.traceId != null)
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: _data!.traceId!));
                Noticing.showNotice(
                  context,
                  S.of(context).ai_summary_trace_copied,
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Trace: ${_data!.traceId!}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                    fontFamily: "monospace",
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
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
                      children: [
                        if (_loading) _buildLoading(context),
                        if (!_loading && _error != null)
                          _buildError(context, _error!),
                        if (!_loading && _error == null && _data == null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(S.of(context).ai_summary_empty),
                          ),
                        if (_data != null) ...[
                          _buildKeywords(context),
                          _buildSummary(context),
                          _buildBranches(context),
                          _buildInteractions(context),
                          _buildFeedbackBar(context),
                          const SizedBox(height: 12),
                        ],
                      ],
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
}

/// Lazily loads representative floors only when expanded.
/// Avoids firing N concurrent [floorResolver] futures for collapsed branches.
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
        _futures = widget.branch.representativeFloors.map((floor) {
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
          widget.branch.label ?? "-",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            widget.branch.content != null && widget.branch.content!.isNotEmpty
            ? Text(
                widget.branch.content!,
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
