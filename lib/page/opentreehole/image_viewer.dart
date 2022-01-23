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
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/src/cache_managers/default_cache_manager.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';

/// An image display page, allowing user to share or save the image.
///
/// Arguments:
/// [String] url: the original url of the image, enabling the page to decide the file name.
/// If [thumbUrl] not set, it should be put in [DefaultCacheManager] first.
///
/// [String] thumbUrl: the thumbnail url of the image. If set, it should be put in [DefaultCacheManager] first,
/// and [ImageViewerPage] will put a hero attribute on [PhotoView] for transition animation.
///

class ImageViewerPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  @protected
  final Dio dio = Dio(BaseOptions(responseType: ResponseType.bytes));

  static const List<String> IMAGE_SUFFIX = [
    '.jpg',
    '.png',
    '.bmp',
    '.jpeg',
    '.gif',
    '.webp'
  ];

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();

  ImageViewerPage({Key? key, this.arguments}) : super(key: key);

  static bool isImage(String url) {
    if (url.isEmpty || Uri.tryParse(url) == null) return false;
    String? path = Uri.tryParse(url)?.path.toLowerCase();
    if (path == null) return false;
    return IMAGE_SUFFIX.any((element) => path.endsWith(element));
  }

  static String getMineType(String? url) {
    return 'image/png';

    /*
    if (!isImage(url)) return '';
    String path = Uri.parse(url).path.toLowerCase();
    return 'image/' +
        IMAGE_SUFFIX
            .firstWhere((element) => path.endsWith(element))
            .replaceFirst(RegExp(r"\\."), "")
            .replaceFirst(RegExp("jpg"), "jpeg");*/
  }
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  /// URL for preview image, if it is already in the cache, it makes loading faster.
  String? _previewUrl;

  /// URL for the (high-definition) original image
  late String _originalUrl;

  late String safeShowingUrl;

  bool originalLoading = true;
  String? originalLoadFailError;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.arguments!['thumbUrl'];
    _originalUrl = widget.arguments!['url']!;
    safeShowingUrl = _previewUrl ?? _originalUrl;
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      unawaited(cacheOriginalImage());
    });
  }

  Future<void> cacheOriginalImage() async {
    if (_previewUrl == null) return;
    try {
      await DefaultCacheManager().getSingleFile(_originalUrl);
      setState(() => originalLoading = false);
    } catch (e, st) {
      setState(() {
        originalLoading = false;
        originalLoadFailError = ErrorPageWidget.generateUserFriendlyDescription(
            S.of(context), e,
            stackTrace: st);
      });
    }
  }

  @override
  void didUpdateWidget(ImageViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    originalLoading = true;
    originalLoadFailError = null;
  }

  static String getFileName(String url) {
    try {
      return RegExp(r'(.*)\..*')
              .firstMatch(Uri.parse(url).pathSegments.last)!
              .group(1)! +
          '.png';
    } catch (_) {
      return "${DateFormat("yyyyMMddHHmmSSS").format(DateTime.now())}.png";
    }
    //return Uri.parse(url).pathSegments.last;
  }

  Future<void> shareImage() async {
    File image = await DefaultCacheManager().getSingleFile(_originalUrl);
    if (PlatformX.isMobile) {
      Share.shareFiles([image.absolute.path],
          mimeTypes: [ImageViewerPage.getMineType(_originalUrl)]);
    } else {
      Noticing.showNotice(context, image.absolute.path);
    }
  }

  Future<void> saveImage() async {
    File image = await DefaultCacheManager().getSingleFile(_originalUrl);
    if (PlatformX.isAndroid) {
      PermissionStatus status = await Permission.storage.status;
      if (!status.isGranted &&
          !(await Permission.storage.request().isGranted)) {
        // Failed to request the permission
        return;
      }
    }
    if (PlatformX.isMobile) {
      var result = await GallerySaver.saveImage(image.absolute.path);
      if (result != null && result) {
        Noticing.showNotice(context, S.of(context).image_save_success);
      } else {
        Noticing.showNotice(context, S.of(context).image_save_failed);
      }
    } else {
      Noticing.showNotice(context, image.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).image),
        trailingActions: [
          if (originalLoading) ...[
            PlatformCircularProgressIndicator(
              material: (_, __) => MaterialProgressIndicatorData(
                  color: Theme.of(context).textTheme.bodyText1?.color),
            )
          ] else if (originalLoadFailError != null) ...[
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(PlatformIcons(context).error),
              color: Theme.of(context).errorColor,
              onPressed: () => Noticing.showNotice(
                  context, originalLoadFailError!,
                  title: S.of(context).fatal_error, useSnackBar: false),
            ),
          ] else ...[
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(PlatformX.isMaterial(context)
                  ? Icons.share
                  : CupertinoIcons.square_arrow_up),
              onPressed: shareImage,
            ),
            // Not needed on iOS
            if (!PlatformX.isIOS)
              PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.save),
                onPressed: saveImage,
              )
          ]
        ],
      ),
      body: PhotoView(
        gaplessPlayback: true,
        heroAttributes: PhotoViewHeroAttributes(
            tag: safeShowingUrl, transitionOnUserGestures: true),
        imageProvider: originalLoading
            ? CachedNetworkImageProvider(safeShowingUrl)
            : CachedNetworkImageProvider(_originalUrl),
        backgroundDecoration:
            BoxDecoration(color: Theme.of(context).canvasColor),
      ),
    );
  }
}
