/*
 *     Copyright (C) 2022  DanXi-Dev
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

class CurriculumBoardRepository extends BaseRepositoryWithDio {
  static const String _BASE_URL = "http://127.0.0.1:8000";

  CurriculumBoardRepository._() {
    // Override the options set in parent class.
  }

  static final _instance = CurriculumBoardRepository._();

  factory CurriculumBoardRepository.getInstance() => _instance;

  @override
  String get linkHost => '127.0.0.1:8000';
}
