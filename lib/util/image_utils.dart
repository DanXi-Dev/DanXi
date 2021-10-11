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
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_html/shims/dart_ui_real.dart';

class ImageUtils {
  /// Load image byte array from [provider].
  ///
  /// For animated images (e.g. .gif, .png, etc.), it only extracts a frame.
  static Future<Uint8List> providerToBytes(
      BuildContext context, ImageProvider provider) async {
    Completer<Uint8List> completer = Completer();
    var stream = provider.resolve(createLocalImageConfiguration(context));
    stream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) async {
      // Recode the image into png format.
      ByteData byteData =
          await (image.image.toByteData(format: ImageByteFormat.png) as FutureOr<ByteData>);

      // Important: Must call dispose after use
      image.dispose();

      // TODO: does the [buffer] represent the WHOLE image's byte array,
      //  or just a fixed-size (e.g. 512 Bytes) buffer array
      //  that should be filled with data for multiple times to read in the image?
      //  We need more inspection.
      completer.complete(byteData.buffer.asUint8List());
    }));
    return completer.future;
  }
}
