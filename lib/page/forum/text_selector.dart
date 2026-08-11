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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/forum/post_render.dart';
import 'package:dan_xi/widget/forum/render/render_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A full-screen page to allow user to select text with a larger font size, using
/// selectable markdown render [kMarkdownSelectorRender].
///
/// Arguments:
/// [String] text: the text to display.
class TextSelectorPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  TextSelectorPageState createState() => TextSelectorPageState();

  const TextSelectorPage({super.key, this.arguments});
}

class TextSelectorPageState extends State<TextSelectorPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: true,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).free_select),
        ),
        body: PostRenderWidget(
          render: kMarkdownSelectorRender,
          content: widget.arguments!['text'],
          hasBackgroundImage: false,
        ));
  }
}
