import 'package:data_plugin/bmob/bmob_query.dart';
import 'package:data_plugin/bmob/table/bmob_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable()
class BBSPost extends BmobObject {
  // ignore: unused_field
  String __type = "BBSPost";

  //replyPost = "0" when it's the first floor of a post
  //replyTo = "0" when it's a reply to nobody
  String author, content, replyPost = "0", replyTo = "0";

  factory BBSPost.fromJson(Map<String, dynamic> json) =>
      _$BBSPostFromJson(json);

  Map<String, dynamic> toJson() => _$BBSPostToJson(this);

  BBSPost(this.author, this.content, this.replyPost, this.replyTo);

  BBSPost.newReply(this.author, this.replyPost,
      {this.replyTo = "0", this.content});

  BBSPost.newPost(this.author, {this.content});

  // ignore: non_constant_identifier_names
  static BmobQuery get QUERY_ALL_POST => BmobQuery<BBSPost>()
      .addWhereEqualTo("replyPost", "0")
      .setOrder("-createdAt");

  // ignore: non_constant_identifier_names
  static BmobQuery QUERY_ALL_REPLIES(BBSPost post) => BmobQuery<BBSPost>()
      .addWhereEqualTo("replyPost", post.objectId)
      .setOrder("createdAt");

  @override
  Map getParams() => new Map<String, dynamic>.from({
        "author": author,
        "content": content,
        "replyPost": replyPost,
        "replyTo": replyTo
      });
}
