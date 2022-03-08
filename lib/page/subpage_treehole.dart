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
import 'dart:convert';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/division.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/ad_manager.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/opentreehole/horizontal_selector.dart';
import 'package:dan_xi/widget/opentreehole/login_widgets.dart';
import 'package:dan_xi/widget/opentreehole/render/render_impl.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/selector.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widget/opentreehole/tag_selector/tag.dart';

const kCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
  UserGroup.FUDAN_POSTGRADUATE_STUDENT,
  UserGroup.FUDAN_STAFF,
  UserGroup.SJTU_STUDENT,
  UserGroup.VISITOR
];

bool isHtml(String content) {
  var htmlMatcher = RegExp(r'<.+>.*</.+>', dotAll: true);
  return htmlMatcher.hasMatch(content);
}

final RegExp latexRegExp = RegExp(r"<(tex|texLine)>.*?</(tex|texLine)>",
    multiLine: true, dotAll: true);
final RegExp mentionRegExp =
    RegExp(r"<(floor|hole)_mention>(.*?)</(floor|hole)_mention>");

/// Render the text from a clip of [content].
/// Also supports adding image tag to markdown posts
String renderText(
    String content, String imagePlaceholder, String formulaPlaceholder,
    {bool removeMentions = true}) {
  String originalContent = content;
  if (!isHtml(content)) {
    content = md.markdownToHtml(content, inlineSyntaxes: [
      LatexSyntax(),
      LatexMultiLineSyntax(),
      if (removeMentions) MentionSyntax()
    ]);
  }
  // Deal with LaTeX
  content = content.replaceAll(latexRegExp, formulaPlaceholder);
  // Deal with Mention
  if (removeMentions) content = content.replaceAll(mentionRegExp, "");
  BeautifulSoup soup = BeautifulSoup(content);
  List<Bs4Element> images = soup.findAll("img");
  if (images.isNotEmpty) {
    return soup.getText().trim() + imagePlaceholder;
  }

  String result = soup.getText().trim();

  // If we have reduce the text to nothing, we would rather not remove mention texts.
  if (result.isEmpty && removeMentions) {
    return renderText(originalContent, imagePlaceholder, formulaPlaceholder,
        removeMentions: false);
  } else {
    return result;
  }
}

/// Return [OTHole] with all floors prefetched for increased performance when scrolling to the end.
Future<OTHole> prefetchAllFloors(OTHole hole) async {
  if (hole.reply != null && hole.reply! < Constant.POST_COUNT_PER_PAGE) {
    return hole;
  }
  List<OTFloor>? floors = await OpenTreeHoleRepository.getInstance()
      .loadFloors(hole, startFloor: 0, length: 0);

  var holeCopy = OTHole.fromJson(jsonDecode(jsonEncode(hole)));
  return holeCopy..floors?.prefetch = floors;
}

const String KEY_NO_TAG = "默认";

class OTTitle extends StatelessWidget {
  const OTTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<OTDivision> divisions =
        OpenTreeHoleRepository.getInstance().getDivisions();
    OTDivision? division = context
        .select<FDUHoleProvider, OTDivision?>((value) => value.currentDivision);
    int currentIndex;
    if (division != null) {
      currentIndex = divisions.indexOf(division);
    } else {
      currentIndex = 0;
    }
    return Expanded(
      child: TagContainer(
          fillRandomColor: false,
          fixedColor: Theme.of(context).colorScheme.tertiary,
          fontSize: 12,
          enabled: true,
          wrapped: false,
          singleChoice: true,
          defaultChoice: currentIndex,
          onChoice: (Tag tag, list) {
            division = context.read<FDUHoleProvider>().currentDivision =
                divisions.firstWhere((element) => element.name == tag.tagTitle);
            DivisionChangedEvent(division!).fire();
          },
          tagList: divisions
              .map((e) => Tag(e.name, null, checkedIcon: null))
              .toList()),
    );
    return HorizontalSelector<OTDivision>(
        options: OpenTreeHoleRepository.getInstance().getDivisions(),
        onSelect: (division) {
          context.read<FDUHoleProvider>().currentDivision = division;
          DivisionChangedEvent(division).fire();
        },
        selectedOption: division);
  }
}

class TreeHoleSubpage extends PlatformSubpage<TreeHoleSubpage> {
  final Map<String, dynamic>? arguments;

  @override
  TreeHoleSubpageState createState() => TreeHoleSubpageState();

  const TreeHoleSubpage({Key? key, this.arguments}) : super(key: key);

