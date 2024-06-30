import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/repository/independent_cookie_jar.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/dio_log.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

class WebvpnProxy {
  static bool directLinkFailed = false;

  static const String WEBVPN_LOGIN_URL = "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fwebvpn.fudan.edu.cn%2Flogin%3Fcas_login%3Dtrue";

  static final Map<String, String> vpnPrefix = {
    "www.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421e7e056d221347d5871048ce29b5a2e",
    "auth.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38",
    "danke.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73",
    "forum.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f6f853892a7e6e546b0086a09d1b203a46"
  };

  static String getProxiedUri(String uri) {
    Uri? u = Uri.tryParse(uri);
    if (u == null) {
      return uri;
    }

    if (vpnPrefix.containsKey(u.host)) {
      String prefix = "https://${u.host}";
      String proxiedUri = uri;
      if (uri.startsWith(prefix)) {
        proxiedUri = vpnPrefix[u.host]! + uri.substring(prefix.length);
      }

      return proxiedUri;
    } else {
      return uri;
    }
  }
}
