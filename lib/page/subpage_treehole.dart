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
import 'package:dan_xi/page/curriculum/course_list_widget.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/opentreehole/auto_banner.dart';
import 'package:dan_xi/widget/opentreehole/login_widgets.dart';
import 'package:dan_xi/widget/opentreehole/render/render_impl.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/selector.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

import '../util/watermark.dart';
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
  // Deal with Mentions
  if (removeMentions) content = content.replaceAll(mentionRegExp, "");
  // Deal with images
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

  OTHole holeClone = OTHole.fromJson(jsonDecode(jsonEncode(hole)));
  return holeClone..floors?.prefetch = floors;
}

const String KEY_NO_TAG = "默认";

/// The tab bar for switching divisions.
class OTTitle extends StatelessWidget {
  const OTTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<OTDivision> divisions =
        OpenTreeHoleRepository.getInstance().getDivisions();
    OTDivision? division = context
        .select<FDUHoleProvider, OTDivision?>((value) => value.currentDivision);
    int currentIndex = 0;
    if (division != null) {
      currentIndex = divisions.indexOf(division);
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
            ChangeDivisionEvent(division!).fire();
          },
          tagList: divisions
              .map((e) => Tag(e.name, null, checkedIcon: null))
              .toList()),
    );
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
  Create<List<AppBarButtonItem>> get trailing => (cxt) {
        void onChangeSortOrder(BuildContext context, SortOrder newSortOrder) {
          context.read<SettingsProvider>().fduholeSortOrder = newSortOrder;
          RefreshListEvent().fire();
        }

        return [
          if (cxt.select<FDUHoleProvider, bool>(
              (value) => value.userInfo?.is_admin ?? false)) ...[
            AppBarButtonItem(
                S.of(cxt).reports,
                Icon(PlatformX.isMaterial(cxt)
                    ? Icons.report_outlined
                    : CupertinoIcons.exclamationmark_octagon), () {
              smartNavigatorPush(cxt, "/bbs/reports");
            })
          ],
          AppBarButtonItem(
              S.of(cxt).sort_order,
              PlatformPopupMenuX(
                options: [
                  PopupMenuOption(
                      label: S.of(cxt).last_replied,
                      onTap: (_) =>
                          onChangeSortOrder(cxt, SortOrder.LAST_REPLIED)),
                  PopupMenuOption(
                      label: S.of(cxt).last_created,
                      onTap: (_) =>
                          onChangeSortOrder(cxt, SortOrder.LAST_CREATED))
                ],
                cupertino: (context, platform) => CupertinoPopupMenuData(
                    cancelButtonData: CupertinoPopupMenuCancelButtonData(
                        child: Text(S.of(context).cancel))),
                icon: Icon(PlatformX.isMaterial(cxt)
                    ? Icons.filter_list
                    : CupertinoIcons.sort_down_circle),
              ),
              null,
              useCustomWidget: true),
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
              CreateNewPostEvent().fire();
            }
          }),
        ];
      };

  @override
  void onDoubleTapOnTab() => RefreshListEvent().fire();
}

class CreateNewPostEvent {}

class RefreshListEvent {}

class ChangeDivisionEvent {
  final OTDivision newDivision;

  ChangeDivisionEvent(this.newDivision);
}

