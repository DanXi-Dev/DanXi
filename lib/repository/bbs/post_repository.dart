import 'package:dan_xi/model/post.dart';

import '../../model/post.dart';

class PostRepository {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;

  PostRepository._();

  Future<List<BBSPost>> loadPosts() async {
    var list = await BBSPost.QUERY_ALL_POST.queryObjects();
    return list.map((e) => BBSPost.fromJson(e)).toList();
  }
}
