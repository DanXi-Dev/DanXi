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

// Lightweight models for AI summary API responses.
class AiSummaryResponse {
  final int? code;
  final String? message;
  final AiSummaryData? data;

  const AiSummaryResponse({this.code, this.message, this.data});

  factory AiSummaryResponse.fromJson(Map<String, dynamic> json) {
    return AiSummaryResponse(
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      data: json['data'] is Map<String, dynamic>
          ? AiSummaryData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AiSummaryData {
  final int? holeId;
  final String? summary;
  final List<AiSummaryBranch> branches;
  final List<AiSummaryInteraction> interactions;
  final List<String> keywords;
  final String? generatedAt;
  final String? cacheExpiresAt;
  final bool? isCached;
  final String? traceId;

  const AiSummaryData({
    this.holeId,
    this.summary,
    this.branches = const [],
    this.interactions = const [],
    this.keywords = const [],
    this.generatedAt,
    this.cacheExpiresAt,
    this.isCached,
    this.traceId,
  });

  factory AiSummaryData.fromJson(Map<String, dynamic> json) {
    return AiSummaryData(
      holeId: (json['hole_id'] as num?)?.toInt(),
      summary: json['summary'] as String?,
      branches: (json['branches'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .map(AiSummaryBranch.fromJson)
              .toList() ??
          const [],
      interactions: (json['interactions'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .map(AiSummaryInteraction.fromJson)
              .toList() ??
          const [],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          const [],
      generatedAt: json['generated_at'] as String?,
      cacheExpiresAt: json['cache_expires_at'] as String?,
      isCached: json['is_cached'] as bool?,
      traceId: json['trace_id'] as String?,
    );
  }
}

class AiSummaryBranch {
  final int? id;
  final String? label;
  final String? content;
  final String? color;
  final List<int> representativeFloors;

  const AiSummaryBranch({
    this.id,
    this.label,
    this.content,
    this.color,
    this.representativeFloors = const [],
  });

  factory AiSummaryBranch.fromJson(Map<String, dynamic> json) {
    return AiSummaryBranch(
      id: (json['id'] as num?)?.toInt(),
      label: json['label'] as String?,
      content: json['content'] as String?,
      color: json['color'] as String?,
      representativeFloors: (json['representative_floors'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );
  }
}

class AiSummaryInteraction {
  final int? fromFloor;
  final String? fromUser;
  final int? toFloor;
  final String? toUser;
  final String? interactionType;
  final String? content;

  const AiSummaryInteraction({
    this.fromFloor,
    this.fromUser,
    this.toFloor,
    this.toUser,
    this.interactionType,
    this.content,
  });

  factory AiSummaryInteraction.fromJson(Map<String, dynamic> json) {
    return AiSummaryInteraction(
      fromFloor: (json['from_floor'] as num?)?.toInt(),
      fromUser: json['from_user'] as String?,
      toFloor: (json['to_floor'] as num?)?.toInt(),
      toUser: json['to_user'] as String?,
      interactionType: json['interaction_type'] as String?,
      content: json['content'] as String?,
    );
  }
}
