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

import 'package:clipboard/clipboard.dart';
import 'package:collection/collection.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/division.dart';
import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/page/forum/admin_operation.dart';
import 'package:dan_xi/page/forum/hole_editor.dart';
import 'package:dan_xi/page/forum/image_viewer.dart';
import 'package:dan_xi/page/subpage_forum.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/util/watermark.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:dan_xi/widget/forum/ottag_selector.dart';
import 'package:dan_xi/widget/forum/post_render.dart';
import 'package:dan_xi/widget/forum/render/base_render.dart';
import 'package:dan_xi/widget/forum/render/render_impl.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:intl/intl.dart';
import 'package:linkify/linkify.dart';
import 'package:nil/nil.dart';
import 'package:provider/provider.dart';

/// This function preprocesses content downloaded from FDUHOLE so that
/// (1) HTML href is added to raw links
/// (2) Markdown Images are converted to HTML images.
String preprocessContentForDisplay(String content) {
  String result = "";

  linkify(content, options: const LinkifyOptions(humanize: false))
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
    } else {
      result += element.text;
    }
  });

  return result;
}

/// A list page showing the content of a bbs post.
///
/// Arguments:
/// [OTHole] or [Future<List<OTFloor>>] post: if [post] is [OTHole], show the page as a post.
/// Otherwise as a list of search result.
///
/// [String] searchKeyword: if set, the page will show the result of searching [searchKeyword].
///
/// [bool] punishmentHistory: if set AND true (i.e. [punishmentHistory == true]), the page will show the punishment history of the post.
///
/// [bool] scroll_to_end: if [scroll_to_end] is true, the page will scroll to the end of
/// the post as soon as the page shows. This implies that [post] should be a [OTHole].
/// If [scroll_to_end] is true, *all* the floors should be prefetched beforehand.
///
/// * See [hasPrefetchedAllData] below.
class BBSPostDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSPostDetail({super.key, this.arguments});

  @override
  BBSPostDetailState createState() => BBSPostDetailState();
}

class BBSPostDetailState extends State<BBSPostDetail> {
  /// Unrelated to the state.
  /// These fields should only be initialized once when created.
  late RenderModel _renderModel;
  FileImage? _backgroundImage;

  /// Fields related to the display states.
  bool _multiSelectMode = false;
  bool _allDataLoaded = false;
  final List<OTFloor> _selectedFloors = [];
  bool shouldScrollToEnd = false;
  OTFloor? locateFloor;

  final PagedListViewController<OTFloor> _listViewController =
      PagedListViewController<OTFloor>();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTFloor>?> _loadContent(int page) async {
    Future<List<OTFloor>?> loadPunishmentHistory(int page) async {
      if (page == 0) {
        return (await ForumRepository.getInstance().getPunishmentHistory())
            ?.map((e) => e.floor!)
            .toList();
      } else {
        // notify the list view that there is no more data - the first page is the last page.
        return [];
      }
    }

    final results = switch (_renderModel) {
      Normal(hole: var hole) => await ForumRepository.getInstance()
          .loadFloors(hole, startFloor: page * Constant.POST_COUNT_PER_PAGE),
      Search(keyword: var searchKeyword) => await ForumRepository.getInstance()
          .loadSearchResults(searchKeyword,
              startFloor: _listViewController.length()),
      MyReplies() => await ForumRepository.getInstance()
          .loadUserFloors(startFloor: _listViewController.length()),
      ViewHistory() => (await ForumRepository.getInstance().loadHolesById(
                  SettingsProvider.getInstance()
                      .viewHistory
                      .skip(_listViewController.length())) ??
              [])
          .map((hole) => hole.floors!.first_floor!)
          .toList(),
      PunishmentHistory() => await loadPunishmentHistory(page),
    };

    return results;
  }

  /// Build the text form of a floor for sharing.
  String _renderFloorAsText(OTFloor floor, int index) {
    StringBuffer shareText = StringBuffer();
    String postTime = DateFormat("yyyy/MM/dd HH:mm")
        .format(DateTime.tryParse(floor.time_created!)!.toLocal());
    shareText.writeln("${floor.anonyname} 于 $postTime");
    shareText.writeln("${index}F (##${floor.floor_id})");
    shareText.write(renderText(
        floor.filteredContent ?? "",
        S.of(context).image_tag,
        S.of(context).formula,
        S.of(context).sticker_tag,
        removeMentions: false));
    return shareText.toString();
  }

  Future<bool> _shareFloorAsText(OTFloor floor, int index) async {
    try {
      await FlutterClipboard.copy(_renderFloorAsText(floor, index));
    } catch (e) {
      return false;
    }
    return true;
  }

