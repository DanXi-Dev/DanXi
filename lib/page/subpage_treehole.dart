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
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/ad_manager.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/scroller_fix/primary_scroll_page.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/opentreehole/bbs_editor.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const kCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
  UserGroup.FUDAN_POSTGRADUATE_STUDENT,
  UserGroup.FUDAN_STAFF,
  UserGroup.SJTU_STUDENT
];

bool isHtml(String content) {
  var htmlMatcher = RegExp(r'<.+>.*</.+>', dotAll: true);
  return htmlMatcher.hasMatch(content);
}

/// Render the text from a clip of [content].
/// Also supports adding image tag to markdown posts
String renderText(String content, String imagePlaceholder) {
  if (!isHtml(content)) {
    content = md.markdownToHtml(content);
  }
  // Deal with Markdown
  content =
      content.replaceAll(RegExp(r"!\[.*\]\(http(s)?://.+\)"), imagePlaceholder);

  var soup = BeautifulSoup(content);
  var images = soup.findAll("img");
  if (images.length > 0) return soup.getText().trim() + imagePlaceholder;
  return soup.getText().trim();
}

const String KEY_NO_TAG = "默认";

class BBSSubpage extends PlatformSubpage with PageWithPrimaryScrollController {
  final Map<String, dynamic>? arguments;

  @override
  _BBSSubpageState createState() => _BBSSubpageState();

  BBSSubpage({Key? key, this.arguments});

  @override
  String get debugTag => "BBSPage";

  /// Build a list of options controlling how to sort posts.
  List<Widget> _buildSortOptionsList(BuildContext cxt) {
    List<Widget> list = [];
    Function onTapListener = (SortOrder newOrder) {
      Navigator.of(cxt).pop();
      SortOrderChangedEvent(newOrder).fire();
    };
    SortOrder.values.forEach((value) {
      list.add(PlatformWidget(
        cupertino: (_, __) => CupertinoActionSheetAction(
          onPressed: () => onTapListener(value),
          child: Text(value.displayTitle(cxt)!),
        ),
        material: (_, __) => ListTile(
          title: Text(value.displayTitle(cxt)!),
          onTap: () => onTapListener(value),
        ),
      ));
    });
    return list;
  }

