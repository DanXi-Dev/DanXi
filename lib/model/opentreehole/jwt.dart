/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'package:json_annotation/json_annotation.dart';

part 'jwt.g.dart';

@JsonSerializable()
class JWToken {
  String? access;
  String? refresh;

  factory JWToken.fromJson(Map<String, dynamic> json) =>
      _$JWTokenFromJson(json);

  bool get isValid => access != null && refresh != null;

  factory JWToken.fromJsonWithVerification(Map<String, dynamic> json) {
    JWToken token = JWToken.fromJson(json);
    if (!token.isValid) {
      throw BadTokenException();
    }
    return token;
  }

  Map<String, dynamic> toJson() => _$JWTokenToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JWToken &&
          runtimeType == other.runtimeType &&
          access == other.access &&
          refresh == other.refresh;

  @override
  int get hashCode => access.hashCode ^ refresh.hashCode;

  JWToken(this.access, this.refresh);
}

class BadTokenException implements Exception {}
