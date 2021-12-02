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
import 'package:dan_xi/util/master_detail_utils.dart';
import 'package:flutter/cupertino.dart';

/// Some useful methods to help get an accurate size whether in mobile or tablet mode.
class ViewportUtils {
  static double getViewportWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getViewportHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static Size getMainNavigatorSize(BuildContext context) =>
      Size(getMainNavigatorWidth(context), getMainNavigatorHeight(context));

  static double getMainNavigatorWidth(BuildContext context) => isTablet(context)
      ? kTabletMasterContainerWidth
      : getViewportWidth(context);

  static double getMainNavigatorHeight(BuildContext context) =>
      getViewportHeight(context);
}