  Future<bool> _shareHoleAsText() async {
    // load the whole post
    ProgressFuture dialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    List<OTFloor> allFloors;
    try {
      allFloors = await _loadAllContent();
    } catch (error, st) {
      if (mounted) Noticing.showErrorDialog(context, error, trace: st);
      return false;
    } finally {
      dialog.dismiss(showAnim: false);
    }

    if (!mounted) return false;
    final List<int> selectedFloors = [];
    final result = await showPlatformModalSheet<List<int>>(
        context: context,
        builder: (_) {
          return StatefulBuilder(builder: (context, setState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: ViewportUtils.getViewportHeight(context) * 0.85),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      S.of(context).share_hole_title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      primary: false,
                      shrinkWrap: true,
                      itemCount: allFloors.length,
                      itemBuilder: (context, index) {
                        final floor = allFloors[index];
                        return Stack(
                          children: [
                            OTFloorWidget(
                              hasBackgroundImage: false,
                              floor: floor,
                              isInMention: true,
                              showToolBars: false,
                              showBottomBar: true,
                              parentHole: (_renderModel as Normal).hole,
                              onTap: () {
                                setState(() {
                                  if (selectedFloors.contains(index)) {
                                    selectedFloors.remove(index);
                                  } else {
                                    selectedFloors.add(index);
                                  }
                                });
                              },
                            ),
                            if (selectedFloors.contains(index)) ...[
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Center(
                                    child: Icon(
                                      PlatformX.isMaterial(context)
                                          ? Icons.check_circle
                                          : CupertinoIcons
                                              .check_mark_circled_solid,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                ),
                              )
                            ]
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          child: Text(S.of(context).select_all),
                          onPressed: () {
                            setState(() {
                              // if all floors are selected, clear the selection.
                              // Otherwise, select all floors.
                              bool hasSelectedAll =
                                  selectedFloors.length == allFloors.length;
                              selectedFloors.clear();
                              if (!hasSelectedAll) {
                                selectedFloors.addAll(List.generate(
                                    allFloors.length, (index) => index));
                              }
                            });
                          },
                        ),
                        TextButton(
                          onPressed: selectedFloors.isNotEmpty
                              ? () => Navigator.of(context).pop(selectedFloors)
                              : null,
                          child: Text(S.of(context).confirm),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
    if (result == null || !mounted) return false;

    // build share text
    StringBuffer shareText = StringBuffer();
    result.forEachIndexed((index, floorIndex) {
      shareText.write(_renderFloorAsText(allFloors[floorIndex], floorIndex));
      if (index != result.length - 1) {
        shareText.writeln();
        shareText.writeln();
      }
    });
    try {
      await FlutterClipboard.copy(shareText.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('post')) {
      OTHole hole = widget.arguments!['post'];
      _renderModel = Normal(hole);

      // Record view history
      SettingsProvider.getInstance().viewHistory = [
        hole.hole_id!,
        // Limit the number of view history, and avoid duplicate entries
        ...SettingsProvider.getInstance()
            .viewHistory
            .filter((id) => id != hole.hole_id!)
            .take(SettingsProvider.MAX_VIEW_HISTORY - 1)
      ];

      // Update hole view count
      if (hole.hole_id != null) {
        unawaited(
            ForumRepository.getInstance().updateHoleViewCount(hole.hole_id!));
      }
    } else if (widget.arguments!.containsKey('searchKeyword')) {
      _renderModel = Search(widget.arguments!['searchKeyword']);
    } else if (widget.arguments?['punishmentHistory'] == true) {
      _renderModel = PunishmentHistory();
    } else if (widget.arguments?['myReplies'] == true) {
      _renderModel = MyReplies();
    } else if (widget.arguments?['viewHistory'] == true) {
      _renderModel = ViewHistory();
    }

    shouldScrollToEnd = widget.arguments?['scroll_to_end'] == true;
    locateFloor = widget.arguments?["locate"];

    StateProvider.needScreenshotWarning = true;
  }

  /// Refresh the list view.
  Future<void> refreshListView({bool scrollToEnd = false}) async {
    _allDataLoaded = false;
    await _listViewController.notifyUpdate(queueDataClear: true);

    if (scrollToEnd) {
      setState(() {
        shouldScrollToEnd = true;
      });
    }
  }

  @override
  void dispose() {
    StateProvider.needScreenshotWarning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        if (locateFloor != null) {
          try {
            if (!_allDataLoaded) {
              await _loadAllContent();
            }

            final floorToJump = locateFloor!;
            _listViewController.scheduleLoadedCallback(() async {
              await _listViewController.scrollToItem(floorToJump);
            }, rebuild: true);
            locateFloor = null;
          } catch (_) {
            // we don't care if we failed to scroll to the floor.
          }
        }

        if (shouldScrollToEnd) {
          try {
            if (!_allDataLoaded) {
              await _loadAllContent();
            }
            // scroll to end.
            _listViewController.scheduleLoadedCallback(
                () async => await _listViewController.scrollToEnd(),
                rebuild: true);
            shouldScrollToEnd = false;
          } catch (_) {
            // we don't care if we failed to scroll to the end.
          }
        }
      }
    });
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;
    final pagedListView = PagedListView<OTFloor>(
      pagedController: _listViewController,
      noneItem: OTFloor.dummy(),
      withScrollbar: true,
      scrollController: PrimaryScrollController.of(context),
      dataReceiver: _loadContent,
      builder: _getListItems,
      loadingBuilder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        child: Center(child: PlatformCircularProgressIndicator()),
      ),
      endBuilder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: switch (_renderModel) {
            Normal(hole: var hole) when (hole.view ?? -1) >= 0 =>
              Text(S.of(context).view_count(hole.view.toString())),
            _ => Text(S.of(context).end_reached),
          },
        ),
      ),
      // Only show empty message when searching, for now.
      emptyBuilder: switch (_renderModel) {
        Search() => (context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(S.of(context).no_data),
              ),
            ),
        _ => null,
      },
    );

    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: switch (_renderModel) {
            Normal(hole: var hole) => Text("#${hole.hole_id}"),
            Search() => Text(S.of(context).search_result),
            MyReplies() => Text(S.of(context).list_my_replies),
            ViewHistory() => Text(S.of(context).list_view_history),
            PunishmentHistory() => Text(S.of(context).list_my_punishments),
          },
        ),
        trailingActions: [
          if (_renderModel
              case Normal(
                hole: var hole,
                selectedPerson: var selectedPerson
              )) ...[
            _buildSubscribeActionButton(),
            _buildFavoredActionButton(),
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(PlatformX.isMaterial(context)
                  ? Icons.reply
                  : CupertinoIcons.arrowshape_turn_up_left),
              onPressed: () async {
                if (await OTEditor.createNewReply(
                    context, hole.hole_id, null)) {
                  refreshListView(scrollToEnd: true);
                }
              },
            ),
            PlatformPopupMenuX(
              options: [
                PopupMenuOption(
                    label: S.of(context).scroll_to_end,
                    onTap: (_) {
                      setState(() {
                        shouldScrollToEnd = true;
                      });
                    }),
                PopupMenuOption(
                    label: selectedPerson == hole.floors?.first_floor?.anonyname
                        ? S.of(context).show_all_replies
                        : S.of(context).only_show_dz,
                    onTap: (_) {
                      setState(() {
                        if ((_renderModel as Normal).selectedPerson !=
                            hole.floors?.first_floor?.anonyname) {
                          (_renderModel as Normal).selectedPerson =
                              hole.floors?.first_floor?.anonyname;
                        } else {
                          (_renderModel as Normal).selectedPerson = null;
                        }
                      });
                    }),
                PopupMenuOption(
                    label: _multiSelectMode
                        ? S.of(context).multiple_select_mode_exit
                        : S.of(context).multiple_select_mode_enter,
                    onTap: (_) {
                      setState(() {
                        _multiSelectMode = !_multiSelectMode;
                        // if we have just entered multi-choice mode, clear the selected floors.
                        if (_multiSelectMode) {
                          _selectedFloors.clear();
                        }
                      });
                    }),
                PopupMenuOption(
                  label: S.of(context).share_hole,
                  onTap: (_) async {
                    if (await _shareHoleAsText()) {
                      if (context.mounted) {
                        Noticing.showMaterialNotice(
                            context, S.of(context).shareHoleSuccess);
                      }
                    }
                  },
                ),
                PopupMenuOption(
                  label: S.of(context).copy_hole_id,
                  onTap: (_) async {
                    await FlutterClipboard.copy('#${hole.hole_id}');
                    if (context.mounted) {
                      Noticing.showMaterialNotice(
                          context, S.of(context).copy_hole_id_success);
                    }
                  },
                ),
                PopupMenuOption(
                    label: S.of(context).hide_hole,
                    onTap: (_) async {
                      bool? result = await Noticing.showConfirmationDialog(
                          context, S.of(context).hide_hole_confirm,
                          isConfirmDestructive: true);
                      if (result == true) {
                        var list = SettingsProvider.getInstance().hiddenHoles;
                        if (hole.hole_id != null &&
                            !list.contains(hole.hole_id!)) {
                          list.add(hole.hole_id!);
                          SettingsProvider.getInstance().hiddenHoles = list;
                        }
                        if (context.mounted) {
                          Noticing.showNotice(
                              context, S.of(context).hide_hole_success);
                        }
                      }
                    }),
              ],
              cupertino: (context, platform) => CupertinoPopupMenuData(
                  cancelButtonData: CupertinoPopupMenuCancelButtonData(
                      child: Text(S.of(context).cancel))),
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.more_vert)
                  : const Icon(CupertinoIcons.ellipsis),
            ),
          ],
          if (_renderModel case ViewHistory())
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete),
              onPressed: () async {
                if (await Noticing.showConfirmationDialog(
                        context, S.of(context).are_you_sure,
                        isConfirmDestructive: true) ==
                    true) {
                  SettingsProvider.getInstance().viewHistory = [];
                  refreshListView();
                }
              },
            )
        ],
      ),
      body: Builder(
        // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
        builder: (context) => Container(
          decoration: _backgroundImage == null
              ? null
              : BoxDecoration(
                  image: DecorationImage(
                      image: _backgroundImage!, fit: BoxFit.cover)),
          child: switch (_renderModel) {
            Normal() => RefreshIndicator(
                edgeOffset: MediaQuery.of(context).padding.top,
                color: Theme.of(context).colorScheme.secondary,
                backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();

                  // when users pull to refresh under "only this person" mode,
                  // the mode should be quited since if the floor is deep
                  // the initial request won't fetch them, and the page will be blank.
                  if ((_renderModel as Normal).selectedPerson !=
                      (_renderModel as Normal)
                          .hole
                          .floors
                          ?.first_floor
                          ?.anonyname) {
                    (_renderModel as Normal).selectedPerson = null;
                  }
                  await refreshListView();
                },
                child: pagedListView),
            _ => pagedListView,
          },
        ),
      ),
    ).withWatermarkRegion();
  }

  // Load all floors, in case we have to scroll to end or to a specific floor.
  Future<List<OTFloor>> _loadAllContent() async {
    final allFloors = await ForumRepository.getInstance()
        .loadFloors((_renderModel as Normal).hole, startFloor: 0, length: 0);

    if (allFloors == null) {
      throw Exception("Failed to fetch all floors");
    }

    _listViewController.replaceAllDataWith(allFloors);
    _allDataLoaded = true;

    return allFloors;
  }

  Widget _buildFavoredActionButton() {
    var notFavoredIcon = Icon(PlatformX.isMaterial(context)
        ? Icons.star_outline
        : CupertinoIcons.star);

    return PlatformIconButton(
      padding: EdgeInsets.zero,
      icon: FutureWidget<bool>(
        future: (_renderModel as Normal).isHoleFavorite(),
        loadingBuilder: notFavoredIcon,
        successBuilder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          bool? isFavored = snapshot.data;
          return isFavored!
              ? Icon(PlatformX.isMaterial(context)
                  ? Icons.star
                  : CupertinoIcons.star_fill)
              : notFavoredIcon;
        },
        errorBuilder: () => Icon(
          PlatformIcons(context).error,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onPressed: () async {
        final normalModel = _renderModel as Normal;
        if (normalModel.isFavored == null) return;
        setState(() => normalModel.isFavored = !normalModel.isFavored!);
        await ForumRepository.getInstance()
            .setFavorite(
                normalModel.isFavored!
                    ? SetStatusMode.ADD
                    : SetStatusMode.DELETE,
                normalModel.hole.hole_id)
            .onError((dynamic error, stackTrace) {
          Noticing.showNotice(context, error.toString(),
              title: S.of(context).operation_failed, useSnackBar: false);
          setState(() => normalModel.isFavored = !normalModel.isFavored!);
          return null;
        });
      },
    );
  }

  // TODO: refactor to reduce redundant code
  Widget _buildSubscribeActionButton() {
    var notSubscribedIcon = Icon(PlatformX.isMaterial(context)
        ? Icons.visibility_off
        : CupertinoIcons.eye_slash);

    return PlatformIconButton(
      padding: EdgeInsets.zero,
      icon: FutureWidget<bool>(
        future: (_renderModel as Normal).isHoleSubscribed(),
        loadingBuilder: notSubscribedIcon,
        successBuilder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          bool? isSubscribed = snapshot.data;
          return isSubscribed!
              ? Icon(PlatformX.isMaterial(context)
                  ? Icons.visibility
                  : CupertinoIcons.eye)
              : notSubscribedIcon;
        },
        errorBuilder: () => Icon(
          PlatformIcons(context).error,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      onPressed: () async {
        final normalModel = _renderModel as Normal;
        if (normalModel.isSubscribed == null) return;
        setState(() => normalModel.isSubscribed = !normalModel.isSubscribed!);
        await ForumRepository.getInstance()
            .setSubscription(
                normalModel.isSubscribed!
                    ? SetStatusMode.ADD
                    : SetStatusMode.DELETE,
                normalModel.hole.hole_id)
            .onError((dynamic error, stackTrace) {
          Noticing.showNotice(context, error.toString(),
              title: S.of(context).operation_failed, useSnackBar: false);
          setState(() => normalModel.isSubscribed = !normalModel.isSubscribed!);
          return null;
        });
      },
    );
  }

  List<OTTag> deepCopyTagList(List<OTTag> list) =>
      list.map((e) => OTTag.fromJson(jsonDecode(jsonEncode(e)))).toList();

  List<Widget> _buildContextMenu(
      BuildContext menuContext, OTFloor e, int index) {
    List<Widget> buildAdminMenu(BuildContext menuContext, OTFloor e) {
      return [
        PlatformContextMenuItem(
          onPressed: () async {
            if (await OTEditor.modifyReply(
                context, e.hole_id, e.floor_id, e.content)) {
              Noticing.showMaterialNotice(
                  context, S.of(context).operation_successful);
            }
          },
          isDestructive: true,
          menuContext: menuContext,
          child: Text(S.of(context).modify_floor),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            if (await showAdminOperation(context, e)) {
              Noticing.showMaterialNotice(
                  context, S.of(context).operation_successful);
            }
          },
          isDestructive: true,
          menuContext: menuContext,
          child: const Text("打开帖子管理页面"),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            bool? lock = await Noticing.showConfirmationDialog(
                context, "锁定或解锁帖子？",
                confirmText: "锁定", cancelText: "解锁");
            if (lock != null) {
              int? result = await ForumRepository.getInstance()
                  .adminLockHole(e.hole_id, lock);
              if (result != null && result < 300 && mounted) {
                Noticing.showMaterialNotice(
                    context, S.of(context).operation_successful);
              }
            }
          },
          isDestructive: true,
          menuContext: menuContext,
          child: const Text("锁定/解锁帖子"),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            bool? hide = await Noticing.showConfirmationDialog(
                context, "隐藏或显示帖子？",
                confirmText: "Hide", cancelText: "Unhide");
            if (hide != null) {
              int? result = hide
                  ? await ForumRepository.getInstance()
                      .adminDeleteHole(e.hole_id)
                  : await ForumRepository.getInstance()
                      .adminUndeleteHole(e.hole_id);
              if (result != null && result < 300 && mounted) {
                Noticing.showMaterialNotice(
                    context, S.of(context).operation_successful);
              }
            }
          },
          isDestructive: true,
          menuContext: menuContext,
          child: const Text("隐藏/显示帖子"),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            bool? sens = await Noticing.showConfirmationDialog(
                context, "标记或取消帖子敏感状态？",
                confirmText: "标记敏感", cancelText: "取消敏感");
            if (sens != null) {
              int? result = await ForumRepository.getInstance()
                  .adminSetAuditFloor(e.floor_id!, sens);
              if (result != null && result < 300 && mounted) {
                Noticing.showMaterialNotice(
                    context, S.of(context).operation_successful);
              }
            }
          },
          isDestructive: true,
          menuContext: menuContext,
          child: const Text("标记/取消敏感"),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            bool? confirmed = await Noticing.showConfirmationDialog(
                context, S.of(context).are_you_sure_pin_unpin,
                isConfirmDestructive: true);
            if (confirmed != true || !mounted) return;

            ForumProvider provider = context.read<ForumProvider>();
            int divisionId = provider.currentDivision!.division_id!;
            List<int> pinned = provider.currentDivision!.pinned!
                .map((hole) => hole.hole_id!)
                .toList();
            if (pinned.contains(e.hole_id!)) {
              pinned.remove(e.hole_id!);
            } else {
              pinned.add(e.hole_id!);
            }
            int? result = await ForumRepository.getInstance()
                .adminModifyDivision(divisionId, null, null, pinned);
            if (result != null && result < 300) {
              // refresh the division's pinned holes
              final _ = await ForumRepository.getInstance()
                  .loadSpecificDivision(divisionId, useCache: false);
              if (mounted) {
                Noticing.showMaterialNotice(
                    context, S.of(context).operation_successful);
              }
            }
          },
          menuContext: menuContext,
          child: Text(S.of(context).pin_unpin_hole),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            final tag = await Noticing.showInputDialog(
                context, S.of(context).input_reason);
            if (tag == null) {
              return; // Note: don't return if tag is empty string, because user may want to clear the special tag with this
            }
            int? result = await ForumRepository.getInstance()
                .adminAddSpecialTag(tag, e.floor_id);
            if (result != null && result < 300 && mounted) {
              Noticing.showMaterialNotice(
                  context, S.of(context).operation_successful);
            }
          },
          menuContext: menuContext,
          child: Text(S.of(context).add_special_tag),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            final hole = (_renderModel as Normal).hole;
            OTDivision selectedDivision = ForumRepository.getInstance()
                .getDivisions()
                .firstWhere(
                    (element) => element.division_id == hole.division_id,
                    orElse: () => OTDivision(hole.division_id, '', '', null));

            List<Widget> buildDivisionOptionsList(BuildContext cxt) {
              List<Widget> list = [];
              onTapListener(OTDivision newDivision) {
                Navigator.of(cxt).pop(newDivision);
              }

              ForumRepository.getInstance().getDivisions().forEach((value) {
                list.add(ListTile(
                  title: Text(value.name ?? "null"),
                  subtitle: Text(value.description ?? ""),
                  onTap: () => onTapListener(value),
                ));
              });
              return list;
            }

            final Widget divisionOptionsView = StatefulBuilder(
                builder: (BuildContext context, Function setState) => Listener(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selectedDivision.name ?? "?"),
                        const Icon(Icons.arrow_drop_down)
                      ],
                    ),
                    onPointerUp: (PointerUpEvent details) async {
                      if (context.read<ForumProvider>().isUserInitialized &&
                          ForumRepository.getInstance()
                              .getDivisions()
                              .isNotEmpty) {
                        selectedDivision =
                            (await showPlatformModalSheet<OTDivision>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      final Widget content = Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: ListView(
                                              shrinkWrap: true,
                                              primary: false,
                                              children:
                                                  buildDivisionOptionsList(
                                                      context)));
                                      return PlatformX.isCupertino(context)
                                          ? SafeArea(
                                              child: Card(child: content))
                                          : SafeArea(child: content);
                                    })) ??
                                selectedDivision;
                        setState(() {});
                      }
                    }));

            final newTagsList = deepCopyTagList(hole.tags ?? []);
            bool? confirmChanged = await showPlatformDialog<bool>(
              context: context,
              builder: (BuildContext context) => PlatformAlertDialog(
                title: Text(S.of(context).modify_tag_division),
                content: Column(
                  children: [
                    divisionOptionsView,
                    OTTagSelector(initialTags: newTagsList),
                  ],
                ),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).cancel),
                      onPressed: () => Navigator.pop(context, false)),
                  PlatformDialogAction(
                      cupertino: (context, platform) =>
                          CupertinoDialogActionData(isDefaultAction: true),
                      child: PlatformText(S.of(context).i_see),
                      onPressed: () => Navigator.pop(context, true)),
                ],
              ),
            );
            if (confirmChanged ?? false) {
              int? result = await ForumRepository.getInstance()
                  .adminUpdateTagAndDivision(
                      newTagsList, hole.hole_id, selectedDivision.division_id);
              if (result != null && result < 300 && mounted) {
                Noticing.showMaterialNotice(
                    context, S.of(context).operation_successful);
              }
            }
          },
          menuContext: menuContext,
          child: Text(S.of(context).modify_tag_division),
        ),
      ];
    }

    String postTime = DateFormat("yyyy/MM/dd HH:mm:ss")
        .format(DateTime.tryParse(e.time_created!)!.toLocal());
    String postTimeStr = S.of(menuContext).post_time(postTime);

    List<Widget> menu = [
      if (e.is_me == true && e.deleted == false) ...[
        PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () async {
            if (await OTEditor.modifyReply(
                context, e.hole_id, e.floor_id, e.content)) {
              if (!mounted) return;
              Noticing.showMaterialNotice(
                  context, S.of(context).request_success);
              ForumRepository.getInstance().invalidateFloorCache(e.floor_id!);
              final newFloor = await ForumRepository.getInstance()
                  .loadFloorById(e.floor_id!);
              _listViewController.replaceDatumWith(e, newFloor!);
            }
            // await refreshListView();
            // // Set duration to 0 to execute [jumpTo] to the top.
            // await _listViewController.scrollToIndex(0, const Duration());
            // await scrollDownToFloor(e);
          },
          child: Text(S.of(context).modify),
        ),
        PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () async {
            if (await Noticing.showConfirmationDialog(context,
                    S.of(context).about_to_delete_floor(e.floor_id ?? "null"),
                    title: S.of(context).are_you_sure,
                    isConfirmDestructive: true) ==
                true) {
              if (!context.mounted) return;
              try {
                await ForumRepository.getInstance().deleteFloor(e.floor_id!);
                Noticing.showMaterialNotice(
                    context, S.of(context).request_success);
                ForumRepository.getInstance().invalidateFloorCache(e.floor_id!);
                final newFloor = await ForumRepository.getInstance()
                    .loadFloorById(e.floor_id!);
                _listViewController.replaceDatumWith(e, newFloor!);
              } catch (e, st) {
                Noticing.showErrorDialog(context, e, trace: st);
              }
            }
          },
          child: Text(S.of(context).delete),
        )
      ],

      // Standard Operations
      PlatformContextMenuItem(
          menuContext: menuContext,
          child: Text(postTimeStr),
          onPressed: () async {
            await FlutterClipboard.copy(postTimeStr);
            if (mounted && menuContext.mounted) {
              Noticing.showMaterialNotice(
                  context, S.of(menuContext).copy_success);
            }
          }),
      PlatformContextMenuItem(
        menuContext: menuContext,
        onPressed: () => smartNavigatorPush(context, "/text/detail",
            arguments: {"text": e.filteredContent}),
        child: Text(S.of(menuContext).free_select),
      ),
      PlatformContextMenuItem(
          menuContext: menuContext,
          child: Text(S.of(menuContext).copy),
          onPressed: () async {
            await FlutterClipboard.copy(
                renderText(e.filteredContent!, '', '', ''));
            if (mounted && menuContext.mounted) {
              Noticing.showMaterialNotice(
                  context, S.of(menuContext).copy_success);
            }
          }),
      PlatformContextMenuItem(
        menuContext: menuContext,
        onPressed: () async {
          FlutterClipboard.copy('##${e.floor_id}');
          if (mounted) {
            Noticing.showMaterialNotice(
                context, S.of(context).copy_floor_id_success);
          }
        },
        child: Text(S.of(context).copy_floor_id),
      ),
      PlatformContextMenuItem(
        menuContext: menuContext,
        onPressed: () async {
          if (await _shareFloorAsText(e, index)) {
            if (mounted) {
              Noticing.showMaterialNotice(
                  context, S.of(context).shareFloorSuccess);
            }
          }
        },
        child: Text(S.of(context).share_floor),
      ),
      if (_renderModel
          case Normal(selectedPerson: var selectedPerson, hole: _)) ...[
        PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () async {
            setState(() {
              var model = _renderModel as Normal;
              model.selectedPerson =
                  model.selectedPerson != null ? null : e.anonyname;
            });
          },
          child: Text(selectedPerson != null
              ? S.of(context).show_all_replies
              : S.of(context).show_this_person),
        ),
      ],
      PlatformContextMenuItem(
        menuContext: menuContext,
        isDestructive: true,
        onPressed: () async {
          if (await OTEditor.reportPost(context, e.floor_id)) {
            if (!mounted) return;
            Noticing.showMaterialNotice(context, S.of(context).report_success);
          }
        },
        child: Text(S.of(menuContext).report),
      ),

      if (ForumRepository.getInstance().isAdmin) ...[
        PlatformContextMenuItem(
          onPressed: () => showPlatformModalSheet(
              context: context,
              builder: (subMenuContext) => PlatformContextMenu(
                  actions: buildAdminMenu(subMenuContext, e),
                  cancelButton: CupertinoActionSheetAction(
                    child: Text(S.of(subMenuContext).cancel),
                    onPressed: () => Navigator.of(subMenuContext).pop(),
                  ))),
          isDestructive: true,
          menuContext: menuContext,
          child: Text(S.of(context).admin_options),
        ),
      ]
    ];

    return menu;
  }

  List<Widget> _buildMultiSelectContextMenu(BuildContext menuContext) {
    Future<void> multiExecution(List<OTFloor> floorsList,
        Future<int?> Function(OTFloor floors) action) async {
      final floors = floorsList.toList();
      List<int?> results = await Future.wait(floors.map(action));

      List<int> successIds = [];
      List<int> failedIds = [];
      results.forEachIndexed((index, result) {
        if (result != null && result < 300) {
          successIds.add(floors[index].floor_id!);
        } else {
          failedIds.add(floors[index].floor_id!);
        }
      });
      if (mounted) {
        Noticing.showMaterialNotice(context,
            "${S.of(context).operation_successful}\nOK ($successIds), Failed ($failedIds)");
      }
    }

    List<Widget> buildAdminMenu(BuildContext menuContext) {
      return [
        PlatformContextMenuItem(
          onPressed: () async {
            if (await Noticing.showConfirmationDialog(
                    context, S.of(context).are_you_sure,
                    isConfirmDestructive: true) ==
                true) {
              final reason = await Noticing.showInputDialog(
                  context, S.of(context).input_reason);
              await multiExecution(
                  _selectedFloors,
                  (floor) async => await ForumRepository.getInstance()
                      .adminDeleteFloor(floor.floor_id, reason));
            }
          },
          isDestructive: true,
          menuContext: menuContext,
          child: Text(S.of(context).delete_floor),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            final tag = await Noticing.showInputDialog(
                context, S.of(context).input_reason);
            if (tag == null) {
              return; // Note: don't return if tag is empty string, because user may want to clear the special tag with this
            }
            await multiExecution(
                _selectedFloors,
                (floor) async => await ForumRepository.getInstance()
                    .adminAddSpecialTag(tag, floor.floor_id));
          },
          menuContext: menuContext,
          child: Text(S.of(context).add_special_tag),
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            final reason = await Noticing.showInputDialog(
                context, S.of(context).input_reason);
            if (reason == null) {
              return; // Note: don't return if tag is empty string, because user may want to clear the special tag with this
            }
            await multiExecution(
                _selectedFloors,
                (floor) async => await ForumRepository.getInstance()
                    .adminFoldFloor(
                        reason.isEmpty ? [] : [reason], floor.floor_id));
          },
          menuContext: menuContext,
          child: Text(S.of(context).fold_floor),
        ),
      ];
    }

    List<Widget> menu = [
      if (ForumRepository.getInstance().isAdmin) ...[
        PlatformContextMenuItem(
          onPressed: () => showPlatformModalSheet(
              context: context,
              builder: (subMenuContext) => PlatformContextMenu(
                  actions: buildAdminMenu(subMenuContext),
                  cancelButton: CupertinoActionSheetAction(
                    child: Text(S.of(subMenuContext).cancel),
                    onPressed: () => Navigator.of(subMenuContext).pop(),
                  ))),
          isDestructive: true,
          menuContext: menuContext,
          child: Text(S.of(context).admin_options),
        ),
      ]
    ];

    return menu;
  }

  Widget _getListItems(BuildContext context, ListProvider<OTFloor> dataProvider,
      int index, OTFloor floor,
      {bool isNested = false}) {
    if (_renderModel case Normal(selectedPerson: var selectedPerson, hole: _)) {
      if (selectedPerson != null && floor.anonyname != selectedPerson) {
        return nil;
      }
    }

    Future<List<ImageUrlInfo>?> loadPageImage(
        BuildContext pageContext, int pageIndex) async {
      List<OTFloor>? result = switch (_renderModel) {
        Normal(hole: var hole) => await ForumRepository.getInstance()
            .loadFloors(hole,
                startFloor: pageIndex * Constant.POST_COUNT_PER_PAGE),
        Search(keyword: var searchKeyword) =>
          await ForumRepository.getInstance().loadSearchResults(searchKeyword,
              startFloor: pageIndex * Constant.POST_COUNT_PER_PAGE),
        MyReplies() => (await ForumRepository.getInstance().loadUserFloors(
            startFloor: pageIndex * Constant.POST_COUNT_PER_PAGE)),
        ViewHistory() => (await ForumRepository.getInstance().loadHolesById(
                    SettingsProvider.getInstance()
                        .viewHistory
                        .skip(_listViewController.length())) ??
                [])
            .map((hole) => hole.floors!.first_floor!)
            .toList(),
        PunishmentHistory() =>
          (await ForumRepository.getInstance().getPunishmentHistory())
              ?.map((e) => e.floor!)
              .toList(),
      };

      if (result == null || result.isEmpty) {
        return null;
      } else {
        List<ImageUrlInfo> imageList = [];
        for (var floor in result) {
          if (floor.content == null) continue;
          imageList.addAll(extractAllImagesInFloor(floor.content!));
        }
        return imageList;
      }
    }

    final floorWidget = OTFloorWidget(
      hasBackgroundImage: _backgroundImage != null,
      floor: floor,
      index: _renderModel is Normal ? index : null,
      isInMention: isNested,
      parentHole: switch (_renderModel) {
        Normal(hole: var hole) => hole,
        _ => null,
      },
      onLongPress: () async {
        showPlatformModalSheet(
            context: context,
            builder: (BuildContext context) => PlatformContextMenu(
                actions: _multiSelectMode
                    ? _buildMultiSelectContextMenu(context)
                    : _buildContextMenu(context, floor, index),
                cancelButton: CupertinoActionSheetAction(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(),
                )));
      },
      onTap: _multiSelectMode
          ? () {
              // If we are in multi-select mode, we should (un)select the floor.
              setState(() {
                if (_selectedFloors.contains(floor)) {
                  _selectedFloors.remove(floor);
                } else if (floor.floor_id != null) {
                  _selectedFloors.add(floor);
                }
              });
            }
          : () async {
              switch (_renderModel) {
                case Normal(hole: var hole):
                  int? replyId;
                  // Set the replyId to null when tapping on the first reply.
                  if (hole.floors?.first_floor?.floor_id != floor.floor_id) {
                    replyId = floor.floor_id;
                    ForumRepository.getInstance().cacheFloor(floor);
                  }
                  if (await OTEditor.createNewReply(
                      context, hole.hole_id, replyId)) {
                    await refreshListView(scrollToEnd: true);
                  }
                  break;
                default:
                  await OTFloorMentionWidget.jumpToFloorInNewPage(
                      context, floor);
              }
            },
      onTapImage: (String? url, Object heroTag) {
        final int length = _listViewController.length();
        smartNavigatorPush(context, '/image/detail', arguments: {
          'preview_url': url,
          'hd_url':
              ForumRepository.getInstance().extractHighDefinitionImageUrl(url!),
          'hero_tag': heroTag,
          'image_list': extractAllImages(),
          'loader': loadPageImage,
          'last_page': length % Constant.POST_COUNT_PER_PAGE == 0
              ? (length ~/ Constant.POST_COUNT_PER_PAGE - 1)
              : length ~/ Constant.POST_COUNT_PER_PAGE
        });
      },
      searchKeyWord: switch (_renderModel) {
        Search(keyword: var keyword) => keyword,
        _ => null,
      },
    );

    if (_multiSelectMode && _selectedFloors.contains(floor)) {
      return Stack(
        children: [
          floorWidget,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Icon(
                  PlatformX.isMaterial(context)
                      ? Icons.check_circle
                      : CupertinoIcons.check_mark_circled_solid,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          )
        ],
      );
    } else {
      return floorWidget;
    }
  }

  Iterable<ImageUrlInfo> extractAllImagesInFloor(String content) {
    final imageExp = RegExp(r'!\[.*?\]\((?!danxi_|dx_)(.*?)\)');
    return imageExp.allMatches(content).map((e) => ImageUrlInfo(
        e.group(1),
        ForumRepository.getInstance()
            .extractHighDefinitionImageUrl(e.group(1)!)));
  }

  List<ImageUrlInfo> extractAllImages() {
    List<ImageUrlInfo> imageList = [];
    final int length = _listViewController.length();
    for (int i = 0; i < length; i++) {
      var floor = _listViewController.getElementAt(i);
      if (floor.content == null) continue;
      imageList.addAll(extractAllImagesInFloor(floor.content!));
    }
    return imageList;
  }
}

