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

import 'dart:async';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/report.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/widget/paged_listview.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/post_render.dart';
import 'package:dan_xi/widget/render/base_render.dart';
import 'package:dan_xi/widget/render/render_impl.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:linkify/linkify.dart';

/// This function preprocesses content downloaded from FDUHOLE so that
/// (1) HTML href is added to raw links
/// (2) Markdown Images are converted to HTML images.
String preprocessContentForDisplay(String content,
    {bool forceMarkdown = false}) {
  String result = "";
  int hrefCount = 0;

  /* Workaround Markdown images
  content = content.replaceAllMapped(RegExp(r"!\[\]\((https://.*?)\)"),
      (match) => "<img src=\"${match.group(1)}\"></img>");*/
  if (isHtml(content) && !forceMarkdown) {
    linkify(content, options: LinkifyOptions(humanize: false))
        .forEach((element) {
      if (element is UrlElement) {
        // Only add tag if tag has not yet been added.
        if (hrefCount == 0) {
          result += "<a href=\"" + element.url + "\">" + element.text + "</a>";
        } else {
          result += element.text;
          hrefCount--;
        }
      } else {
        if (element.text.contains('<a href='))
          hrefCount++;
        else if (element.text.contains('<img src="')) hrefCount++;
        result += element.text;
      }
    });
  } else {
    linkify(content, options: LinkifyOptions(humanize: false))
        .forEach((element) {
      if (element is UrlElement) {
        // Only add tag if tag has not yet been added.
        if (RegExp("\\[.*?\\]\\(${RegExp.escape(element.url)}\\)")
                .hasMatch(content) ||
            RegExp("\\[.*?${RegExp.escape(element.url)}.*?\\]\\(http.*?\\)")
                .hasMatch(content)) {
          result += element.url;
        } else {
          result += "[${element.text}](${element.url})";
        }
      } else
        result += element.text;
    });
  }
  return result;
}

/// A list page showing the content of a bbs post.
///
/// Arguments:
/// [BBSPost] or [Future<List<Reply>>] post: if [post] is BBSPost, show the page as a post.
/// Otherwise as a list of search result.
/// [bool] scroll_to_end: if [scroll_to_end] is true, the page will scroll to the end of
/// the post as soon as the page shows. This implies that [post] should be a [BBSPost].
///
class BBSReportDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSReportDetail({Key? key, this.arguments});

  @override
  _BBSReportDetailState createState() => _BBSReportDetailState();
}

class _BBSReportDetailState extends State<BBSReportDetail> {
  final PagedListViewController _listViewController = PagedListViewController();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<Report>> _loadContent(int page) {
    return PostRepository.getInstance().adminGetReports(page);
  }

  @override
  void initState() {
    super.initState();
  }

  /// Rebuild everything and refresh itself.
  void refreshSelf({scrollToEnd = false}) {
    if (scrollToEnd) _listViewController.queueScrollToEnd();
    _listViewController.notifyUpdate(useInitialData: false);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(resizeToAvoidBottomInset: false),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text("Reports"),
        ),
        trailingActions: [],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Theme.of(context).accentColor,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            refreshSelf();
          },
          child: Material(
              child: PagedListView<Report>(
            startPage: 1,
            pagedController: _listViewController,
            withScrollbar: true,
            scrollController: PrimaryScrollController.of(context),
            dataReceiver: _loadContent,
            builder: _getListItems,
            loadingBuilder: (BuildContext context) => Container(
              padding: EdgeInsets.all(8),
              child: Center(child: PlatformCircularProgressIndicator()),
            ),
            endBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(S.of(context).end_reached),
              ),
            ),
          )),
        ),
      ),
    );
  }

  _buildContextMenu(BuildContext context, Report e) => [
        PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              PostRepository.getInstance().adminSetReportDealt(e.id);
            },
            child: Text("Mark as dealt"),
          ),
          material: (_, __) => ListTile(
            title: Text("Mark as dealt"),
            onTap: () {
              Navigator.of(context).pop();
              PostRepository.getInstance().adminSetReportDealt(e.id);
            },
          ),
        ),
      ];

  Widget _getListItems(BuildContext context, ListProvider<Report> dataProvider,
      int index, Report e) {
    LinkTapCallback onLinkTap = (url) {
      BrowserUtil.openUrl(url!, context);
    };
    ImageTapCallback onImageTap = (url) {
      smartNavigatorPush(context, '/image/detail', arguments: {'url': url});
    };
    return GestureDetector(
      onLongPress: () {
        showPlatformModalSheet(
            context: context,
            builder: (BuildContext context) => PlatformWidget(
                  cupertino: (_, __) => CupertinoActionSheet(
                    actions: _buildContextMenu(context, e),
                    cancelButton: CupertinoActionSheetAction(
                      child: Text(S.of(context).cancel),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  material: (_, __) => Container(
                    height: 300,
                    child: Column(
                      children: _buildContextMenu(context, e),
                    ),
                  ),
                ));
      },
      child: Card(
        child: ListTile(
            dense: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.topLeft,
                    child: smartRender(e.reason!, onLinkTap, onImageTap)),
                Divider(),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(e
                        .content!)), //smartRender(e.content, onLinkTap, onImageTap)),
              ],
            ),
            subtitle: Column(children: [
              const SizedBox(
                height: 8,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  "#${e.post}",
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                ),
                Text(
                  HumanDuration.format(
                      context, DateTime.parse(e.date_created!)),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                ),
                GestureDetector(
                  child: Text("Mark as dealt",
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12)),
                  onTap: () {
                    PostRepository.getInstance().adminSetReportDealt(e.id);
                  },
                ),
              ]),
            ]),
            onTap: () async {
              ProgressFuture progressDialog = showProgressDialog(
                  loadingText: S.of(context).loading, context: context);
              try {
                final BBSPost post = await PostRepository.getInstance()
                    .loadSpecificDiscussion(e.discussion);
                smartNavigatorPush(context, "/bbs/postDetail", arguments: {
                  "post": post,
                });
                progressDialog.dismiss();
              } catch (error) {
                progressDialog.dismiss();
                Noticing.showNotice(context, error.toString(),
                    title: S.of(context).fatal_error);
              }
            }),
      ),
    );
  }
}

PostRenderWidget smartRender(String content, LinkTapCallback onTapLink,
        ImageTapCallback onTapImage) =>
    isHtml(content)
        ? PostRenderWidget(
            render: kHtmlRender,
            content: preprocessContentForDisplay(content),
            onTapImage: onTapImage,
            onTapLink: onTapLink,
          )
        : PostRenderWidget(
            render: kMarkdownRender,
            content: preprocessContentForDisplay(content),
            onTapImage: onTapImage,
            onTapLink: onTapLink,
          );
