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
  int? code;
  String? message;
  AiSummaryData? data;

  AiSummaryResponse({this.code, this.message, this.data});

  factory AiSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryResponseToJson(this);
}

@JsonSerializable()
class AiSummaryData {
  int? hole_id;
  String? summary;
  List<AiSummaryBranch>? branches;
  List<AiSummaryInteraction>? interactions;
  List<String>? keywords;
  String? generated_at;
  String? cache_expires_at;
  bool? is_cached;
  String? trace_id;

  AiSummaryData({
    this.hole_id,
    this.summary,
    this.branches,
    this.interactions,
    this.keywords,
    this.generated_at,
    this.cache_expires_at,
    this.is_cached,
    this.trace_id,
  });

  factory AiSummaryData.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryDataFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryDataToJson(this);
}

@JsonSerializable()
class AiSummaryBranch {
  int? id;
  String? label;
  String? content;
  String? color;
  List<int>? representative_floors;

  AiSummaryBranch({
    this.id,
    this.label,
    this.content,
    this.color,
    this.representative_floors,
  });

  factory AiSummaryBranch.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryBranchFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryBranchToJson(this);
}

@JsonSerializable()
class AiSummaryInteraction {
  int? from_floor;
  String? from_user;
  int? to_floor;
  String? to_user;
  String? interaction_type;
  String? content;

  AiSummaryInteraction({
    this.from_floor,
    this.from_user,
    this.to_floor,
    this.to_user,
    this.interaction_type,
    this.content,
  });

  factory AiSummaryInteraction.fromJson(Map<String, dynamic> json) =>
      _$AiSummaryInteractionFromJson(json);

  Map<String, dynamic> toJson() => _$AiSummaryInteractionToJson(this);
}
