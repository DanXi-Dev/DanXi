/*
 *     Copyright (C) 2021  w568w
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

/// A Feature is a functional item shown on the dashboard, with which user interacts via tapping.
abstract class Feature {
  /// Request FeatureContainer to update the content text/icon since they're changed
  notifyUpdate() => container.doUpdate();

  bool get clickable => false;

  Widget get icon => null;

  String get mainTitle;

  String get subTitle => null;

  String get tertiaryTitle => null;

  FeatureContainer container;

  BuildContext context;

  void buildFeature() {}

  /// Called when FeatureContainer invokes [initState].
  void initFeature() {}

  /// Called when Feature is clicked.
  void onTap() {}
}

/// FeatureContainer is a container to render the feature as a list item. Usually is a class of [State<StatefulWidget>]
mixin FeatureContainer {
  void doUpdate();
}
