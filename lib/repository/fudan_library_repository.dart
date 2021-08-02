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

import 'package:dan_xi/repository/base_repository.dart';
import 'package:dio/dio.dart';

/// This repository is also designed to check whether the app is connected to the school LAN.
class FudanLibraryRepository extends BaseRepositoryWithDio {
  static const String _INFO_URL = "http://10.55.101.62/book/show";

  FudanLibraryRepository._();

  static final _instance = FudanLibraryRepository._();

  factory FudanLibraryRepository.getInstance() => _instance;

  Future<bool> checkConnection() =>
      getLibraryRawData().then((value) => true, onError: (e) => false);
  /// Get current numbers of people in library.
  ///
  /// Return a list of 4, respectively referring to 文图，理图，张江，枫林,
  /// but I do not know the order.
  Future<List<int>> getLibraryRawData() async {
    RegExp dataMatcher = RegExp(r'(?<=当前在馆人数：)[0-9]+');
    Response r = await dio.get(_INFO_URL);
    String rawHtml = r.data.toString();
    return dataMatcher
        .allMatches(rawHtml)
        .map((e) => int.tryParse(e.group(0)))
        .toList();
  }
  @override
  String get linkHost => "10.55.101.62";
}

class NotConnectedToLANError implements Exception {}