  @override
  Create<List<AppBarButtonItem>> get leading => (cxt) => [
        AppBarButtonItem(
          S.of(cxt).messages,
          Icon(PlatformX.isMaterial(cxt)
              ? Icons.notifications
              : CupertinoIcons.bell),
          () {
            if (cxt.read<FDUHoleProvider>().isUserInitialized) {
              smartNavigatorPush(cxt, '/bbs/messages',
                  forcePushOnMainNavigator: true);
            }
          },
        )
      ];

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).forum);

  @override
  Create<List<AppBarButtonItem>> get trailing => (cxt) =>
  [
        if (OpenTreeHoleRepository.getInstance().isAdmin) ...[
          AppBarButtonItem(
              S.of(cxt).reports,
              Icon(PlatformX.isMaterial(cxt)
                  ? Icons.report_outlined
                  : CupertinoIcons.exclamationmark_octagon), () {
            smartNavigatorPush(cxt, "/bbs/reports");
          })
        ],
        // AppBarButtonItem(S.of(cxt).all_tags, Icon(PlatformIcons(cxt).tag), () {
        //   if (OpenTreeHoleRepository.getInstance().isUserInitialized) {
        //     smartNavigatorPush(cxt, '/bbs/tags',
        //         forcePushOnMainNavigator: true);
        //   }
        // }),
        AppBarButtonItem(
            S.of(cxt).favorites,
            Icon(PlatformX.isMaterial(cxt)
                ? Icons.star_outline
                : CupertinoIcons.star), () {
          if (cxt.read<FDUHoleProvider>().isUserInitialized) {
            smartNavigatorPush(cxt, '/bbs/discussions',
                arguments: {'showFavoredDiscussion': true},
                forcePushOnMainNavigator: true);
          }
        }),
        AppBarButtonItem(
            S.of(cxt).new_post, Icon(PlatformIcons(cxt).addCircled), () {
          if (cxt.read<FDUHoleProvider>().isUserInitialized) {
            AddNewPostEvent().fire();
          }
        }),
      ];

  @override
  void onDoubleTapOnTab() => RefreshBBSEvent().fire();
}

class AddNewPostEvent {}

class RefreshBBSEvent {}

class DivisionChangedEvent {
  final OTDivision newDivision;

  DivisionChangedEvent(this.newDivision);
}

enum PostsType { FAVORED_DISCUSSION, FILTER_BY_TAG, NORMAL_POSTS }

/// A list page showing bbs posts.
///
/// Arguments:
/// [bool] showFavoredDiscussion: if [showFavoredDiscussion] is not null,
/// it means this page is showing user's favored posts.
/// [String] tagFilter: if [tagFilter] is not null, it means this page is showing
/// the posts which is tagged with [tagFilter].
///
class TreeHoleSubpageState extends PlatformSubpageState<TreeHoleSubpage> {
  /// Unrelated to the state.
  /// These field should only be initialized once when created.
  final StateStreamListener<AddNewPostEvent> _postSubscription =
      StateStreamListener();
  final StateStreamListener<RefreshBBSEvent> _refreshSubscription =
      StateStreamListener();
  final StateStreamListener<DivisionChangedEvent> _divisionChangedSubscription =
      StateStreamListener();
  final GlobalKey<RefreshIndicatorState> indicatorKey =
      GlobalKey<RefreshIndicatorState>();

  String? _tagFilter;
  PostsType _postsType = PostsType.NORMAL_POSTS;

  final PagedListViewController<OTHole> listViewController =
      PagedListViewController();

  final TimeBasedLoadAdaptLayer<OTHole> adaptLayer =
      TimeBasedLoadAdaptLayer(Constant.POST_COUNT_PER_PAGE, 1);

  /// Fields related to the display states.
  static int getDivisionId(BuildContext context) =>
      context.read<FDUHoleProvider>().currentDivision?.division_id ?? 1;

  FoldBehavior? get foldBehavior => foldBehaviorFromInternalString(
      OpenTreeHoleRepository.getInstance().userInfo?.config?.show_folded);

  BannerAd? bannerAd;

  FileImage? _backgroundImage;

  /// This is to prevent the entire page being rebuilt on iOS when the keyboard pops up
  late bool _fieldInitComplete;