  @override
  Create<List<AppBarButtonItem>> get leading => (cxt) => [
        AppBarButtonItem(
          S.of(cxt).sort_order,
          Icon(CupertinoIcons.sort_down_circle),
          () => showPlatformModalSheet(
            context: cxt,
            builder: (BuildContext context) => PlatformWidget(
              cupertino: (_, __) => CupertinoActionSheet(
                title: Text(S.of(cxt).sort_order),
                actions: _buildSortOptionsList(context),
                cancelButton: CupertinoActionSheetAction(
                  child: Text(S.of(context).cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              material: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildSortOptionsList(context),
              ),
            ),
          ),
        )
      ];

  @override
  Create<String> get title => (cxt) => S.of(cxt).forum;

  @override
  Create<List<AppBarButtonItem>> get trailing => (cxt) => [
        AppBarButtonItem(S.of(cxt).all_tags, Icon(PlatformIcons(cxt).tag),
            () => smartNavigatorPush(cxt, '/bbs/tags')),
        AppBarButtonItem(
            S.of(cxt).favorites,
            Icon(CupertinoIcons.star),
            () => smartNavigatorPush(cxt, '/bbs/discussions', arguments: {
                  'showFavoredDiscussion': true,
                })),
        AppBarButtonItem(
            S.of(cxt).new_post,
            Icon(PlatformIcons(cxt).addCircled),
            () => AddNewPostEvent().fire()),
      ];
}

class AddNewPostEvent {}

class RefreshBBSEvent {
  final bool refreshAll;

  RefreshBBSEvent({this.refreshAll = false});
}

class SortOrderChangedEvent {
  SortOrder newOrder;

  SortOrderChangedEvent(this.newOrder);
}

/// A list page showing bbs posts.
///
/// Arguments:
/// [bool] showFavoredDiscussion: if [showFavoredDiscussion] is not null,
/// it means this page is showing user's favored posts.
/// [String] tagFilter: if [tagFilter] is not null, it means this page is showing
/// the posts which is tagged with [tagFilter].
///
class _BBSSubpageState extends State<BBSSubpage>
    with AutomaticKeepAliveClientMixin {
  /// Unrelated to the state.
  /// These field should only be initialized once when created.
  final StateStreamListener _postSubscription = StateStreamListener();
  final StateStreamListener _refreshSubscription = StateStreamListener();
  final StateStreamListener _searchSubscription = StateStreamListener();
  final StateStreamListener _sortOrderChangedSubscription =
      StateStreamListener();
  String? _tagFilter;
  FocusNode _searchFocus = FocusNode();

  final PagedListViewController<OTHole> _listViewController =
      PagedListViewController();

  final TimeBasedLoadAdaptLayer<OTHole> adaptLayer =
      new TimeBasedLoadAdaptLayer(10, 1);

  /// Fields related to the display states.
  int _divisionId = 0;
  SortOrder? _sortOrder;
  FoldBehavior? _foldBehavior;

  BannerAd? bannerAd;

  /// This is to prevent the entire page being rebuilt on iOS when the keyboard pops up
  late bool _fieldInitComplete;

  ///Set the Future of the page to a single variable so that when the framework calls build(), the content is not reloaded every time.
  Future<List<OTHole>?> _loadContent(int page) async {
    // If PersonInfo is null, it means that the page is pushed with Navigator, and thus we shouldn't check for permission.
    if (checkGroup(kCompatibleUserGroup)) {
      _sortOrder = SettingsProvider.getInstance().fduholeSortOrder ??
          SortOrder.LAST_REPLIED;
      _foldBehavior = SettingsProvider.getInstance().fduholeFoldBehavior;
      if (_tagFilter != null)
        return await OpenTreeHoleRepository.getInstance()
            .loadTagFilteredDiscussions(_tagFilter!, _sortOrder!, page);
      else if (widget.arguments?.containsKey('showFavoredDiscussion') ??
          false) {
        if (page > 1) return Future.value([]);
        return await OpenTreeHoleRepository.getInstance().getFavoriteHoles();
      } else {
        if (!OpenTreeHoleRepository.getInstance().isUserInitialized)
          await OpenTreeHoleRepository.getInstance()
              .initializeUser(StateProvider.personInfo.value);
        List<OTHole>? loadedPost = await adaptLayer
            .generateReceiver(_listViewController, (lastElement) {
          DateTime time = DateTime.now();
          if (lastElement != null) {
            time = DateTime.parse(lastElement.time_created!);
          }
          return OpenTreeHoleRepository.getInstance()
              .loadHoles(time, _divisionId);
        }).call(page);
        // Filter blocked posts
        List<OTTag> hiddenTags =
            SettingsProvider.getInstance().hiddenTags ?? [];
        loadedPost?.removeWhere((element) => element.tags!.any((thisTag) =>
            hiddenTags.any((blockTag) => thisTag.name == blockTag.name)));

        // About this line, see [PagedListView].
        return loadedPost == null || loadedPost.isEmpty
            ? [OTHole.DUMMY_POST]
            : loadedPost;
      }
    } else {
      throw NotLoginError("Logged in as a visitor.");
    }
  }

  Future<void> refreshSelf() async {
    if (widget.arguments?.containsKey('showFavoredDiscussion') == true) {
      await OpenTreeHoleRepository.getInstance()
          .getFavoriteHoleId(forceUpdate: true);
    }
    await _listViewController.notifyUpdate();
  }

  Widget _buildSearchTextField() {
    // If user is filtering by tag, do not build search text field.
    if (_tagFilter != null ||
        (widget.arguments?.containsKey('showFavoredDiscussion') ?? false))
      return Container();
    final RegExp pidPattern = new RegExp(r'#[0-9]+');
    return Container(
      padding: Theme.of(context)
          .cardTheme
          .margin, //EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: CupertinoSearchTextField(
        focusNode: _searchFocus,
        placeholder: S.of(context).search_hint,
        onSubmitted: (value) {
          value = value.trim();
          if (value.isEmpty) return;
          // Determine if user is using #PID pattern to reach a specific post
          if (value.startsWith(pidPattern)) {
            // We needn't deal with the situation that "id = null" here.
            // If so, it will turn into a 404 http error.
            try {
              _goToPIDResultPage(
                  int.parse(pidPattern.firstMatch(value)![0]!.substring(1)));
              return;
            } catch (ignored) {}
          }
          smartNavigatorPush(context, "/bbs/postDetail",
              arguments: {"searchKeyword": value});
        },
      ),
    );
  }

  Widget _autoAdminNotice() {
    return FutureWidget<bool?>(
      future: OpenTreeHoleRepository.getInstance().isUserAdmin(),
      successBuilder: (context, snapshot) {
        if (snapshot.data as bool) {
          return Card(
            child: ListTile(
              title: Text("FDUHole Administrative Interface"),
              subtitle: Text(
                "Status: Authorized",
                style: TextStyle(color: Colors.green),
              ),
              onTap: () {
                smartNavigatorPush(context, "/bbs/reports");
              },
            ),
          );
        }
        return Container();
      },
      errorBuilder: Container(),
      loadingBuilder: Container(),
    );
  }

  _goToPIDResultPage(int pid) async {
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    try {
      final OTHole post =
          await OpenTreeHoleRepository.getInstance().loadSpecificHole(pid);
      smartNavigatorPush(context, "/bbs/postDetail", arguments: {
        "post": post,
      });
    } catch (error) {
      if (error is DioError &&
          error.response?.statusCode == HttpStatus.notFound)
        Noticing.showNotice(context, S.of(context).post_does_not_exist,
            title: S.of(context).fatal_error);
      else
        Noticing.showNotice(context, error.toString(),
            title: S.of(context).fatal_error);
    }
    progressDialog.dismiss();
  }

  @override
  void initState() {
    super.initState();
    _fieldInitComplete = false;
    _postSubscription.bindOnlyInvalid(
        Constant.eventBus.on<AddNewPostEvent>().listen((_) async {
          final bool success =
              await BBSEditor.createNewPost(context, _divisionId);
          if (success) refreshSelf();
        }),
        hashCode);
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshBBSEvent>().listen((event) {
          if (event.refreshAll == true) {
            _refreshAll();
          } else
            refreshSelf();
        }),
        hashCode);
    _sortOrderChangedSubscription.bindOnlyInvalid(
        Constant.eventBus.on<SortOrderChangedEvent>().listen((event) {
          SettingsProvider.getInstance().fduholeSortOrder =
              _sortOrder = event.newOrder;
          refreshSelf();
        }),
        hashCode);
    bannerAd = AdManager.loadBannerAd(1); // 1 for bbs page
  }

