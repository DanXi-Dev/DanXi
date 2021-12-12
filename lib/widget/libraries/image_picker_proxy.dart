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

import 'package:dan_xi/util/platform_universal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

abstract class ImagePickerProxy {
  Future<String?> pickImage();

  factory ImagePickerProxy.createPicker() {
    if (PlatformX.isMobile) {
      return _ImagePickerMobile();
    } else {
      return _ImagePickerUniversal();
    }
  }

  ImagePickerProxy();
}

class _ImagePickerMobile extends ImagePickerProxy {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }
}

class _ImagePickerUniversal extends ImagePickerProxy {
  @override
  Future<String?> pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.files.single.path;
  }
}
