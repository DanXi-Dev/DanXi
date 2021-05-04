/*
 *     Copyright (C) 2021 kavinzhao
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
import 'package:dan_xi/page/bbs_editor.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_quill/widgets/controller.dart';

class BBSEditor {
  static Future<void> createNewReply(
      BuildContext context, int discussionId, int postId) async {
    String content = await _showEditor(
        context,
        postId == null
            ? S.of(context).reply_to(discussionId)
            : S.of(context).reply_to(postId));
    if (content == null || content == "") return;

    int responseCode = await PostRepository.getInstance()
        .newReply(discussionId, postId, content);
    // Note: postId refers to the specific post the user is replying to, can be NULL
    if (responseCode != 200) {
      Noticing.showNotice(context, S.of(context).reply_failed(responseCode));
    } else {
      //TODO: Refresh Page to load new reply
    }
  }

  static Future<void> reportPost(BuildContext context, int postId) async {
    String content =
        await _showEditor(context, S.of(context).reason_report_post(postId));
    if (content == null || content == "") return;

    int responseCode =
        await PostRepository.getInstance().reportPost(postId, content);
    if (responseCode != 200) {
      Noticing.showNotice(context, S.of(context).report_failed(responseCode));
    } else {
      Noticing.showNotice(context, S.of(context).report_success);
    }
  }

  static Future<String> _showEditor(BuildContext context, String title) async {
    QuillController _controller = QuillController.basic();
    return await showPlatformDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width * 0.9,
                child: BBSEditorWidget(
                  controller: _controller,
                ),
              ),
              actions: [
                PlatformDialogAction(
                    child: Text(S.of(context).cancel),
                    onPressed: () {
                      Navigator.of(context).pop<String>(null);
                    }),
                PlatformDialogAction(
                    child: Text(S.of(context).submit),
                    onPressed: () async {
                      Navigator.of(context)
                          .pop<String>(BBSEditorWidget.getText(_controller));
                    }),
              ],
            ));
  }
}
