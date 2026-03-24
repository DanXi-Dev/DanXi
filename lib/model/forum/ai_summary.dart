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

// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'ai_summary.g.dart';

@JsonSerializable()
class AiSummaryResponse {
  final int code;
  final String message;
  final AiSummaryData? data;

  AiSummaryResponse({this.code = 0, this.message = '', this.data});

  factory AiSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryResponseToJson(this);
}

@JsonSerializable()
class AiSummaryData {
  final int hole_id;
  final String summary;
  final List<AiSummaryBranch> branches;
  final List<AiSummaryInteraction> interactions;
  final List<String> keywords;
  final String generated_at;
  final String trace_id;

  // Reserved for future backend implementation.
  final String? cache_expires_at;
  final bool? is_cached;

  AiSummaryData({
    this.hole_id = 0,
    this.summary = '',
    this.branches = const [],
    this.interactions = const [],
    this.keywords = const [],
    this.generated_at = '',
    this.trace_id = '',
    this.cache_expires_at,
    this.is_cached,
  });

  factory AiSummaryData.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryDataFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryDataToJson(this);
}

@JsonSerializable()
class AiSummaryBranch {
  final int id;
  final String label;
  final String content;
  final String color;
  final List<int> representative_floors;

  AiSummaryBranch({
    this.id = 0,
    this.label = '',
    this.content = '',
    this.color = '',
    this.representative_floors = const [],
  });

  factory AiSummaryBranch.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryBranchFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryBranchToJson(this);
}

@JsonSerializable()
class AiSummaryInteraction {
  final int from_floor;
  final String from_user;
  final int to_floor;
  final String to_user;
  final String interaction_type;
  final String content;

  AiSummaryInteraction({
    this.from_floor = 0,
    this.from_user = '',
    this.to_floor = 0,
    this.to_user = '',
    this.interaction_type = 'reply',
    this.content = '',
  });

  factory AiSummaryInteraction.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryInteractionFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryInteractionToJson(this);
}
