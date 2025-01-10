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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/division.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/forum/hole_editor.dart';
import 'package:dan_xi/page/forum/quiz.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/forum/auto_banner.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:dan_xi/widget/forum/login_widgets.dart';
import 'package:dan_xi/widget/forum/render/render_impl.dart';
import 'package:dan_xi/widget/forum/tag_selector/selector.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';

import '../util/watermark.dart';
import '../widget/forum/tag_selector/tag.dart';

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

/// Should be called when user logged in Danta account;
/// it refreshes every page that cares about login status.
/// (except the setting page, since it is refreshed when initializing token.)
///
/// FIXME: this is an ugly implementation that requires manual calling every time.
void onLogin() {
  forumPageKey.currentState?.refreshList();
  dankePageKey.currentState?.setState(() {});
}

/// Should be called when user logged out Danta account;
/// it refreshes every page that cares about login status.
/// (except setting page, since it is refreshed when initializing token.)
///
/// FIXME: this is an ugly implementation that requires manual calling every time.
void onLogout() {
  forumPageKey.currentState?.setState(() {});
  dankePageKey.currentState?.setState(() {});
}

final RegExp latexRegExp = RegExp(r"<(tex|texLine)>.*?</(tex|texLine)>",
    multiLine: true, dotAll: true);
final RegExp mentionRegExp =
    RegExp(r"<(floor|hole)Mention>(.*?)</(floor|hole)Mention>");

/// Render the text from a clip of [content].
/// Also supports adding image tag to markdown posts
String renderText(String content, String imagePlaceholder,
    String formulaPlaceholder, String stickerPlaceholder,
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

  String result = soup.getText().trim();

  if (images.isNotEmpty) {
    if (images[0].toString().contains("danxi_") ||
        images[0].toString().contains("dx_")) {
      return result + stickerPlaceholder;
    } else {
      return result + imagePlaceholder;
    }
  }

  // If we have reduce the text to nothing, we would rather not remove mention texts.
  if (result.isEmpty && removeMentions) {
    return renderText(originalContent, imagePlaceholder, formulaPlaceholder,
        stickerPlaceholder,
        removeMentions: false);
  } else {
    return result;
  }
}

const String KEY_NO_TAG = "默认";

/// The tab bar for switching divisions.
class OTTitle extends StatelessWidget {
  const OTTitle({super.key});

  @override
  Widget build(BuildContext context) {
    List<OTDivision> divisions =
        context.select<ForumProvider, List<OTDivision>>(
            (value) => value.divisionCache);
    OTDivision? division = context
        .select<ForumProvider, OTDivision?>((value) => value.currentDivision);
    int currentIndex = 0;
    if (division != null) {
      currentIndex = divisions.indexOf(division);
    }
    return Expanded(
      child: TagContainer(
          fillRandomColor: false,
          fixedColor: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          enabled: true,
          wrapped: false,
          singleChoice: true,
          defaultChoice: currentIndex,
          onChoice: (Tag tag, list) {
            division =
                divisions.firstWhere((element) => element.name == tag.tagTitle);
            context.read<ForumProvider>().currentDivisionId =
                division?.division_id;
            ChangeDivisionEvent(division!).fire();
          },
          tagList: divisions
              .map((e) => Tag(e.name, null, checkedIcon: null))
              .toList()),
    );
  }
}

class ForumSubpage extends PlatformSubpage<ForumSubpage> {
  final Map<String, dynamic>? arguments;

  @override
  ForumSubpageState createState() => ForumSubpageState();

  const ForumSubpage({super.key, this.arguments});

