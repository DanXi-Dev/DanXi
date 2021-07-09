import 'package:dan_xi/main.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:flutter/widgets.dart';

const kTabletMasterContainerWidth = 350.0;

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width >= 768.0;
}

class NavigatorX extends Navigator {
  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    // Handles the case where the input context is a navigator element.
    NavigatorState navigator;
    if (context is StatefulElement && context.state is NavigatorState) {
      navigator = context.state as NavigatorState;
    }
    if (rootNavigator) {
      navigator =
          context.findRootAncestorStateOfType<NavigatorState>() ?? navigator;
    } else {
      navigator =
          navigator ?? context.findAncestorStateOfType<NavigatorState>();
    }

    assert(() {
      if (navigator == null) {
        throw FlutterError(
          'Navigator operation requested with a context that does not include a Navigator.\n'
          'The context used to push or pop routes from the Navigator must be that of a '
          'widget that is a descendant of a Navigator widget.',
        );
      }
      return true;
    }());
    return navigator;
  }

  @optionalTypeArgs
  static Future<T> pushNamed<T extends Object>(
    BuildContext context,
    String routeName, {
    Object arguments,
  }) {
    if (isTablet(context)) {
      // TODO: WARNING: Bug: This implementation will not return anything.
      masterDetailControllerKey.currentState
          .setDetailPage(BBSPostDetail(arguments: arguments));
      return null;
    }
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }
}
