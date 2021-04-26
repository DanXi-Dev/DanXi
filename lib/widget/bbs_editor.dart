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
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class BBSEditor {

  static Future<void> createNewPost(BuildContext context) async {
    //TODO: tag editor
    String content = await _showEditor(context, "TODO: feature under construction");
    if (content == null || content == "") return;
    //TODO: POST to server
    // Obtain token form postRepository

    //TODO: handle failure
  }

  static Future<void> createNewReply(BuildContext context, int discussionId, int postId) async {
    String content = await _showEditor(context, postId == null ? S.of(context).reply_to(discussionId) : S.of(context).reply_to(postId));
    if (content == null || content == "") return;

    int responseCode = await PostRepository.getInstance().newReply(discussionId, postId, content);
    // Note: postId refers to the specific post the user is replying to, can be NULL
    if (responseCode != 200) {
      Noticing.showNotice(context, S.of(context).reply_failed(responseCode));
    }
    else {
      //TODO: Refresh Page to load new reply
    }
  }

  static Future<void> reportPost(BuildContext context, int postId) async {
    String content = await _showEditor(context, S.of(context).reason_report_post(postId));
    if (content == null || content == "") return;

    int responseCode = await PostRepository.getInstance().reportPost(postId, content);
    if (responseCode != 200) {
      Noticing.showNotice(context, S.of(context).report_failed(responseCode));
    }
    else {
      Noticing.showNotice(context, S.of(context).report_success);
    }
  }

  static Future<String> _showEditor(BuildContext context, String title) async {
    HtmlEditorController _controller = HtmlEditorController();
    await showPlatformDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(title),
          content: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width * 0.9,
              child: HtmlEditor(
                  controller: _controller,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: S.of(context).editor_hint,
                  ),
                  htmlToolbarOptions: HtmlToolbarOptions(
                      defaultToolbarButtons: [
                        //add constructors here and set buttons to false, e.g.
                        StyleButtons(),
                        FontSettingButtons(fontSizeUnit: false),
                        FontButtons(),
                        ColorButtons(),
                        ListButtons(),
                        ParagraphButtons(caseConverter: false),
                        InsertButtons(audio: false, video: false, otherFile: false),
                        OtherButtons(fullscreen: false, codeview: false,),
                      ]
                  ),
                  otherOptions: OtherOptions(
                    //height: MediaQuery.of(context).size.height * 0.5,
                  ),
                callbacks: Callbacks(
                  onInit: () {
                    _controller.setFullScreen();
                  },
                  onImageUpload: (fileUpload) {
                    //TODO: handle this
                  }
                ),
                ),
          ),
          actions: [
            TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () {
                  Navigator.of(context).pop();
                  return null;
                }),
            TextButton(
                child: Text(S.of(context).submit),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          ],
        )
    );
    return await _controller.getText();
  }
}