StatelessWidget smartRender(
    BuildContext context,
    String content,
    LinkTapCallback? onTapLink,
    ImageTapCallback? onTapImage,
    bool translucentCard,
    {bool preview = false}) {
  return PostRenderWidget(
    render: SettingsProvider.getInstance().isMarkdownRenderingEnabled
        ? kMarkdownRender
        : kPlainRender,
    content: preprocessContentForDisplay(content),
    onTapImage: onTapImage,
    onTapLink: onTapLink,
    hasBackgroundImage: translucentCard,
    isPreviewWidget: preview,
  );
}

sealed class RenderModel {}

class Normal extends RenderModel {
  OTHole hole;
  bool? isFavored, isSubscribed;
  String? selectedPerson;

  Normal(this.hole);

  Future<bool> isHoleFavorite() async {
    if (isFavored != null) return isFavored!;
    final List<int>? favorites =
        await (ForumRepository.getInstance().getFavoriteHoleId());
    isFavored = favorites!.any((elementId) => elementId == hole.hole_id);
    return isFavored!;
  }

  Future<bool> isHoleSubscribed() async {
    if (isSubscribed != null) return isSubscribed!;
    final List<int>? subscriptions =
        await (ForumRepository.getInstance().getSubscribedHoleId());
    isSubscribed = subscriptions!.any((elementId) => elementId == hole.hole_id);
    return isSubscribed!;
  }
}

class Search extends RenderModel {
  String keyword;

  Search(this.keyword);
}

class MyReplies extends RenderModel {}

class ViewHistory extends RenderModel {}

class PunishmentHistory extends RenderModel {}
