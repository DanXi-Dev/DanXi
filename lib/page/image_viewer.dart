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
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/future_widget.dart';
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
import 'package:dan_xi/public_extension_methods.dart';
import 'package:share/share.dart';

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

  static bool isImage(String url) {
    if (url == null || url.isEmpty || Uri.tryParse(url) == null) return false;
    String path = Uri.parse(url).path?.toLowerCase();
    if (path == null) return false;
    return IMAGE_SUFFIX.any((element) => path.endsWith(element));
  }

  static String getMineType(String url) {
    if (!isImage(url)) return '';
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
  String _url;
  String _fileName;

  @override
  void initState() {
    super.initState();
    _url = widget.arguments['url'];
    _fileName = Uri.parse(_url).pathSegments.last;
  }

  Future<void> loadImage(String url) async {
    if (_rawImage != null && _rawImage.isNotEmpty) return;
    Response response = await widget.dio.get(url);
    _rawImage = response.data;
  }

  Widget _buildErrorWidget() => GestureDetector(
        child: Center(
          child: Text(S.of(context).failed),
        ),
        onTap: () {
          _rawImage = null;
          refreshSelf();
        },
      );

  Future<File> saveToFile(
      String dirName, String fileName, List<int> bytes) async {
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile = File("${documentDir.absolute.path}/$dirName/$fileName");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsBytes(bytes, flush: true);
    return outputFile;
  }

  Future<void> shareImage() async {
    // Save the image temporarily
    Directory documentDir = await getApplicationDocumentsDirectory();
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
        iosContentPadding: true,
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
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.save),
              onPressed: saveImage,
            )
          ],
        ),
        body: Container(
            child: FutureWidget<void>(
          nullable: true,
          future: loadImage(_url),
          successBuilder: (_, __) => PhotoView(
            imageProvider: MemoryImage(Uint8List.fromList(_rawImage)),
            backgroundDecoration:
                BoxDecoration(color: Theme.of(context).canvasColor),
          ),
          loadingBuilder: Center(
            child: PlatformCircularProgressIndicator(),
          ),
          errorBuilder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            return _buildErrorWidget();
          },
        )));
  }
}
