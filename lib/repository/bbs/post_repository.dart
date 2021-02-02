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