enum PostsType {
  FAVORED_DISCUSSION,
  FILTER_BY_TAG,
  NORMAL_POSTS,
  EXTERNAL_VIEW
}

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
  final StateStreamListener<CreateNewPostEvent> _postSubscription =
      StateStreamListener();
  final StateStreamListener<RefreshListEvent> _refreshSubscription =
      StateStreamListener();
  final StateStreamListener<ChangeDivisionEvent> _divisionChangedSubscription =
      StateStreamListener();
  final GlobalKey<RefreshIndicatorState> indicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final GlobalKey bannerKey = GlobalKey();

  String? _tagFilter;
  PostsType _postsType = PostsType.NORMAL_POSTS;

  ListDelegate? _delegate;

  final PagedListViewController<OTHole> listViewController =
      PagedListViewController();

  final TimeBasedLoadAdaptLayer<OTHole> adaptLayer =
      TimeBasedLoadAdaptLayer(Constant.POST_COUNT_PER_PAGE, 1);

  /// Fields related to the display states.
  static int getDivisionId(BuildContext context) =>
      context.read<FDUHoleProvider>().currentDivision?.division_id ?? 1;

  FoldBehavior? get foldBehavior => foldBehaviorFromInternalString(
      OpenTreeHoleRepository.getInstance().userInfo?.config?.show_folded);

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
        // Favored discussion has only one page.
        if (page > 1) return [];
        return await OpenTreeHoleRepository.getInstance().getFavoriteHoles();
      case PostsType.FILTER_BY_TAG:
      case PostsType.NORMAL_POSTS:
        List<OTHole>? loadedPost = await adaptLayer
            .generateReceiver(listViewController, (lastElement) {
          DateTime time = DateTime.now();
          if (lastElement != null) {
            time = DateTime.parse(lastElement.time_updated!);
          }
          return OpenTreeHoleRepository.getInstance().loadHoles(
              time, getDivisionId(context),
              tag: _tagFilter,
              sortOrder: context.read<SettingsProvider>().fduholeSortOrder);
        }).call(page);

        // If not more posts, notify ListView that we reached the end.
        if (loadedPost?.isEmpty ?? false) return [];

        // Filter blocked posts
        List<OTTag> hiddenTags = OpenTreeHoleRepository.getInstance().isAdmin
            ? []
            : SettingsProvider.getInstance().hiddenTags ?? [];
        loadedPost?.removeWhere((element) => element.tags!.any((thisTag) =>
            hiddenTags.any((blockTag) => thisTag.name == blockTag.name)));
        // Filter hidden posts
        List<int> hiddenPosts = SettingsProvider.getInstance().hiddenHoles;
        loadedPost?.removeWhere((element) =>
            hiddenPosts.any((blockPost) => element.hole_id == blockPost));

        // About this line, see [PagedListView].
        return loadedPost == null || loadedPost.isEmpty
            ? [OTHole.DUMMY_POST]
            : loadedPost;
      case PostsType.EXTERNAL_VIEW:
        // If we are showing a widget predefined
        return [];
    }
  }

  /// Refresh the whole list.
  Future<void> refreshList() async {
    try {
      if (_postsType == PostsType.FAVORED_DISCUSSION) {
        await OpenTreeHoleRepository.getInstance().getFavoriteHoleId();
      } else if (context.read<FDUHoleProvider>().isUserInitialized) {
        await OpenTreeHoleRepository.getInstance()
            .loadDivisions(useCache: false);
        await refreshSelf();
      }
    } finally {
      if (_postsType == PostsType.EXTERNAL_VIEW) {
        await _delegate?.triggerRefresh();
      } else {
        await listViewController.notifyUpdate(
            useInitialData: true, queueDataClear: true);
      }
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
        onTap: () => Noticing.showNotice(context, S.of(context).silence_detail,
            title: S.of(context).silence_notice, useSnackBar: false),
      ),
    );
  }

  Widget _autoPinnedPosts() => Column(
        children: OpenTreeHoleRepository.getInstance()
            .getPinned(getDivisionId(context))
            .map((e) => _buildListItem(context, null, null, e, isPinned: true))
            .toList(),
      );

  @override
  void initState() {
    super.initState();
    _fieldInitComplete = false;
    _postSubscription.bindOnlyInvalid(
        Constant.eventBus.on<CreateNewPostEvent>().listen((_) async {
          final bool success =
              await OTEditor.createNewPost(context, getDivisionId(context),
                  interceptor: (_, PostEditorText? text) async {
            if (text?.tags.isEmpty ?? true) {
              return await Noticing.showConfirmationDialog(
                      context, S.of(context).post_has_no_tags,
                      title: S.of(context).post_has_no_tags_title,
                      confirmText: S.of(context).continue_sending,
                      isConfirmDestructive: true) ??
                  false;
            }
            return true;
          });
          if (success) refreshList();
        }),
        hashCode);
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshListEvent>().listen((event) {
          indicatorKey.currentState?.show();
        }),
        hashCode);

    // @w568w (2022-3-13):
    // Question: why not use [context.watch] to listen to change of division?
    //
    // Answer: We have to do some initial work before build (like the codes below),
    // and some conclusive work after build (like showing the indicator).
    // After some thought, I believe a subscription is still a better way, unless
    // we refactor all logic fundamentally.
    _divisionChangedSubscription.bindOnlyInvalid(
        Constant.eventBus.on<ChangeDivisionEvent>().listen((event) {
          if (event.newDivision.name ==
              Constant.SPECIAL_DIVISION_FOR_CURRICULUM) {
            setState(() {
              _delegate = CourseListDelegate();
              // _postsType = PostsType.EXTERNAL_VIEW;
            });
          } else {
            setState(() {
              _postsType = PostsType.NORMAL_POSTS;
            });
          }
          // Schedule a reload after setState() is done.
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            indicatorKey.currentState?.show();
          });
        }),
        hashCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Watermark.addWatermark(context, PlatformX.isDarkMode,
          rowCount: 4, columnCount: 8);
    });
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
    super.dispose();
    _postSubscription.cancel();
    _refreshSubscription.cancel();
    _divisionChangedSubscription.cancel();
  }

  void pageRefresh() {
    refreshSelf();
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
            builder: (context) => _buildPageBody(context, false),
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
            builder: (context) => _buildPageBody(context, false),
          ),
        );
      case PostsType.NORMAL_POSTS:
      case PostsType.EXTERNAL_VIEW:
        return _buildPageBody(context, PlatformX.isMaterial(context));
    }
  }

  Widget _buildPageBody(BuildContext context, bool buildTabBar) {
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;
    return Container(
      decoration: _backgroundImage == null
          ? null
          : BoxDecoration(
              image:
                  DecorationImage(image: _backgroundImage!, fit: BoxFit.cover)),
      child: RefreshIndicator(
        // Make the indicator listen to [ScrollNotification] from deeper located [PagedListView].
        notificationPredicate: (notification) => true,
        edgeOffset: MediaQuery.of(context).padding.top,
        key: indicatorKey,
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          // Refresh the list...
          await refreshList();
          // ... and scroll it to the top.
          if (!mounted) return;
          try {
            await PrimaryScrollController.of(context).animateTo(0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease);
            // It is not important if [listViewController] is not attached to a ListView.
          } catch (_) {}
        },
        child: Builder(builder: (context) {
          if (_postsType == PostsType.EXTERNAL_VIEW) {
            return _delegate!.build(context);
          } else {
            return _buildOTListView(context,
                padding: buildTabBar ? EdgeInsets.zero : null);
          }
        }),
      ),
    );
  }

  Widget _buildOTListView(BuildContext context, {EdgeInsets? padding}) =>
      PagedListView<OTHole>(
        noneItem: OTHole.DUMMY_POST,
        pagedController: listViewController,
        withScrollbar: true,
        scrollController: PrimaryScrollController.of(context),
        startPage: 1,
        // Avoiding extra padding from ListView. We have added it in [SliverSafeArea].
        padding: padding,
        builder: _buildListItem,
        headBuilder: (context) => Column(
          children: [
            if (_postsType == PostsType.NORMAL_POSTS) ...[
              buildForumTopBar(),
              _autoSilenceNotice(),
              const AutoBanner(refreshDuration: Duration(seconds: 10)),
              _autoPinnedPosts(),
            ]
          ],
        ),
        loadingBuilder: (BuildContext context) => Container(
            padding: const EdgeInsets.all(8),
            child: Center(child: PlatformCircularProgressIndicator())),
        endBuilder: (context) => Center(
            child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(S.of(context).end_reached),
        )),
        emptyBuilder: (context) => Container(
          padding: const EdgeInsets.all(8),
          child: Center(
              child: Text(_postsType == PostsType.FAVORED_DISCUSSION
                  ? S.of(context).no_favorites
                  : S.of(context).no_data)),
        ),
        fatalErrorBuilder: (_, error) {
          if (error is NotLoginError) {
            return OTWelcomeWidget(loginCallback: () async {
              await smartNavigatorPush(context, "/bbs/login",
                  arguments: {"info": StateProvider.personInfo.value!});
              refreshList();
            });
          }
          return ErrorPageWidget.buildWidget(context, error,
              onTap: refreshSelf);
        },
        dataReceiver: _loadContent,
        onDismissItem: _postsType == PostsType.FAVORED_DISCUSSION
            ? (context, index, item) async {
                await OpenTreeHoleRepository.getInstance()
                    .setFavorite(SetFavoriteMode.DELETE, item.hole_id)
                    .onError((error, stackTrace) {
                  Noticing.showNotice(context, error.toString(),
                      title: S.of(context).operation_failed,
                      useSnackBar: false);
                  return null;
                });
              }
            : null,
        onConfirmDismissItem: _postsType == PostsType.FAVORED_DISCUSSION
            ? (context, index, item) {
                return Noticing.showConfirmationDialog(
                    context, S.of(context).remove_favorite_hole_confirmation,
                    isConfirmDestructive: true);
              }
            : null,
      );

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
    return OTHoleWidget(
        postElement: postElement,
        translucent: _backgroundImage != null,
        isPinned: isPinned,
        isFolded: postElement.is_folded && foldBehavior == FoldBehavior.FOLD);
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

