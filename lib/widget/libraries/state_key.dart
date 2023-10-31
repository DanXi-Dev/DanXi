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

import 'package:flutter/cupertino.dart';

/// StateKey is a ValueKey with current context of the child widget.
/// With the help of [WithStateKey], we can easily obtain a widget instance just with the key.
///
/// However, the key may not be used as a "true" key to pass to a widget's initializer,
/// since it is not immutable and not reliable.
class StateKey<T> extends ValueKey<T> {
  late BuildContext currentContext;

  StateKey(super.value);
}

class WithStateKey<T> extends StatefulWidget {
  final StateKey<T>? childKey;
  final Widget? child;

  const WithStateKey({super.key, this.childKey, this.child});

  @override
  WithStateKeyState<T> createState() => WithStateKeyState<T>();
}

class WithStateKeyState<T> extends State<WithStateKey<T>>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    widget.childKey!.currentContext = context;
    return widget.child!;
  }

  @override
  void initState() {
    super.initState();
    widget.childKey!.currentContext = context;
  }

  @override
  bool get wantKeepAlive => true;
}