  void _refreshAll() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    if (!_fieldInitComplete) {
      if (widget.arguments != null &&
          widget.arguments!.containsKey('tagFilter'))
        _tagFilter = widget.arguments!['tagFilter'];
      _fieldInitComplete = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    _postSubscription.cancel();
    _refreshSubscription.cancel();
    _searchSubscription.cancel();
    _sortOrderChangedSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.arguments == null)
      return _buildPageBody();
    else if (widget.arguments!.containsKey('showFavoredDiscussion')) {
      return PlatformScaffold(
        iosContentPadding: false,
        iosContentBottomPadding: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).favorites),
        ),
        body: _buildPageBody(),
      );
    }
    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).filtering_by_tag(_tagFilter ?? "?")),
      ),
      body: _buildPageBody(),
    );
  }

  Widget _buildPageBody() {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/graphics/kavinzhao.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Theme.of(context).accentColor,
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await refreshSelf();
            },
            child: PagedListView<OTHole>(
                noneItem: OTHole.DUMMY_POST,
                pagedController: _listViewController,
                withScrollbar: true,
                scrollController: widget.primaryScrollController(context),
                startPage: 1,
                builder: _buildListItem,
                headBuilder: (_) => Column(
                      children: [
                        AutoBannerAdWidget(bannerAd: bannerAd),
                        _buildSearchTextField(),
                        _autoAdminNotice()
                      ],
                    ),
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
                emptyBuilder: (_) => _buildEmptyFavoritesPage(),
                dataReceiver: _loadContent),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesPage() => Container(
        padding: EdgeInsets.all(8),
        child: Center(child: Text(S.of(context).no_favorites)),
      );

  _launchUrlWithNotice(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      BrowserUtil.openUrl(link.url, context);
    } else {
      Noticing.showNotice(context, S.of(context).cannot_launch_url);
    }
  }

  Widget _buildListItem(BuildContext context, ListProvider<OTHole> _, int index,
      OTHole postElement) {
    if (postElement.floors?.first_floor == null ||
        postElement.floors?.last_floor == null ||
        (_foldBehavior == FoldBehavior.HIDE && postElement.is_folded))
      return Container();
    Linkify postContentWidget = Linkify(
      text: renderText(postElement.floors!.first_floor!.filteredContent!,
          S.of(context).image_tag),
      style: TextStyle(fontSize: 16),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
      onOpen: _launchUrlWithNotice,
    );
    final TextStyle infoStyle =
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);
    return Card(
      child: Column(children: [
        ListTile(
            contentPadding: EdgeInsets.fromLTRB(16, 4, 10, 0),
            dense: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                generateTagWidgets(context, postElement, (String? tagname) {
                  smartNavigatorPush(context, '/bbs/discussions', arguments: {
                    "tagFilter": tagname,
                  });
                }, SettingsProvider.getInstance().useAccessibilityColoring),
                const SizedBox(
                  height: 10,
                ),
                (postElement.is_folded && _foldBehavior == FoldBehavior.FOLD)
                    ? Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          expandedAlignment: Alignment.topLeft,
                          childrenPadding: EdgeInsets.symmetric(vertical: 4),
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            S.of(context).folded,
                            style: infoStyle,
                          ),
                          children: [
                            postContentWidget,
                          ],
                        ),
                      )
                    : postContentWidget,
              ],
            ),
            subtitle: Column(
              children: [
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "#${postElement.hole_id}",
                      style: infoStyle,
                    ),
                    Text(
                      HumanDuration.format(
                          context, DateTime.parse(postElement.time_created!)),
                      style: infoStyle,
                    ),
                    Row(
                      children: [
                        Text(
                          "${postElement.reply} ",
                          style: infoStyle,
                        ),
                        Icon(
                          CupertinoIcons.ellipses_bubble,
                          size: infoStyle.fontSize,
                          color: infoStyle.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              smartNavigatorPush(context, "/bbs/postDetail", arguments: {
                "post": postElement,
              });
            }),
        if (!(postElement.is_folded && _foldBehavior == FoldBehavior.FOLD) &&
            postElement.floors?.last_floor!.hole_id !=
                postElement.floors?.first_floor!.hole_id)
          Divider(
            height: 4,
          ),
        if (!(postElement.is_folded && _foldBehavior == FoldBehavior.FOLD) &&
            postElement.floors?.last_floor!.hole_id !=
                postElement.floors?.first_floor!.hole_id)
          _buildCommentView(postElement),
      ]),
    );
  }

  Widget _buildCommentView(OTHole postElement, {bool useLeading = true}) {
    final String lastReplyContent = renderText(
        postElement.floors!.last_floor!.filteredContent!,
        S.of(context).image_tag);
    return ListTile(
        dense: true,
        minLeadingWidth: 16,
        leading: useLeading
            ? Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(
                  CupertinoIcons.quote_bubble,
                  color: Theme.of(context).hintColor,
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).latest_reply(
                          postElement.floors!.last_floor!.anonyname ?? "?",
                          HumanDuration.format(
                              context,
                              DateTime.parse(postElement
                                  .floors!.last_floor!.time_created!))),
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    Icon(CupertinoIcons.search,
                        size: 14,
                        color: Theme.of(context).hintColor.withOpacity(0.2)),
                  ]),
            ),
            Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Linkify(
                    text: lastReplyContent.trim().isEmpty
                        ? S.of(context).no_summary
                        : lastReplyContent,
                    style: TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    onOpen: _launchUrlWithNotice)),
          ],
        ),
        onTap: () => smartNavigatorPush(context, "/bbs/postDetail", arguments: {
              "post": postElement,
              "scroll_to_end": true,
            }));
  }

  @override
  bool get wantKeepAlive => true;
}

/// This class is a workaround between Open Tree Hole's time-based content retrieval
/// and [PagedListView]'s page-based loading style.
class TimeBasedLoadAdaptLayer<T> {
  final int pageSize;
  final int startPage;

  TimeBasedLoadAdaptLayer(this.pageSize, this.startPage);

  DataReceiver<T> generateReceiver(PagedListViewController<T> controller,
      TimeBasedDataReceiver<T> receiver) {
    return (int pageIndex) async {
      int nextPageEnd = pageSize * (pageIndex - startPage + 1);
      if (controller.length() == 0 || pageIndex == startPage) {
        // If this is the first page, call with nothing.
        return receiver.call(null);
      } else if (nextPageEnd < controller.length()) {
        // If this is not the first page, and we have loaded beyond [pageIndex],
        // we should loaded it again with the last item of previous page.
        return receiver
            .call(controller.getElementAt(nextPageEnd - startPage - 1));
      } else {
        // If requesting a brand new page, just loaded it with info of the last item.
        return receiver.call(controller.getElementAt(controller.length() - 1));
      }
    };
  }
}

typedef TimeBasedDataReceiver<T> = Future<List<T>?> Function(T? lastElement);
