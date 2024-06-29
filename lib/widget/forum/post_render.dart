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

import 'package:dan_xi/widget/forum/render/base_render.dart';
import 'package:flutter/widgets.dart';

class PostRenderWidget extends StatelessWidget {
  final String? content;
  final BaseRender render;
  final ImageTapCallback? onTapImage;
  final LinkTapCallback? onTapLink;
  final bool hasBackgroundImage;
  final bool isPreviewWidget;

  const PostRenderWidget(
      {super.key,
      required this.content,
      required this.render,
      this.onTapImage,
      this.onTapLink,
      required this.hasBackgroundImage,
      this.isPreviewWidget = false});

  @override
  Widget build(BuildContext context) => render.call(context, content,
      onTapImage, onTapLink, hasBackgroundImage, isPreviewWidget);
}
