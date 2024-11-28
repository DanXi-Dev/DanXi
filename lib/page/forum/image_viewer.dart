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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/io/cache_manager_with_webvpn.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/src/cache_managers/default_cache_manager.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

/// An image display page, allowing user to share or save the image.
///
/// Arguments:
/// [String] hd_url (Required): the original url of the image, enabling the page to decide the file name.
/// If [preview_url] not set, it should be put in [DefaultCacheManager] first.
///
/// [String] preview_url: the thumbnail url of the image. If set, it should be put in [DefaultCacheManager] first,
/// and [ImageViewerPage] will put a hero attribute on [PhotoView] for transition animation.
///
/// [Object] hero_tag: a hero object used to show animation between page transition.
///
/// [List<ImageUrlInfo>] image_list: a list of images to be shown. If set, <preview_url,hd_url> should be in the list.
///
/// [ImageLoadCallback] loader: a method to load more image on the next page.
///
/// [int] last_page: the page index of the last image of the list. It should be set with [loader]. Default value is 0.
class ImageViewerPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  @protected
  final Dio dio =
      DioUtils.newDioWithProxy(BaseOptions(responseType: ResponseType.bytes));

  static const List<String> IMAGE_SUFFIX = [
    '.jpg',
    '.png',
    '.bmp',
    '.jpeg',
    '.gif',
    '.webp'
  ];

  @override
  ImageViewerPageState createState() => ImageViewerPageState();

  ImageViewerPage({super.key, this.arguments})
      : assert(arguments == null || arguments['hd_url'] != null);

  static bool isImage(String url) {
    if (url.isEmpty || Uri.tryParse(url) == null) return false;
    String? path = Uri.tryParse(url)?.path.toLowerCase();
    if (path == null) return false;
    return IMAGE_SUFFIX.any((element) => path.endsWith(element));
  }

  static String getMineType(String url) {
    if (!isImage(url)) return 'image/png';
    String path = Uri.parse(url).path.toLowerCase();
    return 'image/${IMAGE_SUFFIX.firstWhere((element) => path.endsWith(element)).replaceFirst(RegExp(r"\\."), "").replaceFirst(RegExp("jpg"), "jpeg")}';
  }
}

class ImageViewerPageState extends State<ImageViewerPage> {
  final FocusNode _focusNode = FocusNode();

  late List<ImageUrlInfo> _imageList;
  ImageLoadCallback? _imageLoader;
  late ImageUrlInfo _initInfo;
  Object? heroTag;
  late int initialIndex;
  late PageController controller;

  Map<ImageUrlInfo, String?> originalLoadFailError = {};
  Map<ImageUrlInfo, bool> originalLoading = {};
  bool nextPageLoading = false;

  late int showIndex;
  late int lastIndex;

