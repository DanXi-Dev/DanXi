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

import 'package:dan_xi/model/cloud_sticker.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:flutter/foundation.dart';

class CloudStickerProvider with ChangeNotifier {
  final AnnouncementRepository _repository = AnnouncementRepository.getInstance();
  
  List<CloudSticker> _stickers = [];
  bool _isLoading = false;
  String? _error;

  List<CloudSticker> get stickers => _stickers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initializeStickers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stickers = await _repository.getAvailableStickers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncStickers() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stickers = await _repository.syncStickers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}