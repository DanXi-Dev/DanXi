import 'package:dan_xi/model/post.dart';
import 'package:flutter/material.dart';

class BBSEditorPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSEditorPage({Key key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  BBSPost _post;

  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("写点什么"),
          actions: [
            IconButton(icon: Icon(Icons.send), onPressed: _sendDocument)
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(4),
          child: TextField(
            style: TextStyle(fontSize: 18),
            expands: true,
            controller: _controller,
            maxLines: null,
            autofocus: true,
          ),
        ));
  }

  Future<void> _sendDocument() async {
    _post.content = _controller.text;
    await _post.save();
    Navigator.pop(context);
  }
}
