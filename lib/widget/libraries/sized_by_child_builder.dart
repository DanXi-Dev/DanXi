/*
 *     Copyright (C) 2023  DanXi-Dev
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

import 'package:flutter/widgets.dart';

/// This widget is used to build a widget with sizes determined by its [child],
/// after that, the sizes will be remembered and used for the next build,
/// which calls [builder] with the remembered sizes.
class SizedByChildBuilder extends StatefulWidget {
  final Widget Function(BuildContext, Key) child;
  final Widget Function(BuildContext, Size) builder;

  const SizedByChildBuilder(
      {super.key, required this.child, required this.builder});

  @override
  State<SizedByChildBuilder> createState() => _SizedByChildBuilderState();
}

class _SizedByChildBuilderState extends State<SizedByChildBuilder> {
  Size? _size;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then(
      (_) {
        if (mounted && _size == null) {
          setState(() {
            _size = _key.currentContext!.size;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_size == null) {
      return widget.child(context, _key);
    } else {
      return widget.builder(context, _size!);
    }
  }
}
