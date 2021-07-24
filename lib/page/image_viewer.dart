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
import 'dart:io';
import 'dart:typed_data';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share/share.dart';

/// An image display page, allowing user to share or save the image.
///
/// Arguments:
/// [Uint8List] raw_image: the raw byte array of the image.
/// [String] url: the original url of the image, enabling the page to decide the file name.
///
class ImageViewerPage extends StatefulWidget {
  final Map<String, dynamic> arguments;
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

  ImageViewerPage({Key key, this.arguments});

  static bool isBase64Image(String content) {
    return content.startsWith("data:image/");
  }

  static bool isImage(String url) {
    if (url == null || url.isEmpty || Uri.tryParse(url) == null) return false;
    if (isBase64Image(url)) return true;

    String path = Uri.parse(url).path?.toLowerCase();
    if (path == null) return false;
    return IMAGE_SUFFIX.any((element) => path.endsWith(element));
  }

  static String getMineType(String url) {
    if (!isImage(url)) return '';
    if (isBase64Image(url)) {
      return url.between("data:", ";base64");
    }
    String path = Uri.parse(url).path.toLowerCase();
    return 'image/' +
        IMAGE_SUFFIX
            .firstWhere((element) => path.endsWith(element))
            .replaceFirst(RegExp(r"\\."), "")
            .replaceFirst(RegExp("jpg"), "jpeg");
  }
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  List<int> _rawImage;
  String _fileName;
  static const _BASE64_IMAGE_FILE_NAME = "base64.jpg";
  String _url;

  @override
  void initState() {
    super.initState();
    _rawImage = widget.arguments['raw_image'];
    _url = widget.arguments['url'];
    _fileName = getFileName(_url);
  }

  getFileName(String url) {
    if (ImageViewerPage.isBase64Image(url)) {
      return _BASE64_IMAGE_FILE_NAME;
    }
    return Uri.parse(url).pathSegments.last;
  }

  Future<File> saveToFile(
      String dirName, String fileName, List<int> bytes) async {
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile = PlatformX.createPlatformFile(
        "${documentDir.absolute.path}/$dirName/$fileName");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsBytes(bytes, flush: true);
    return outputFile;
  }

  Future<void> shareImage() async {
    // Save the image temporarily
    File outputFile = await saveToFile('temp_image', _fileName, _rawImage);
    if (PlatformX.isMobile)
      Share.shareFiles([outputFile.absolute.path],
          mimeTypes: [ImageViewerPage.getMineType(_url)]);
    else {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  Future<void> saveImage() async {
    if (PlatformX.isAndroid) {
      PermissionStatus status = await Permission.storage.status;
      if (!status.isGranted &&
          !(await Permission.storage.request().isGranted)) {
        // Failed to request the permission
        return;
      }
    }
    File outputFile = await saveToFile('image', _fileName, _rawImage);
    if (PlatformX.isMobile) {
      var result = await GallerySaver.saveImage(outputFile.absolute.path);
      if (result != null && result) {
        Noticing.showNotice(context, S.of(context).image_save_success);
      } else {
        Noticing.showNotice(context, S.of(context).image_save_failed);
      }
    } else {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: false,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).image),
          trailingActions: [
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(PlatformX.isMaterial(context)
                  ? Icons.share
                  : SFSymbols.square_arrow_up),
              onPressed: shareImage,
            ),

            // Not needed on iOS
            if (PlatformX.isMaterial(context))
              PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.save),
                onPressed: saveImage,
              )
          ],
        ),
        body: Container(
          child: PhotoView(
            imageProvider: MemoryImage(Uint8List.fromList(_rawImage)),
            backgroundDecoration:
                BoxDecoration(color: Theme.of(context).canvasColor),
          ),
        ));
  }
}
