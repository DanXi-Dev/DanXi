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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dio/dio.dart';

class TermsNotAgreed implements Exception {}

class QRCodeRepository extends BaseRepositoryWithDio {
  static const String QR_URL =
      "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode";

  QRCodeRepository._();

  static final _instance = QRCodeRepository._();

  factory QRCodeRepository.getInstance() => _instance;

  Future<String> getQRCode() {
    final options = RequestOptions(
      method: "GET",
      path: QR_URL,
      responseType: ResponseType.plain,
    );
    return FudanSession.request(options, (rep) {
      final soup = BeautifulSoup(rep.data.toString());
      try {
        return soup.find("#myText")!.attributes['value']!;
      } catch (_) {
        if (soup.find("#btn-agree-ok") != null) {
          throw TermsNotAgreed();
        } else {
          rethrow;
        }
      }
    });
  }

  @override
  String get linkHost => "fudan.edu.cn";
}
