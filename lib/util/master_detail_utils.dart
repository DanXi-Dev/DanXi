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

import 'package:flutter/widgets.dart';

const kTabletMasterContainerWidth = 370.0;

bool isTablet(BuildContext context) {
  // A tablet view (i.e. dual-pane layout) is defined as a device with a screen width of 840dp or greater.
  // Reference:
  // 1. https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes
  // 2. https://m2.material.io/design/layout/responsive-layout-grid.html#breakpoints
  // 3. https://m3.material.io/foundations/layout/applying-layout/window-size-classes
  return MediaQuery.widthOf(context) >= 840.0;
}