  @override
  Create<List<AppBarButtonItem>> get leading => (cxt) => [
        AppBarButtonItem(
          S.of(cxt).messages,
          Icon(PlatformX.isMaterial(cxt)
              ? Icons.notifications
              : CupertinoIcons.bell),
          () {
            if (cxt.read<ForumProvider>().isUserInitialized) {
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
          context.read<SettingsProvider>().forumSortOrder = newSortOrder;
          RefreshListEvent().fire();
        }

        return [
          if (cxt.select<ForumProvider, bool>(
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
              S.of(cxt).subscriptions,
              Icon(PlatformX.isMaterial(cxt)
                  ? Icons.visibility
                  : CupertinoIcons.eye), () {
            if (cxt.read<ForumProvider>().isUserInitialized) {
              smartNavigatorPush(cxt, '/bbs/discussions',
                  arguments: {'showSubscribedDiscussion': true},
                  forcePushOnMainNavigator: true);
            }
          }),
          AppBarButtonItem(
              S.of(cxt).favorites,
              Icon(PlatformX.isMaterial(cxt)
                  ? Icons.star_outline
                  : CupertinoIcons.star), () {
            if (cxt.read<ForumProvider>().isUserInitialized) {
              smartNavigatorPush(cxt, '/bbs/discussions',
                  arguments: {'showFavoredDiscussion': true},
                  forcePushOnMainNavigator: true);
            }
          }),
          AppBarButtonItem(
              S.of(cxt).new_post, Icon(PlatformIcons(cxt).addCircled), () {
            if (cxt.read<ForumProvider>().isUserInitialized) {
              CreateNewPostEvent().fire();
            }
          }),
        ];
      };

  @override
  void onDoubleTapOnTab() => RefreshListEvent().fire();

  @override
  void onViewStateChanged(BuildContext parentContext, SubpageViewState state) {
    super.onViewStateChanged(parentContext, state);
    switch (state) {
      case SubpageViewState.VISIBLE:
        // Subpage is always mounted even if it is invisible.
        // Monitoring within State lifecycle methods like `initState` and `dispose` isn't effective.
        // So we have to count on the onViewStateChanged hook to add/remove watermark.
        Watermark.addWatermark(parentContext);
        break;
      case SubpageViewState.INVISIBLE:
        Watermark.remove();
        break;
    }
  }
}

class CreateNewPostEvent {}

class RefreshListEvent {}

class ChangeDivisionEvent {
  final OTDivision newDivision;

  ChangeDivisionEvent(this.newDivision);
}

enum PostsType {
  FAVORED_DISCUSSION,
  SUBSCRIBED_DISCUSSION,
  FILTER_BY_TAG,
  FILTER_BY_ME,
  NORMAL_POSTS,
  EXTERNAL_VIEW
}

/// A list page showing bbs posts.
///
/// Arguments:
/// [bool] showFavoredDiscussion: if [showFavoredDiscussion] is not null,
/// it means this page is showing user's favored posts (whether it is false or true).
/// [bool] showSubscribedDiscussion: if [showSubscribedDiscussion] is not null,
/// it means this page is showing user's subscribed posts (whether it is false or true).
/// [bool] showFilterByMe: if [showFilterByMe] is not null, it means this page is showing
/// the posts which is created by the user (whether it is false or true).
/// [String] tagFilter: if [tagFilter] is not null, it means this page is showing
/// the posts which is tagged with [tagFilter].
///
class ForumSubpageState extends PlatformSubpageState<ForumSubpage> {
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
  final GlobalKey<AutoBannerState> bannerKey = GlobalKey<AutoBannerState>();

  String? _tagFilter;
  PostsType _postsType = PostsType.NORMAL_POSTS;

  ListDelegate? _delegate;

  final PagedListViewController<OTHole> listViewController =
      PagedListViewController();

  final TimeBasedLoadAdaptLayer<OTHole> adaptLayer =
      TimeBasedLoadAdaptLayer(Constant.POST_COUNT_PER_PAGE, 1);

  /// Fields related to the display states.
  static int getDivisionId(BuildContext context) =>
      context.read<ForumProvider>().currentDivision?.division_id ?? 1;

  FoldBehavior? get foldBehavior => foldBehaviorFromInternalString(
      context.read<ForumProvider>().userInfo?.config?.show_folded);

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
    if (!context.read<ForumProvider>().isUserInitialized) {
      await ForumRepository.getInstance().initializeRepo();
      context.read<ForumProvider>().currentDivisionId =
          ForumRepository.getInstance().getDivisions().firstOrNull?.division_id;
    }

    bool answered =
        await ForumRepository.getInstance().hasAnsweredQuestions() ?? true;
    if (!answered) {
      throw QuizUnansweredError(
          "User hasn't finished the quiz of forum rules yet. ");
    }

    switch (_postsType) {
      case PostsType.FAVORED_DISCUSSION:
        // Favored discussion has only one page.
        if (page > 1) return [];
        return await ForumRepository.getInstance().getFavoriteHoles();
      case PostsType.SUBSCRIBED_DISCUSSION:
        if (page > 1) return [];
        return await ForumRepository.getInstance().getSubscribedHoles();
      case PostsType.FILTER_BY_ME:
        List<OTHole>? loadedPost = await adaptLayer
            .generateReceiver(listViewController, (lastElement) {
          DateTime time = DateTime.now();
          if (lastElement != null) {
            time = DateTime.parse(lastElement.time_updated!);
          }
          return ForumRepository.getInstance()
              .loadUserHoles(time, sortOrder: SortOrder.LAST_CREATED);
        }).call(page);
        // If not more posts, notify ListView that we reached the end.
        if (loadedPost?.isEmpty ?? false) return [];

        // About this line, see [PagedListView].
        return loadedPost == null || loadedPost.isEmpty
            ? [OTHole.DUMMY_POST]
            : loadedPost;
      case PostsType.FILTER_BY_TAG:
      case PostsType.NORMAL_POSTS:
        List<OTHole>? loadedPost = await adaptLayer
            .generateReceiver(listViewController, (lastElement) {
          DateTime time = DateTime.now();
          if (lastElement != null) {
            time = DateTime.parse(lastElement.time_updated!);
          }
          return ForumRepository.getInstance().loadHoles(
              time, getDivisionId(context),
              tag: _tagFilter,
              sortOrder: context.read<SettingsProvider>().forumSortOrder);
        }).call(page);

        // If not more posts, notify ListView that we reached the end.
        if (loadedPost?.isEmpty ?? false) return [];

        // Remove posts of which the first floor is empty (aka hidden)
        loadedPost?.removeWhere(
            (element) => element.floors?.first_floor?.content?.isEmpty ?? true);

        // Filter blocked posts
        List<OTTag> hiddenTags =
            SettingsProvider.getInstance().hiddenTags ?? [];
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
        await ForumRepository.getInstance().getFavoriteHoleId();
      } else if (_postsType == PostsType.SUBSCRIBED_DISCUSSION) {
        await ForumRepository.getInstance().getSubscribedHoleId();
      } else if (context.read<ForumProvider>().isUserInitialized) {
        await ForumRepository.getInstance().loadDivisions(useCache: false);
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
    final DateTime? silenceDate = ForumRepository.getInstance()
        .getSilenceDateForDivision(getDivisionId(context))
        ?.toLocal();
    if (silenceDate == null || silenceDate.isBefore(DateTime.now())) {
      return const SizedBox();
    }
    return Card(
      child: ListTile(
        leading: Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(S.of(context).silence_notice,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        subtitle: Text(
          S.of(context).ban_post_until(
              DateFormat('yyyy-MM-dd H:mm').format(silenceDate)),
        ),
        onTap: () => Noticing.showNotice(context, S.of(context).silence_detail,
            title: S.of(context).silence_notice, useSnackBar: false),
      ),
    );
  }

  Widget _autoPinnedPosts() => Column(
        children: ForumRepository.getInstance()
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
              // _delegate = CourseListDelegate();
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
  }

  @override
  void didChangeDependencies() {
    if (!_fieldInitComplete) {
      if (widget.arguments?.containsKey('tagFilter') ?? false) {
        _tagFilter = widget.arguments!['tagFilter'];
      }
      if (_tagFilter != null) {
        _postsType = PostsType.FILTER_BY_TAG;
      } else if (widget.arguments?.containsKey('showSubscribedDiscussion') ??
          false) {
        _postsType = PostsType.SUBSCRIBED_DISCUSSION;
      } else if (widget.arguments?.containsKey('showFavoredDiscussion') ??
          false) {
        _postsType = PostsType.FAVORED_DISCUSSION;
      } else if (widget.arguments?.containsKey('showFilterByMe') ?? false) {
        _postsType = PostsType.FILTER_BY_ME;
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

  @override
  Widget buildPage(BuildContext context) {
    switch (_postsType) {
      case PostsType.FAVORED_DISCUSSION:
      case PostsType.SUBSCRIBED_DISCUSSION:
        return PlatformScaffold(
          iosContentPadding: false,
          iosContentBottomPadding: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PlatformAppBarX(
            title: Text(switch (_postsType) {
              PostsType.FAVORED_DISCUSSION => S.of(context).favorites,
              PostsType.SUBSCRIBED_DISCUSSION => S.of(context).subscriptions,
              _ => throw Exception("Unreachable"),
            }),
          ),
          body: Builder(
            // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
            builder: (context) => _buildPageBody(context, false),
          ),
        );
      case PostsType.FILTER_BY_ME:
      case PostsType.FILTER_BY_TAG:
        return PlatformScaffold(
          iosContentPadding: false,
          iosContentBottomPadding: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PlatformAppBarX(
            title: Text(switch (_postsType) {
              PostsType.FILTER_BY_ME => S.of(context).list_my_posts,
              PostsType.FILTER_BY_TAG =>
                S.of(context).filtering_by_tag(_tagFilter ?? "?"),
              _ => throw Exception("Unreachable"),
            }),
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
          // Update the banner list
          await AnnouncementRepository.getInstance().loadAnnouncements();
          bannerKey.currentState?.updateBannerList();
          // ... and scroll it to the top.
          if (!context.mounted) return;
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
              AutoBanner(
                  key: bannerKey,
                  refreshDuration: const Duration(seconds: 10),
                  onExpand: (expanded) async {
                    if (!expanded) {
                      try {
                        await PrimaryScrollController.of(context).animateTo(0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease);
                        // It is not important if [listViewController] is not attached to a ListView.
                      } catch (_) {}
                    }
                  }),
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
              child: Text(switch (_postsType) {
                PostsType.FAVORED_DISCUSSION => S.of(context).no_favorites,
                PostsType.SUBSCRIBED_DISCUSSION =>
                  S.of(context).no_subscriptions,
                _ => S.of(context).no_data
              }),
            )),
        fatalErrorBuilder: (_, error) {
          if (error is NotLoginError) {
            return OTWelcomeWidget(loginCallback: () async {
              await smartNavigatorPush(context, "/bbs/login",
                  arguments: {"info": StateProvider.personInfo.value!});
              onLogin();
            });
          } else if (error is QuizUnansweredError) {
            return OTQuizWidget(successCallback: () async {
              // Update user data
              await ForumRepository.getInstance()
                  .getUserProfile(forceUpdate: true);
              refreshList();
            });
          }
          return ErrorPageWidget.buildWidget(context, error,
              onTap: refreshSelf);
        },
        dataReceiver: _loadContent,
        onDismissItem: switch (_postsType) {
          PostsType.FAVORED_DISCUSSION => (context, index, item) async {
              await ForumRepository.getInstance()
                  .setFavorite(SetStatusMode.DELETE, item.hole_id)
                  .onError((error, stackTrace) {
                Noticing.showNotice(context, error.toString(),
                    title: S.of(context).operation_failed, useSnackBar: false);
                return null;
              });
            },
          PostsType.SUBSCRIBED_DISCUSSION => (context, index, item) async {
              await ForumRepository.getInstance()
                  .setSubscription(SetStatusMode.DELETE, item.hole_id)
                  .onError((error, stackTrace) {
                Noticing.showNotice(context, error.toString(),
                    title: S.of(context).operation_failed, useSnackBar: false);
                return null;
              });
            },
          _ => null
        },
        onConfirmDismissItem: switch (_postsType) {
          PostsType.FAVORED_DISCUSSION => (context, index, item) {
              return Noticing.showConfirmationDialog(
                  context, S.of(context).remove_favorite_hole_confirmation,
                  isConfirmDestructive: true);
            },
          PostsType.SUBSCRIBED_DISCUSSION => (context, index, item) {
              return Noticing.showConfirmationDialog(
                  context, S.of(context).remove_subscribed_hole_confirmation,
                  isConfirmDestructive: true);
            },
          _ => null
        },
      );

  Widget _buildListItem(BuildContext context, ListProvider<OTHole>? _, int? __,
      OTHole postElement,
      {bool isPinned = false}) {
    // Avoid excluding pinned posts from favorite and subscription list
    bool isSpecialView = _postsType == PostsType.FAVORED_DISCUSSION ||
        _postsType == PostsType.SUBSCRIBED_DISCUSSION;
    if (postElement.floors?.first_floor == null ||
        postElement.floors?.last_floor == null ||
        (foldBehavior == FoldBehavior.HIDE && postElement.is_folded) ||
        (!isPinned &&
            !isSpecialView &&
            ForumRepository.getInstance()
                .getPinned(getDivisionId(context))
                .contains(postElement))) {
      return const SizedBox();
    }
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

Widget buildForumTopBar() => Selector<ForumProvider, bool>(
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
/// When [ForumSubpageState._postsType] is set to [PostsType.EXTERNAL_VIEW],
/// the subpage will use the delegate as its content, rather than [PagedListView]
/// built in the [ForumSubpageState.build] method.
///
/// Also see:
/// - [ForumSubpageState]
abstract class ListDelegate {
  /// Same as a normal build() method. Return a widget to be shown in the page.
  Widget build(BuildContext context);

  /// Call when a refresh is triggered by user or by code.
  /// You should do some time-consuming refresh work here.
  Future<void> triggerRefresh();
}