Widget buildForumTopBar() => Selector<FDUHoleProvider, bool>(
    selector: (_, model) => model.isUserInitialized,
    builder: (context, userInitialized, _) => userInitialized
        ? Row(
            children: [
              Padding(
                padding: PlatformX.isMaterial(context)
                    ? const EdgeInsets.all(8.0)
                    : EdgeInsets.zero,
                child: PlatformIconButton(
                  icon: Icon(PlatformIcons(context).search),
                  onPressed: () => smartNavigatorPush(context, '/bbs/search',
                      forcePushOnMainNavigator: true),
                ),
              ),
              const OTTitle()
            ],
          )
        : const SizedBox());

/// The delegate to show the tab switch as a floating header.
class ForumTabDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      buildForumTopBar();

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}

/// A delegate class to control the body widget shown in the tab page.
///
/// When [TreeHoleSubpageState._postsType] is set to [PostsType.EXTERNAL_VIEW],
/// the subpage will use the delegate as its content, rather than [PagedListView]
/// built in the [TreeHoleSubpageState.build] method.
///
/// Also see:
/// - [TreeHoleSubpageState]
abstract class ListDelegate {
  /// Same as a normal build() method. Return a widget to be shown in the page.
  Widget build(BuildContext context);

  /// Call when a refresh is triggered by user or by code.
  /// You should do some time-consuming refresh work here.
  Future<void> triggerRefresh();
}

class CourseListDelegate extends ListDelegate {
  final GlobalKey<CourseListWidgetState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) => CourseListWidget(key: _key);

  @override
  Future<void> triggerRefresh() async {
    await _key.currentState?.refresh();
  }
}
