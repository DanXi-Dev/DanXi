import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';

class PostFilterJsRuntime {
  static const bool isSupported = true;

  late final JavascriptRuntime _runtime = getJavascriptRuntime(xhr: false);

  bool evaluate(String expression, Map<String, dynamic> post) {
    final script =
        '''(() => {
          "use strict";
          const post = ${jsonEncode(post)};
          const hole = post;
          const {
            id,
            content,
            lastContent,
            tags,
            reply,
            view,
            favoriteCount,
            subscriptionCount,
            first,
            last,
            created,
            updated,
            hidden,
            locked,
            frozen
          } = post;
          return Boolean($expression);
        })()''';
    final result = _runtime.evaluate(script);
    return !result.isError &&
        (result.rawResult == true || result.stringResult == 'true');
  }

  void dispose() {
    _runtime.dispose();
  }
}