  ///Set the Future of the page when the framework calls build(), the content is not reloaded every time.
  Future<List<OTHole>?> _loadContent(int page) async {
    if (!checkGroup(kCompatibleUserGroup)) {
      throw NotLoginError("Logged in as a visitor.");
    }

    // Initialize the user token from shared preferences.
    // If no token, NotLoginError will be thrown.
    if (!context.read<FDUHoleProvider>().isUserInitialized) {
      await OpenTreeHoleRepository.getInstance().initializeRepo();
      context.read<FDUHoleProvider>().currentDivision =
          OpenTreeHoleRepository.getInstance().getDivisions().firstOrNull;
      settingsPageKey.currentState?.setState(() {});
    }

    switch (_postsType) {
      case PostsType.FAVORED_DISCUSSION:
        if (page > 1) return Future.value([]);
        return await OpenTreeHoleRepository.getInstance().getFavoriteHoles();
      case PostsType.FILTER_BY_TAG:
      case PostsType.NORMAL_POSTS:
        List<OTHole>? loadedPost = await adaptLayer
            .generateReceiver(listViewController, (lastElement) {
          DateTime time;
          if (lastElement != null) {
            time = DateTime.parse(lastElement.time_updated!);
          } else {
            time = DateTime.now();
          }
          return OpenTreeHoleRepository.getInstance()
              .loadHoles(time, getDivisionId(context), tag: _tagFilter);
        }).call(page);

        // If not more posts, notify ListView that we reached the end.
        if (loadedPost?.isEmpty ?? false) return [];

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
  }

  Future<void> refreshList() async {
    try {
      if (_postsType == PostsType.FAVORED_DISCUSSION) {
        await OpenTreeHoleRepository.getInstance()
            .getFavoriteHoleId(forceUpdate: true);
      } else if (context.read<FDUHoleProvider>().isUserInitialized) {
        OpenTreeHoleRepository.getInstance()
            .loadDivisions(useCache: false)
            .then((value) => setState(() {}))
            .catchError((error) {});
      }
    } finally {
      await listViewController.notifyUpdate(
          useInitialData: true, queueDataClear: true);
    }
  }

  Widget _autoSilenceNotice() {
    final DateTime? silenceDate = OpenTreeHoleRepository.getInstance()
        .getSilenceDateForDivision(getDivisionId(context))
        ?.toLocal();
    if (silenceDate == null || silenceDate.isBefore(DateTime.now())) {
      return const SizedBox();
    }
    return Card(
      child: ListTile(
        leading: Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: Theme.of(context).errorColor,
        ),
        title: Text(S.of(context).silence_notice,
            style: TextStyle(color: Theme.of(context).errorColor)),
        subtitle: Text(
          S.of(context).ban_post_until(
              "${silenceDate.year}-${silenceDate.month}-${silenceDate.day} ${silenceDate.hour}:${silenceDate.minute}"),
        ),
        onTap: () {
          Noticing.showNotice(context, S.of(context).silence_detail,
              title: S.of(context).silence_notice, useSnackBar: false);
        },
      ),
    );
  }

  Widget _autoPinnedPosts() {
    print("Build pinned!");
    return Column(
      children: OpenTreeHoleRepository.getInstance()
          .getPinned(getDivisionId(context))
          .map((e) => _buildListItem(context, null, null, e, isPinned: true))
          .toList(),
    );
  }

  Widget _autoTabWidget() {
    return Selector<FDUHoleProvider, bool>(
        selector: (_, model) => model.isUserInitialized,
        builder: (context, value, _) {
          if (value) {
            return Row(
              children: [
                Padding(
                  padding: Theme.of(context).cardTheme.margin ??
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: PlatformIconButton(
                    icon: Icon(PlatformIcons(context).search),
                    onPressed: () {
                      smartNavigatorPush(context, '/bbs/search',
                          forcePushOnMainNavigator: true);
                    },
                  ),
                ),
                const OTTitle()
              ],
            );
          } else {
            return Container();
          }
        });
  }

  @override
  void initState() {
    super.initState();
    _fieldInitComplete = false;
    _postSubscription.bindOnlyInvalid(
        Constant.eventBus.on<AddNewPostEvent>().listen((_) async {
          final bool success =
              await OTEditor.createNewPost(context, getDivisionId(context));
          if (success) refreshList();
        }),
        hashCode);
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshBBSEvent>().listen((event) {
          indicatorKey.currentState?.show();
        }),
        hashCode);
    _divisionChangedSubscription.bindOnlyInvalid(
        Constant.eventBus.on<DivisionChangedEvent>().listen((event) {
          indicatorKey.currentState?.show();
        }),
        hashCode);