  @override
  void initState() {
    super.initState();
    _initInfo = ImageUrlInfo(
        widget.arguments!['preview_url'], widget.arguments!['hd_url']!);
    _imageList = widget.arguments!['image_list'] ?? [_initInfo];
    _imageLoader = widget.arguments!['loader'];
    lastIndex = widget.arguments!['last_page'] ?? 0;
    initialIndex = showIndex = _imageList.indexOf(_initInfo);
    controller = PageController(initialPage: initialIndex);
    heroTag = widget.arguments!['hero_tag']!;
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  void didUpdateWidget(ImageViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // remove only failed and loading state, as the image may be reloaded
    originalLoading.removeWhere((key, value) => value);
    originalLoadFailError.clear();
  }

  Future<void> shareImage(BuildContext context) async {
    File image = await DefaultCacheManagerWithWebvpn()
        .getSingleFile(_imageList[showIndex].hdUrl);
    if (!mounted) return;

    if (PlatformX.isMobile) {
      final box = context.findRenderObject() as RenderBox?;
      Share.shareXFiles(
        [
          XFile(image.absolute.path,
              mimeType:
                  ImageViewerPage.getMineType(_imageList[showIndex].hdUrl))
        ],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else if (context.mounted) {
      Noticing.showNotice(context, image.absolute.path);
    }
  }

  static String? _guessExtensionNameFromUrl(String url) {
    if (url.isEmpty || Uri.tryParse(url) == null) return null;
    String? path = Uri.tryParse(url)?.path.toLowerCase();
    if (path == null) return null;
    return path.substring(path.lastIndexOf("."));
  }

  Future<void> saveImage(BuildContext context) async {
    File image = await DefaultCacheManagerWithWebvpn()
        .getSingleFile(_imageList[showIndex].hdUrl);
    if (PlatformX.isAndroid) {
      bool hasPermission = await PlatformX.galleryStorageGranted;
      if (!hasPermission && !(await Permission.storage.request().isGranted)) {
        // Failed to request the permission
        return;
      }
    }
    if (PlatformX.isMobile) {
      // Attach an extension name for the picture file
      File tempFileWithExtName = await image.copy(image.absolute.path +
          (_guessExtensionNameFromUrl(_imageList[showIndex].hdUrl) ?? ""));
      bool result = false;
      try {
        await Gal.putImage(tempFileWithExtName.absolute.path);
        result = true;
      } catch (_) {}
      if (!mounted) return;
      if (result) {
        Noticing.showNotice(context, S.of(context).image_save_success);
      } else {
        Noticing.showNotice(context, S.of(context).image_save_failed);
      }
    } else if (mounted) {
      Noticing.showNotice(context, image.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent keyEvent) {
        if (keyEvent is KeyUpEvent) return;
        if (keyEvent.logicalKey == LogicalKeyboardKey.arrowLeft &&
            showIndex - 1 >= 0) {
          controller.jumpToPage(--showIndex);
        } else if (keyEvent.logicalKey == LogicalKeyboardKey.arrowRight &&
            showIndex + 1 < _imageList.length) {
          controller.jumpToPage(++showIndex);
        }
      },
      child: PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: true,
        appBar: PlatformAppBarX(
          title: Text(_imageList.length == 1
              ? S.of(context).image
              : "${S.of(context).image} (${showIndex + 1}/${_imageList.length})"),
          trailingActions: [
            if (originalLoading[_imageList[showIndex]] != false) ...[
              PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: PlatformCircularProgressIndicator(
                  material: (_, __) => MaterialProgressIndicatorData(
                      color: Theme.of(context).colorScheme.surface),
                ),
              )
            ] else if (originalLoadFailError[_imageList[showIndex]] !=
                null) ...[
              PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: Icon(PlatformIcons(context).error),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => Noticing.showNotice(
                    context, originalLoadFailError[_imageList[showIndex]]!,
                    title: S.of(context).fatal_error, useSnackBar: false),
              ),
            ] else ...[
              PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: Icon(PlatformX.isMaterial(context)
                    ? Icons.share
                    : CupertinoIcons.square_arrow_up),
                onPressed: () => shareImage(context),
              ),
              // Not needed on iOS
              if (!PlatformX.isIOS)
                PlatformIconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.save),
                  onPressed: () => saveImage(context),
                )
            ]
          ],
        ),
        body: NotificationListener<ImageLoadNotification>(
          onNotification: (ImageLoadNotification notification) {
            setState(() {
              originalLoading[notification.imageInfo] =
                  notification.originalLoaded;
              originalLoadFailError[notification.imageInfo] =
                  notification.originalLoadError;
            });
            return true;
          },
          child: PhotoViewGestureDetectorScope(
            axis: Axis.horizontal,
            child: PageView.builder(
              controller: controller,
              dragStartBehavior: DragStartBehavior.down,
              itemCount: _imageList.length,
              itemBuilder: (BuildContext context, int page) {
                return ImageViewerBodyView(
                  imageInfo: _imageList[page],
                  heroTag: _initInfo == _imageList[page] ? heroTag : null,
                );
              },
              onPageChanged: (int pageIndex) {
                setState(() {
                  showIndex = pageIndex;
                });
                if (showIndex == _imageList.length - 1 &&
                    _imageLoader != null &&
                    !nextPageLoading) {
                  _imageLoader?.call(context, ++lastIndex).then((value) {
                    if (value != null) setState(() => _imageList.addAll(value));
                  }, onError: (e, st) {}).whenComplete(() {
                    nextPageLoading = false;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ImageViewerBodyView extends StatefulWidget {
  final ImageUrlInfo imageInfo;
  final Object? heroTag;

  const ImageViewerBodyView({super.key, required this.imageInfo, this.heroTag});

  @override
  ImageViewerBodyViewState createState() => ImageViewerBodyViewState();
}

class ImageViewerBodyViewState extends State<ImageViewerBodyView> {
  late String safeShowingUrl;
  String? originalLoadFailError;
  bool originalLoading = true;

  Future<void> cacheOriginalImage() async {
    if (widget.imageInfo.thumbUrl == null) return;
    try {
      await DefaultCacheManagerWithWebvpn()
          .getSingleFile(widget.imageInfo.hdUrl);
      setState(() => originalLoading = false);
    } catch (e, st) {
      setState(() {
        originalLoading = false;
        originalLoadFailError = ErrorPageWidget.generateUserFriendlyDescription(
            S.of(context), e,
            stackTrace: st);
      });
    } finally {
      if (mounted) {
        ImageLoadNotification(
                widget.imageInfo, originalLoading, originalLoadFailError)
            .dispatch(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    safeShowingUrl = widget.imageInfo.thumbUrl ?? widget.imageInfo.hdUrl;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      unawaited(cacheOriginalImage());
    });
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      gaplessPlayback: true,
      heroAttributes: widget.heroTag != null
          ? PhotoViewHeroAttributes(
              tag: widget.heroTag!, transitionOnUserGestures: true)
          : null,
      imageProvider: originalLoading
          ? CachedNetworkImageProvider(safeShowingUrl)
          : CachedNetworkImageProvider(widget.imageInfo.hdUrl),
      backgroundDecoration: BoxDecoration(color: Theme.of(context).canvasColor),
    );
  }
}

class ImageLoadNotification extends Notification {
  final ImageUrlInfo imageInfo;
  final bool originalLoaded;
  final String? originalLoadError;

  ImageLoadNotification(
      this.imageInfo, this.originalLoaded, this.originalLoadError);
}

class ImageUrlInfo {
  final String? thumbUrl;
  final String hdUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageUrlInfo &&
          runtimeType == other.runtimeType &&
          thumbUrl == other.thumbUrl &&
          hdUrl == other.hdUrl;

  @override
  int get hashCode => thumbUrl.hashCode ^ hdUrl.hashCode;

  ImageUrlInfo(this.thumbUrl, this.hdUrl);
}

typedef ImageLoadCallback = Future<List<ImageUrlInfo>?> Function(
    BuildContext pageContext, int pageIndex);
