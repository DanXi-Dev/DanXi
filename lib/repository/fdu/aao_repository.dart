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

class FudanAAORepository extends BaseRepositoryWithDio {
  FudanAAORepository._();

  static String _undergraduateListUrl(String type, int page) {
    return "https://jwc.fudan.edu.cn/$type/list${page <= 1 ? "" : page.toString()}.htm";
  }

  static const String _UNDERGRADUATE_BASE_URL = "https://jwc.fudan.edu.cn";
  static const String TYPE_UNDERGRADUATE_NOTICE_ANNOUNCEMENT = "9397";

  static final _instance = FudanAAORepository._();

  factory FudanAAORepository.getInstance() => _instance;

  Future<List<Notice>> getUndergraduateNotices(
      String type, int page) {
    final options = RequestOptions(
        method: "GET",
        path: _undergraduateListUrl(type, page),
        responseType: ResponseType.plain);
    return FudanSession.request(options, (req) {
      List<Notice> notices = [];
      final responseHtml = req.data.toString();
      if (responseHtml.contains("Under Maintenance")) {
        throw NotConnectedToLANError();
      }
      final soup = BeautifulSoup(responseHtml);
      final noticeNodes = soup
          .findAll(".wp_article_list_table > tbody > tr > td > table > tbody")
          .map((e) => e.element!);
      for (final noticeNode in noticeNodes) {
        final noticeInfo =
            noticeNode.querySelector("tr")!.querySelectorAll("td");
        notices.add(Notice(
            noticeInfo[0].text.trim(),
            _UNDERGRADUATE_BASE_URL +
                noticeInfo[0].querySelector("a")!.attributes["href"]!,
            noticeInfo[1].text.trim()));
      }
      return notices;
    });
  }

  static String _postgraduateListUrl(String type, int page) {
    return "https://gs.fudan.edu.cn/$type/list${page <= 1 ? "" : page.toString()}.htm";
  }

  static const String _POSTGRADUATE_BASE_URL = "https://gs.fudan.edu.cn";
  static const String TYPE_POSTGRADUATE_NOTICE_ANNOUNCEMENT = "tzgg";

  Future<List<Notice>> getPostgraduateNotices(
      String type, int page) {
    final options = RequestOptions(
      method: "GET",
      path: _postgraduateListUrl(type, page),
      responseType: ResponseType.plain,
    );
    return FudanSession.request(options, (req) {
      List<Notice> notices = [];
      final responseHtml = req.data.toString();
      if (responseHtml.contains("Under Maintenance")) {
        throw NotConnectedToLANError();
      }
      final soup = BeautifulSoup(responseHtml);
      final noticeNodes =
          soup.findAll(".wp_article_list > li").map((e) => e.element);
      for (final noticeNode in noticeNodes) {
        final relativePath = noticeNode?.querySelector("a")?.attributes["href"];
        final title = noticeNode?.querySelector("a")?.text.trim();
        final time =
            noticeNode?.querySelector(".Article_PublishDate")?.text.trim();
        notices.add(Notice(
            title ?? "???",
            relativePath != null
                ? _POSTGRADUATE_BASE_URL + relativePath
                : _POSTGRADUATE_BASE_URL,
            time ?? "???"));
      }
      return notices;
    });
  }

  @override
  String get linkHost => "fudan.edu.cn";
}

class NotConnectedToLANError implements Exception {}

class Notice {
  String title;
  String url;
  String time;

  Notice(this.title, this.url, this.time);
}
