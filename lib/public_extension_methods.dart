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


import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

extension StringEx on String {
  /// Get the substring of [this] between [a] and [b].
  ///
  /// e.g.
  /// "I love flutter".between("l","t") == "ove flu"
  ///
  /// If [headGreedy] is false, it will return the longest matched part.
  ///
  /// e.g.
  /// "I love flutter".between("l","t",headGreedy = false) == "ove flut"
  String between(String a, String b, {bool headGreedy = true}) {
    // a = RegExp.escape(a);
    // b = RegExp.escape(b);
    if (indexOf(a) < 0) return null;
    if (headGreedy) {
      if (indexOf(b, indexOf(a) + a.length) < 0) return null;
      return substring(
          indexOf(a) + a.length, indexOf(b, indexOf(a) + a.length));
    } else {
      if (indexOf(b, lastIndexOf(a) + a.length) < 0) return null;
      return substring(
          lastIndexOf(a) + a.length, indexOf(b, lastIndexOf(a) + a.length));
    }
  }

  bool isAlpha() {
    var regex = RegExp("[A-Za-z]");
    return runes
        .map((e) => String.fromCharCode(e))
        .every((element) => regex.hasMatch(element));
  }

  bool isNumber() {
    var regex = RegExp("[0-9]");
    return runes
        .map((e) => String.fromCharCode(e))
        .every((element) => regex.hasMatch(element));
  }
}

extension ObjectEx on dynamic {
  /// Send the object itself as an event to [Constant.eventBus].
  void fire() {
    Constant.eventBus.fire(this);
  }
}

extension StateEx on State {
  /// Call [setState] to perform a global redrawing of the widget.
  void refreshSelf() {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
  }
}

extension MapEx on Map {
  /// Encode a map as a url query string.
  String encodeMap() {
    return keys.map((key) {
      var k = key.toString();
      var v = Uri.encodeComponent(this[key].toString());
      return '$k=$v';
    }).join('&');
  }
}

extension BuildContextEx on BuildContext {
  PersonInfo get personInfo =>
      Provider.of<ValueNotifier<PersonInfo>>(this, listen: false)?.value;
}
