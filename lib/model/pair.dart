/*
 * Copyright (c) 2021. w568w
 */

class Pair<T, V> {
  final T first;
  final V second;

  Pair(this.first, this.second);

  @override
  String toString() => '{$first,$second}';
}
