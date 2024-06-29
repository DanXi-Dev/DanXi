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
import 'package:dan_xi/page/forum/hole_editor.dart';

/// [EditorObject] represents an object the [BBSEditorWidget] replies or posts to.
///
/// See also:
///
/// * [FDUHoleProvider], where [EditorObject]s are usually stored.
class EditorObject {
  /// The post id or discussion id.
  ///
  /// Set to 0 if creating a new post.
  final int? id;
  final EditorObjectType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  EditorObject(this.id, this.type);
}

enum EditorObjectType {
  NONE,
  REPLY_TO_FLOOR,
  REPLY_TO_HOLE,
  MODIFY_FLOOR,
  NEW_POST
}