    bannerAd = AdManager.loadBannerAd(1); // 1 for bbs page
  }

  @override
  void didChangeDependencies() {
    if (!_fieldInitComplete) {
      if (widget.arguments?.containsKey('tagFilter') ?? false) {
        _tagFilter = widget.arguments!['tagFilter'];
      }
      if (_tagFilter != null) {
        _postsType = PostsType.FILTER_BY_TAG;
      } else if (widget.arguments?.containsKey('showFavoredDiscussion') ??
          false) {
        _postsType = PostsType.FAVORED_DISCUSSION;
      }
      _fieldInitComplete = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    //screenListener.dispose();
    super.dispose();
    _postSubscription.cancel();
    _refreshSubscription.cancel();
    _divisionChangedSubscription.cancel();
  }

  @override
  Widget buildPage(BuildContext context) {
    switch (_postsType) {
      case PostsType.FAVORED_DISCUSSION:
        return PlatformScaffold(
          iosContentPadding: false,
          iosContentBottomPadding: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PlatformAppBarX(
            title: Text(S.of(context).favorites),
          ),
          body: Builder(
            // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
            builder: (context) => _buildPageBody(context),
          ),
        );
      case PostsType.FILTER_BY_TAG:
        return PlatformScaffold(
          iosContentPadding: false,
          iosContentBottomPadding: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PlatformAppBarX(
            title: Text(S.of(context).filtering_by_tag(_tagFilter ?? "?")),
          ),
          body: Builder(
            // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
            builder: (context) => _buildPageBody(context),
          ),
        );
      case PostsType.NORMAL_POSTS:
        return _buildPageBody(context);
    }
  }

  Widget _buildPageBody(BuildContext context) {
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;
    return Material(
      child: Container(
        decoration: _backgroundImage == null
            ? null
            : BoxDecoration(
                image: DecorationImage(
                    image: _backgroundImage!, fit: BoxFit.cover)),
        child: RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          key: indicatorKey,
          color: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await refreshList();
            try {
              await listViewController.scrollToIndex(0);
              // It is not important if [listViewController] is not attached to a ListView.
            } catch (_) {}
          },
          child: Column(
            children: [
              Expanded(
                child: PagedListView<OTHole>(
                    noneItem: OTHole.DUMMY_POST,
                    pagedController: listViewController,
                    withScrollbar: true,
                    scrollController: PrimaryScrollController.of(context),
                    startPage: 1,
                    builder: _buildListItem,
                    headBuilder: (context) => Column(
                          children: [
                            AutoBannerAdWidget(bannerAd: bannerAd),
                            if (_postsType == PostsType.NORMAL_POSTS) ...[
                              _autoTabWidget(),
                              _autoSilenceNotice(),
                              _autoPinnedPosts(),
                            ],
                          ],
                        ),
                    loadingBuilder: (BuildContext context) => Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                              child: PlatformCircularProgressIndicator()),
                        ),
                    endBuilder: (context) => Center(
                            child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(S.of(context).end_reached),
                        )),
                    emptyBuilder: (_) {
                      if (_postsType == PostsType.FAVORED_DISCUSSION) {
                        return _buildEmptyFavoritesPage();
                      } else {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          child: Center(child: Text(S.of(context).no_data)),
                        );
                      }
                    },
                    fatalErrorBuilder: (_, e) {
                      if (e is NotLoginError) {
                        return OTWelcomeWidget(loginCallback: () async {
                          await smartNavigatorPush(context, "/bbs/login",
                              arguments: {
                                "info": StateProvider.personInfo.value!
                              });
                          refreshList();
                        });
                      }
                      return ErrorPageWidget.buildWidget(context, e,
                          onTap: () => refreshSelf());
                    },
                    dataReceiver: _loadContent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavoritesPage() => Container(
        padding: const EdgeInsets.all(8),
        child: Center(child: Text(S.of(context).no_favorites)),
      );

  _launchUrlWithNotice(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      BrowserUtil.openUrl(link.url, context);
    } else {
      Noticing.showNotice(context, S.of(context).cannot_launch_url);
    }
  }

  Widget _buildListItem(BuildContext context, ListProvider<OTHole>? _, int? __,
      OTHole postElement,
      {bool isPinned = false}) {
    if (postElement.floors?.first_floor == null ||
        postElement.floors?.last_floor == null ||
        (foldBehavior == FoldBehavior.HIDE && postElement.is_folded) ||
        (!isPinned &&
            OpenTreeHoleRepository.getInstance()
                .getPinned(getDivisionId(context))
                .contains(postElement))) return const SizedBox();

    Linkify postContentWidget = Linkify(
      text: renderText(postElement.floors!.first_floor!.filteredContent!,
          S.of(context).image_tag, S.of(context).formula),
      style: const TextStyle(fontSize: 16),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
      onOpen: _launchUrlWithNotice,
    );
    final TextStyle infoStyle =
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);

    return Card(
      color: _backgroundImage != null
          ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
          : null,
      child: Column(
        children: [
          ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 10, 0),
              dense: false,
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 4,
                        children: [
                          generateTagWidgets(context, postElement,
                              (String? tagName) {
                            smartNavigatorPush(context, '/bbs/discussions',
                                arguments: {"tagFilter": tagName},
                                forcePushOnMainNavigator: true);
                          },
                              SettingsProvider.getInstance()
                                  .useAccessibilityColoring),
                          Row(
                            //mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isPinned)
                                OTLeadingTag(
                                  color: Theme.of(context).colorScheme.primary,
                                  text: S.of(context).pinned,
                                ),
                              if (postElement.floors?.first_floor?.special_tag
                                      ?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(width: 4),
                                OTLeadingTag(
                                  color: Colors.red,
                                  text: postElement
                                      .floors!.first_floor!.special_tag!,
                                ),
                              ],
                              if (postElement.hidden == true) ...[
                                const SizedBox(width: 4),
                                OTLeadingTag(
                                  color: Theme.of(context).colorScheme.primary,
                                  text: S.of(context).hole_hidden,
                                ),
                              ]
                            ],
                          ),
                        ]),
                    const SizedBox(
                      height: 4,
                    ),
                    (postElement.is_folded && foldBehavior == FoldBehavior.FOLD)
                        ? ExpansionTileX(
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            expandedAlignment: Alignment.topLeft,
                            childrenPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              S.of(context).folded,
                              style: infoStyle,
                            ),
                            children: [
                                postContentWidget,
                              ])
                        : postContentWidget,
                  ]),
              subtitle:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("#${postElement.hole_id}", style: infoStyle),
                      Text(
                          HumanDuration.tryFormat(
                              context,
                              DateTime.parse(postElement.time_created!)
                                  .toLocal()),
                          style: infoStyle),
                      Row(children: [
                        Text("${postElement.reply} ", style: infoStyle),
                        Icon(
                            PlatformX.isMaterial(context)
                                ? Icons.sms_outlined
                                : CupertinoIcons.ellipses_bubble,
                            size: infoStyle.fontSize,
                            color: infoStyle.color),
                      ]),
                    ]),
              ]),
              onTap: () => smartNavigatorPush(context, "/bbs/postDetail",
                  arguments: {"post": postElement})),
          if (!(postElement.is_folded && foldBehavior == FoldBehavior.FOLD) &&
              postElement.floors?.last_floor !=
                  postElement.floors?.first_floor) ...[
            const Divider(height: 4),
            _buildCommentView(postElement)
          ]
        ],
      ),
    );
  }

  Widget _buildCommentView(OTHole postElement, {bool useLeading = true}) {
    final String lastReplyContent = renderText(
        postElement.floors!.last_floor!.filteredContent!,
        S.of(context).image_tag,
        S.of(context).formula);
    return ListTile(
        dense: true,
        minLeadingWidth: 16,
        leading: useLeading
            ? Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  PlatformX.isMaterial(context)
                      ? Icons.sms_outlined
                      : CupertinoIcons.quote_bubble,
                  color: Theme.of(context).hintColor,
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).latest_reply(
                          postElement.floors!.last_floor!.anonyname ?? "?",
                          HumanDuration.tryFormat(
                              context,
                              DateTime.parse(postElement
                                      .floors!.last_floor!.time_created!)
                                  .toLocal())),
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    Icon(CupertinoIcons.search,
                        size: 14,
                        color: Theme.of(context).hintColor.withOpacity(0.2)),
                  ]),
            ),
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Linkify(
                    text: lastReplyContent,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    onOpen: _launchUrlWithNotice)),
          ],
        ),
        onTap: () async {
          ProgressFuture dialog = showProgressDialog(
              loadingText: S.of(context).loading, context: context);
          try {
            smartNavigatorPush(context, "/bbs/postDetail", arguments: {
              "post": await prefetchAllFloors(postElement),
              "scroll_to_end": true
            });
          } catch (error, st) {
            Noticing.showModalError(context, error, trace: st);
          } finally {
            dialog.dismiss(showAnim: false);
          }
        });
  }
}

/// This class is a workaround between Open Tree Hole's time-based content retrieval style
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
        // If this is not the first page, and we have loaded far more than [pageIndex],
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
