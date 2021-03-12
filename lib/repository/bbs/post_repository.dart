/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:data_plugin/bmob/response/bmob_registered.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';

class PostRepository {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;

  PostRepository._();

  Future<BmobUser> login(PersonInfo personInfo) async {
    var user = BmobUser();
    user.username = personInfo.name;
    user.email = personInfo.id;
    user.password = personInfo.password;
    return await user.login();
  }

  Future<BmobRegistered> register(PersonInfo personInfo) async {
    var user = BmobUser();
    user
      ..username = personInfo.name
      ..email = "${personInfo.id}@fudan.edu.cn"
      ..password = personInfo.password;
    return await user.register();
  }

  Future<List<BBSPost>> loadPosts() async {
    var list = await BBSPost.QUERY_ALL_POST.queryObjects();
    return list.map((e) => BBSPost.fromJson(e)).toList();
  }

  Future<List<BBSPost>> loadReplies(BBSPost post) async {
    var list = await BBSPost.QUERY_ALL_REPLIES(post).queryObjects();
    var bbsList = [post];
    bbsList.addAll(list.map((e) => BBSPost.fromJson(e)));
    return bbsList;
  }
}
