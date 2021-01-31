import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BBSSubpage extends StatefulWidget {
  @override
  _BBSSubpageState createState() => _BBSSubpageState();

  BBSSubpage({Key key});
}

class _BBSSubpageState extends State<BBSSubpage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    PersonInfo info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;
    return FutureBuilder(
        builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) => snapshot.hasData
            ? ListView(
                children: snapshot.data
                    .map((e) => ListTile(
                          dense: false,
                          title: Text(e.content,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.author,
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                              Text(
                                e.createdAt,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () {},
                        ))
                    .toList())
            : Container(),
        future: PostRepository.getInstance().loadPosts());
  }
}
