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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nil/nil.dart';

/// A helper class to convert [String], [WidgetBuilder], [List<Widget>] or something similar into [Widget].
class SmartWidget {
  static Widget toWidget<T>(dynamic object, BuildContext context,
      {Widget? fallback,
      AsyncSnapshot<T>? snapshot,
      int? index,
      Widget? child,
      VoidCallback? onStepContinue,
      VoidCallback? onStepCancel}) {
    fallback ??= nil;
    if (object == null) return fallback;

    if (object is String) {
      return Text(object);
    } else if (object is WidgetBuilder) {
      return object(context);
    } else if (object is IndexedWidgetBuilder ||
        object is NullableIndexedWidgetBuilder) {
      return object(context, index);
    } else if (object is TransitionBuilder) {
      return object(context, child);
    } else if (object is AsyncWidgetBuilder<T> ||
        object is AsyncWidgetBuilder<T?>) {
      return object(context, snapshot!);
    }
    // TODO: Due to framework change, this has been temporarily disabled
    /* else if (object is ControlsWidgetBuilder) {
      return object(context,
          onStepContinue: onStepContinue, onStepCancel: onStepCancel);
    } */
    else if (object is Function) {
      return object();
    } else if (object is Widget) {
      return object;
    } else if (object is List) {
      return ListView(
        children: object.map((e) => toWidget(e, context)) as List<Widget>,
      );
    }
    return fallback;
  }
}
