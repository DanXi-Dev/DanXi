library change;

import 'package:json_annotation/json_annotation.dart';

part 'change.g.dart';

@JsonSerializable()
class Change {
  factory Change.fromJson(Map<String, dynamic> json) => _$ChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ChangeToJson(this);

  String? appKey;
  String? tableName;
  String? objectId;
  String? action;
  Map<String, dynamic>? data;

  Change();
}
