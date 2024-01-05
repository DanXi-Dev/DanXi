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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/scale_transform.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A slightly smaller version of [CircularProgressIndicator].
///
/// It is commonly used in [Feature] to indicate that the feature is loading.
class FeatureProgressIndicator extends StatelessWidget {
  const FeatureProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaleTransform(
      scale: PlatformX.isMaterial(context) ? 0.5 : 1.0,
      child: PlatformCircularProgressIndicator(),
    );
  }
}
