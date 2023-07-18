/*
 * Copyright (c) 2021. w568w
 */

class Pair<T, V> {
  final T first;
  final V second;

  Pair(this.first, this.second);

  @override
  String toString() => '{$first,$second}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pair &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second;

  @override
  int get hashCode => first.hashCode ^ second.hashCode;
}
