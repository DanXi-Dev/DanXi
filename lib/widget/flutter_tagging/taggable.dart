// Copyright 2020 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A base class to facilitate [operator==] and [hashCode] overrides.
///
/// ```dart
/// class ConstTest extends Taggable {
///   const ConstTest(this.a);
///
///   final int a;
///
///   @override
///   List<Object> get props => [a];
/// }
/// ```
@immutable
abstract class Taggable {
  /// The [List] of `props` (properties) which will be used to determine whether
  /// two [Taggables] are equal.
  List<Object> get props;

  /// If true, string comparison will be case sensitive.
  bool get caseSensitive => false;

  /// A class that helps implement equality
  /// without needing to explicitly override == and [hashCode].
  /// Taggables override their own `==` operator and [hashCode] based on their `props`.
  const Taggable();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Taggable &&
          runtimeType == other.runtimeType &&
          _equals(props, other.props, caseSensitive);

  @override
  int get hashCode => runtimeType.hashCode ^ _mapPropsToHashCode(props);

  @override
  String toString() => '$runtimeType';
}

/// You must define the [TaggableMixin] on the class
/// which you want to make Taggable.
///
/// [TaggableMixin] does the override of the `==` operator as well as `hashCode`.
mixin TaggableMixin implements Taggable {
  /// The [List] of `props` (properties) which will be used to determine whether
  /// two [Taggables] are equal.
  List<Object> get props;

  /// If true, string comparison will be case sensitive.
  bool get caseSensitive => false;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TaggableMixin &&
            runtimeType == other.runtimeType &&
            _equals(props, other.props, caseSensitive);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ _mapPropsToHashCode(props);

  @override
  String toString() => '$runtimeType';
}

int _mapPropsToHashCode(dynamic props) {
  var hashCode = 0;

  if (props is Map) {
    props.forEach((key, value) {
      final propHashCode =
          _mapPropsToHashCode(key) ^ _mapPropsToHashCode(value);
      hashCode = hashCode ^ propHashCode;
    });
  } else if (props is List || props is Iterable || props is Set) {
    props.forEach((prop) {
      final propHashCode =
          (prop is List || prop is Iterable || prop is Set || prop is Map)
              ? _mapPropsToHashCode(prop)
              : prop.hashCode;
      hashCode = hashCode ^ propHashCode;
    });
  } else {
    hashCode = hashCode ^ props.hashCode;
  }

  return hashCode;
}

const DeepCollectionEquality _equality = DeepCollectionEquality();

bool _equals(List list1, List list2, bool caseSensitive) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  var length = list1.length;
  if (length != list2.length) return false;

  for (var i = 0; i < length; i++) {
    final unit1 = list1[i];
    final unit2 = list2[i];

    if (unit1 is Iterable || unit1 is List || unit1 is Map || unit1 is Set) {
      if (!_equality.equals(unit1, unit2)) return false;
    } else if (unit1?.runtimeType != unit2?.runtimeType) {
      return false;
    } else if (unit1 is String) {
      if (caseSensitive && unit1.compareTo(unit2) != 0) {
        return false;
      }
      if (!caseSensitive &&
          unit1.toLowerCase().compareTo(unit2.toLowerCase()) != 0) {
        return false;
      }
    } else if (unit1 != unit2) {
      return false;
    }
  }
  return true;
}
