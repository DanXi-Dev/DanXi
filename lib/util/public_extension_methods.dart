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
import 'dart:math';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';

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
  String? between(String a, String b, {bool headGreedy = true}) {
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

extension ObjectNullSafetyEx<T> on T? {
  V? apply<V>(V Function(T) applier) {
    if (this != null) {
      return applier.call(this as T);
    } else {
      return null;
    }
  }
}

extension StateEx on State {
  /// Call [setState] to perform a global redrawing of the widget.
  Future<void> refreshSelf() {
    Completer<void> completer = Completer();
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        completer.complete();
      });
      return completer.future;
    }
    return Future.value();
  }
}

extension MapEx<K, V> on Map<K, V> {
  /// Encode a map as a url query string.
  String encodeMap() {
    return keys.map((key) {
      var k = key.toString();
      var v = Uri.encodeComponent(this[key].toString());
      return '$k=$v';
    }).join('&');
  }

  V opt(K key, V defaultValue) => containsKey(key) ? this[key]! : defaultValue;
}

extension ToStr on bool {
  String toRequestParamStringRepresentation() {
    if (this) return "1";
    return "0";
  }
}

extension ListEx<T> on List<T>? {
  /// Remove any element in list which [filter] returns false.
  List<T> filter(FilterFunction<T> filter) {
    List<T> newList = [];
    this?.forEach((element) {
      if (filter(element)) {
        newList.add(element);
      }
    });
    return newList;
  }

  /// Join [generator] between every element of this list.
  List<T>? joinElement(T Function() generator) {
    if (this == null) return null;
    List<T> newList = [];
    for (int i = 0; i < this!.length; i++) {
      newList.add(this!.elementAt(i));
      if (i != this!.length - 1) {
        newList.add(generator.call());
      }
    }
    return newList;
  }

  T? get(int index, [T? defaultValue]) {
    if (this != null && index >= 0 && index < this!.length) return this![index];
    return defaultValue;
  }
}

typedef FilterFunction<T> = bool Function(T element);

extension HSL on Color {
  Color withHue(double hue) {
    return HSLColor.fromColor(this).withHue(hue).toColor();
  }

  Color withSaturation(double saturation) {
    return HSLColor.fromColor(this).withSaturation(saturation).toColor();
  }

  Color withLightness(double lightness) {
    return HSLColor.fromColor(this).withLightness(lightness).toColor();
  }

  Color autoAdapt() {
    final HSLColor hslColor = HSLColor.fromColor(this);
    if (PlatformX.isDarkMode) {
      if (hslColor.lightness < 0.5) {
        return hslColor
            .withLightness((sqrt(hslColor.lightness) * 3 / 2))
            .toColor();
      }
    } else {
      if (hslColor.lightness > 0.5) {
        return hslColor
            .withLightness((hslColor.lightness * hslColor.lightness * 2 / 3))
            .toColor();
      }
    }

    return this;
  }
}

extension HashColor on String {
  Color hashColor() {
    final String text = this;
    if (text.isEmpty || text.startsWith("*")) return Colors.red;
    var sum = 0;
    for (var code in text.runes) {
      sum += code;
    }
    return Constant.getColorFromString(
                Constant.TAG_COLOR_LIST[sum % Constant.TAG_COLOR_LIST.length])[
            PlatformX.isDarkMode ? 300 : 800] ??
        Colors.red;
  }
}
