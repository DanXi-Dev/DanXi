library bmobgeopoint;

import 'package:json_annotation/json_annotation.dart';

part 'bmob_geo_point.g.dart';

@JsonSerializable()
class BmobGeoPoint {
  factory BmobGeoPoint.fromJson(Map<String, dynamic> json) =>
      _$BmobGeoPointFromJson(json);

  Map<String, dynamic> toJson() => _$BmobGeoPointToJson(this);

  double latitude;
  double longitude;

  @JsonKey(name: "__type")
  String type = "GeoPoint";

  BmobGeoPoint();
}
