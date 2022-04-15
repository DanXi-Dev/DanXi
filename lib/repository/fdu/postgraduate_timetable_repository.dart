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

import 'dart:convert';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/io/cache.dart';
import 'package:dan_xi/util/js/js.dart'
    if (dart.library.js) 'package:dan_xi/util/js/js_web.dart' as js;
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostgraduateTimetableRepository extends BaseRepositoryWithDio {
  static const String TIME_TABLE_UG_URL =
      'http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do?_=';
  static const String HOMEPAGE_URL =
      "http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/*default/index.do";
  static const String GET_TOKEN_URL =
      "http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/login/4/vcode.do?";
  static const String GET_CAPTCHA_URL =
      "http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/login/vcode/image.do?vtoken=";
  static const String LOGIN_URL =
      "http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/login/check/login.do?";

  PostgraduateTimetableRepository._();

  static final _instance = PostgraduateTimetableRepository._();

  factory PostgraduateTimetableRepository.getInstance() => _instance;

  Future<String> _loadToken() async {
    Response tokenData = await dio.get(GET_TOKEN_URL);
    var temp = tokenData.data is Map
        ? tokenData.data
        : jsonDecode(tokenData.data.toString());
    return temp['data']['token'];
  }

  String encryptDES(String pwd) =>
      js.evaluate(DES_JS.replaceFirst("PASSWORD", pwd));

  Future<void> _requestLogin(
      String id, String pwd, String yzm, String token) async {
    await dio.post(LOGIN_URL,
        data: {
          "loginName": id,
          "loginPwd": pwd,
          "verifyCode": yzm,
          "vtoken": token
        }.encodeMap(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));
  }

  Future<void> _login(PersonInfo ug, OnCaptchaCallback callback) async {
    String yzmToken = await _loadToken();
    String yzm = await callback(GET_CAPTCHA_URL + yzmToken);
    await _requestLogin(ug.id!, encryptDES(ug.password!), yzm, yzmToken);
  }

  Future<TimeTable?> loadTimeTableRemotely(
      PersonInfo info, OnCaptchaCallback callback,
      {DateTime? startTime}) {
    return Retrier.tryAsyncWithFix(
        () => _loadTimeTableRemotely(callback, startTime: startTime),
        (exception) => _login(info, callback));
  }

  Future<TimeTable?> _loadTimeTableRemotely(OnCaptchaCallback callback,
      {DateTime? startTime}) async {
    Response coursePage = await dio.get(
        TIME_TABLE_UG_URL + DateTime.now().millisecondsSinceEpoch.toString(),
        options: Options());
    return TimeTable.fromPGJson(
        startTime ??
            DateTime.tryParse(
                SettingsProvider.getInstance().thisSemesterStartDate ?? "") ??
            Constant.DEFAULT_SEMESTER_START_DATE,
        coursePage.data is Map
            ? coursePage.data
            : jsonDecode(coursePage.data.toString()));
  }

  Future<TimeTable?> loadTimeTable(PersonInfo info, OnCaptchaCallback callback,
      {DateTime? startTime, bool forceLoadFromRemote = false}) {
    startTime ??= TimeTable.defaultStartTime;
    if (forceLoadFromRemote) {
      return Cache.getRemotely<TimeTable>(
          TimeTableRepository.KEY_TIMETABLE_CACHE,
          () async => (await loadTimeTableRemotely(info, callback,
              startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
    } else {
      return Cache.get<TimeTable>(
          TimeTableRepository.KEY_TIMETABLE_CACHE,
          () async => (await loadTimeTableRemotely(info, callback,
              startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
    }
  }

  TimeTable loadTimeTableLocally() {
    SharedPreferences preferences = SettingsProvider.getInstance().preferences!;
    if (preferences.containsKey(TimeTableRepository.KEY_TIMETABLE_CACHE)) {
      return TimeTable.fromJson(jsonDecode(
          preferences.getString(TimeTableRepository.KEY_TIMETABLE_CACHE)!));
    } else {
      throw StateError("No local timetable now");
    }
  }

  @override
  String get linkHost => "yjsxk.fudan.edu.cn";
}

typedef OnCaptchaCallback = Future<String> Function(String imageUrl);

const String DES_JS = '''
function d(X, Q, B, E) {
    var H = X.length;
    var I = "";
    var U, R, O, Y, G, J;
    if (Q != null && Q != "") {
        U = r(Q);
        Y = U.length
    }
    if (B != null && B != "") {
        R = r(B);
        G = R.length
    }
    if (E != null && E != "") {
        O = r(E);
        J = O.length
    }
    if (H > 0) {
        if (H < 4) {
            var V = a(X);
            var F;
            if (Q != null && Q != "" && B != null && B != "" && E != null && E != "") {
                var T;
                var M, L, K;
                T = V;
                for (M = 0; M < Y; M++) {
                    T = e(T, U[M])
                }
                for (L = 0; L < G; L++) {
                    T = e(T, R[L])
                }
                for (K = 0; K < J; K++) {
                    T = e(T, O[K])
                }
                F = T
            } else {
                if (Q != null && Q != "" && B != null && B != "") {
                    var T;
                    var M, L;
                    T = V;
                    for (M = 0; M < Y; M++) {
                        T = e(T, U[M])
                    }
                    for (L = 0; L < G; L++) {
                        T = e(T, R[L])
                    }
                    F = T
                } else {
                    if (Q != null && Q != "") {
                        var T;
                        var M = 0;
                        T = V;
                        for (M = 0; M < Y; M++) {
                            T = e(T, U[M])
                        }
                        F = T
                    }
                }
            }
            I = f(F)
        } else {
            var P = parseInt(H / 4);
            var N = H % 4;
            var S = 0;
            for (S = 0; S < P; S++) {
                var D = X.substring(S * 4 + 0, S * 4 + 4);
                var W = a(D);
                var F;
                if (Q != null && Q != "" && B != null && B != "" && E != null && E != "") {
                    var T;
                    var M, L, K;
                    T = W;
                    for (M = 0; M < Y; M++) {
                        T = e(T, U[M])
                    }
                    for (L = 0; L < G; L++) {
                        T = e(T, R[L])
                    }
                    for (K = 0; K < J; K++) {
                        T = e(T, O[K])
                    }
                    F = T
                } else {
                    if (Q != null && Q != "" && B != null && B != "") {
                        var T;
                        var M, L;
                        T = W;
                        for (M = 0; M < Y; M++) {
                            T = e(T, U[M])
                        }
                        for (L = 0; L < G; L++) {
                            T = e(T, R[L])
                        }
                        F = T
                    } else {
                        if (Q != null && Q != "") {
                            var T;
                            var M;
                            T = W;
                            for (M = 0; M < Y; M++) {
                                T = e(T, U[M])
                            }
                            F = T
                        }
                    }
                }
                I += f(F)
            }
            if (N > 0) {
                var C = X.substring(P * 4 + 0, H);
                var W = a(C);
                var F;
                if (Q != null && Q != "" && B != null && B != "" && E != null && E != "") {
                    var T;
                    var M, L, K;
                    T = W;
                    for (M = 0; M < Y; M++) {
                        T = e(T, U[M])
                    }
                    for (L = 0; L < G; L++) {
                        T = e(T, R[L])
                    }
                    for (K = 0; K < J; K++) {
                        T = e(T, O[K])
                    }
                    F = T
                } else {
                    if (Q != null && Q != "" && B != null && B != "") {
                        var T;
                        var M, L;
                        T = W;
                        for (M = 0; M < Y; M++) {
                            T = e(T, U[M])
                        }
                        for (L = 0; L < G; L++) {
                            T = e(T, R[L])
                        }
                        F = T
                    } else {
                        if (Q != null && Q != "") {
                            var T;
                            var M;
                            T = W;
                            for (M = 0; M < Y; M++) {
                                T = e(T, U[M])
                            }
                            F = T
                        }
                    }
                }
                I += f(F)
            }
        }
    }
    return I
}
function p(W, P, B, D) {
    var F = W.length;
    var G = "";
    var U, R, M, X, E, I;
    if (P != null && P != "") {
        U = r(P);
        X = U.length
    }
    if (B != null && B != "") {
        R = r(B);
        E = R.length
    }
    if (D != null && D != "") {
        M = r(D);
        I = M.length
    }
    var O = parseInt(F / 16);
    var T = 0;
    for (T = 0; T < O; T++) {
        var C = W.substring(T * 16 + 0, T * 16 + 16);
        var H = c(C);
        var V = new Array(64);
        var Q = 0;
        for (Q = 0; Q < 64; Q++) {
            V[Q] = parseInt(H.substring(Q, Q + 1))
        }
        var N;
        if (P != null && P != "" && B != null && B != "" && D != null && D != "") {
            var S;
            var L, K, J;
            S = V;
            for (L = I - 1; L >= 0; L--) {
                S = q(S, M[L])
            }
            for (K = E - 1; K >= 0; K--) {
                S = q(S, R[K])
            }
            for (J = X - 1; J >= 0; J--) {
                S = q(S, U[J])
            }
            N = S
        } else {
            if (P != null && P != "" && B != null && B != "") {
                var S;
                var L, K, J;
                S = V;
                for (L = E - 1; L >= 0; L--) {
                    S = q(S, R[L])
                }
                for (K = X - 1; K >= 0; K--) {
                    S = q(S, U[K])
                }
                N = S
            } else {
                if (P != null && P != "") {
                    var S;
                    var L, K, J;
                    S = V;
                    for (L = X - 1; L >= 0; L--) {
                        S = q(S, U[L])
                    }
                    N = S
                }
            }
        }
        G += v(N)
    }
    return G
}
function o(B) {
    return d(B, "1", "2", "3")
}
function h(B) {
    return p(B, "1", "2", "3")
}
function r(E) {
    var B = new Array();
    var D = E.length;
    var F = parseInt(D / 4);
    var G = D % 4;
    var C = 0;
    for (C = 0; C < F; C++) {
        B[C] = a(E.substring(C * 4 + 0, C * 4 + 4))
    }
    if (G > 0) {
        B[C] = a(E.substring(C * 4 + 0, D))
    }
    return B
}
function a(J) {
    var B = J.length;
    var K = new Array(64);
    if (B < 4) {
        var H = 0
          , G = 0
          , D = 0
          , C = 0;
        for (H = 0; H < B; H++) {
            var F = J.charCodeAt(H);
            for (G = 0; G < 16; G++) {
                var I = 1
                  , E = 0;
                for (E = 15; E > G; E--) {
                    I *= 2
                }
                K[16 * H + G] = parseInt(F / I) % 2
            }
        }
        for (D = B; D < 4; D++) {
            var F = 0;
            for (C = 0; C < 16; C++) {
                var I = 1
                  , E = 0;
                for (E = 15; E > C; E--) {
                    I *= 2
                }
                K[16 * D + C] = parseInt(F / I) % 2
            }
        }
    } else {
        for (H = 0; H < 4; H++) {
            var F = J.charCodeAt(H);
            for (G = 0; G < 16; G++) {
                var I = 1;
                for (E = 15; E > G; E--) {
                    I *= 2
                }
                K[16 * H + G] = parseInt(F / I) % 2
            }
        }
    }
    return K
}
function b(C) {
    var B;
    switch (C) {
    case "0000":
        B = "0";
        break;
    case "0001":
        B = "1";
        break;
    case "0010":
        B = "2";
        break;
    case "0011":
        B = "3";
        break;
    case "0100":
        B = "4";
        break;
    case "0101":
        B = "5";
        break;
    case "0110":
        B = "6";
        break;
    case "0111":
        B = "7";
        break;
    case "1000":
        B = "8";
        break;
    case "1001":
        B = "9";
        break;
    case "1010":
        B = "A";
        break;
    case "1011":
        B = "B";
        break;
    case "1100":
        B = "C";
        break;
    case "1101":
        B = "D";
        break;
    case "1110":
        B = "E";
        break;
    case "1111":
        B = "F";
        break
    }
    return B
}
function l(B) {
    var C;
    switch (B) {
    case "0":
        C = "0000";
        break;
    case "1":
        C = "0001";
        break;
    case "2":
        C = "0010";
        break;
    case "3":
        C = "0011";
        break;
    case "4":
        C = "0100";
        break;
    case "5":
        C = "0101";
        break;
    case "6":
        C = "0110";
        break;
    case "7":
        C = "0111";
        break;
    case "8":
        C = "1000";
        break;
    case "9":
        C = "1001";
        break;
    case "A":
        C = "1010";
        break;
    case "B":
        C = "1011";
        break;
    case "C":
        C = "1100";
        break;
    case "D":
        C = "1101";
        break;
    case "E":
        C = "1110";
        break;
    case "F":
        C = "1111";
        break
    }
    return C
}
function v(E) {
    var D = "";
    for (i = 0; i < 4; i++) {
        var C = 0;
        for (j = 0; j < 16; j++) {
            var B = 1;
            for (m = 15; m > j; m--) {
                B *= 2
            }
            C += E[16 * i + j] * B
        }
        if (C != 0) {
            D += String.fromCharCode(C)
        }
    }
    return D
}
function f(D) {
    var C = "";
    for (i = 0; i < 16; i++) {
        var B = "";
        for (j = 0; j < 4; j++) {
            B += D[i * 4 + j]
        }
        C += b(B)
    }
    return C
}
function c(B) {
    var C = "";
    for (i = 0; i < 16; i++) {
        C += l(B.substring(i, i + 1))
    }
    return C
}
function e(C, M) {
    var P = w(M);
    var L = z(C);
    var D = new Array(32);
    var O = new Array(32);
    var H = new Array(32);
    var K = 0
      , J = 0
      , I = 0
      , G = 0
      , F = 0;
    for (I = 0; I < 32; I++) {
        D[I] = L[I];
        O[I] = L[32 + I]
    }
    for (K = 0; K < 16; K++) {
        for (J = 0; J < 32; J++) {
            H[J] = D[J];
            D[J] = O[J]
        }
        var N = new Array(48);
        for (G = 0; G < 48; G++) {
            N[G] = P[K][G]
        }
        var B = u(t(s(u(x(O), N))), H);
        for (F = 0; F < 32; F++) {
            O[F] = B[F]
        }
    }
    var E = new Array(64);
    for (K = 0; K < 32; K++) {
        E[K] = O[K];
        E[32 + K] = D[K]
    }
    return y(E)
}
function q(C, M) {
    var P = w(M);
    var L = z(C);
    var D = new Array(32);
    var O = new Array(32);
    var H = new Array(32);
    var K = 0
      , J = 0
      , I = 0
      , G = 0
      , F = 0;
    for (I = 0; I < 32; I++) {
        D[I] = L[I];
        O[I] = L[32 + I]
    }
    for (K = 15; K >= 0; K--) {
        for (J = 0; J < 32; J++) {
            H[J] = D[J];
            D[J] = O[J]
        }
        var N = new Array(48);
        for (G = 0; G < 48; G++) {
            N[G] = P[K][G]
        }
        var B = u(t(s(u(x(O), N))), H);
        for (F = 0; F < 32; F++) {
            O[F] = B[F]
        }
    }
    var E = new Array(64);
    for (K = 0; K < 32; K++) {
        E[K] = O[K];
        E[32 + K] = D[K]
    }
    return y(E)
}
function z(C) {
    var B = new Array(64);
    for (i = 0,
    m = 1,
    n = 0; i < 4; i++,
    m += 2,
    n += 2) {
        for (j = 7,
        k = 0; j >= 0; j--,
        k++) {
            B[i * 8 + k] = C[j * 8 + m];
            B[i * 8 + k + 32] = C[j * 8 + n]
        }
    }
    return B
}
function x(B) {
    var C = new Array(48);
    for (i = 0; i < 8; i++) {
        if (i == 0) {
            C[i * 6 + 0] = B[31]
        } else {
            C[i * 6 + 0] = B[i * 4 - 1]
        }
        C[i * 6 + 1] = B[i * 4 + 0];
        C[i * 6 + 2] = B[i * 4 + 1];
        C[i * 6 + 3] = B[i * 4 + 2];
        C[i * 6 + 4] = B[i * 4 + 3];
        if (i == 7) {
            C[i * 6 + 5] = B[0]
        } else {
            C[i * 6 + 5] = B[i * 4 + 4]
        }
    }
    return C
}
function u(D, C) {
    var B = new Array(D.length);
    for (i = 0; i < D.length; i++) {
        B[i] = D[i] ^ C[i]
    }
    return B
}
function s(D) {
    var B = new Array(32);
    var F = "";
    var N = [[14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7], [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8], [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0], [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13]];
    var M = [[15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10], [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5], [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15], [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9]];
    var L = [[10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8], [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1], [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7], [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12]];
    var K = [[7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15], [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9], [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4], [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14]];
    var J = [[2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9], [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6], [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14], [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3]];
    var I = [[12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11], [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8], [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6], [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13]];
    var H = [[4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1], [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6], [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2], [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12]];
    var G = [[13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7], [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2], [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8], [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11]];
    for (m = 0; m < 8; m++) {
        var E = 0
          , C = 0;
        E = D[m * 6 + 0] * 2 + D[m * 6 + 5];
        C = D[m * 6 + 1] * 2 * 2 * 2 + D[m * 6 + 2] * 2 * 2 + D[m * 6 + 3] * 2 + D[m * 6 + 4];
        switch (m) {
        case 0:
            F = A(N[E][C]);
            break;
        case 1:
            F = A(M[E][C]);
            break;
        case 2:
            F = A(L[E][C]);
            break;
        case 3:
            F = A(K[E][C]);
            break;
        case 4:
            F = A(J[E][C]);
            break;
        case 5:
            F = A(I[E][C]);
            break;
        case 6:
            F = A(H[E][C]);
            break;
        case 7:
            F = A(G[E][C]);
            break
        }
        B[m * 4 + 0] = parseInt(F.substring(0, 1));
        B[m * 4 + 1] = parseInt(F.substring(1, 2));
        B[m * 4 + 2] = parseInt(F.substring(2, 3));
        B[m * 4 + 3] = parseInt(F.substring(3, 4))
    }
    return B
}
function t(C) {
    var B = new Array(32);
    B[0] = C[15];
    B[1] = C[6];
    B[2] = C[19];
    B[3] = C[20];
    B[4] = C[28];
    B[5] = C[11];
    B[6] = C[27];
    B[7] = C[16];
    B[8] = C[0];
    B[9] = C[14];
    B[10] = C[22];
    B[11] = C[25];
    B[12] = C[4];
    B[13] = C[17];
    B[14] = C[30];
    B[15] = C[9];
    B[16] = C[1];
    B[17] = C[7];
    B[18] = C[23];
    B[19] = C[13];
    B[20] = C[31];
    B[21] = C[26];
    B[22] = C[2];
    B[23] = C[8];
    B[24] = C[18];
    B[25] = C[12];
    B[26] = C[29];
    B[27] = C[5];
    B[28] = C[21];
    B[29] = C[10];
    B[30] = C[3];
    B[31] = C[24];
    return B
}
function y(B) {
    var C = new Array(64);
    C[0] = B[39];
    C[1] = B[7];
    C[2] = B[47];
    C[3] = B[15];
    C[4] = B[55];
    C[5] = B[23];
    C[6] = B[63];
    C[7] = B[31];
    C[8] = B[38];
    C[9] = B[6];
    C[10] = B[46];
    C[11] = B[14];
    C[12] = B[54];
    C[13] = B[22];
    C[14] = B[62];
    C[15] = B[30];
    C[16] = B[37];
    C[17] = B[5];
    C[18] = B[45];
    C[19] = B[13];
    C[20] = B[53];
    C[21] = B[21];
    C[22] = B[61];
    C[23] = B[29];
    C[24] = B[36];
    C[25] = B[4];
    C[26] = B[44];
    C[27] = B[12];
    C[28] = B[52];
    C[29] = B[20];
    C[30] = B[60];
    C[31] = B[28];
    C[32] = B[35];
    C[33] = B[3];
    C[34] = B[43];
    C[35] = B[11];
    C[36] = B[51];
    C[37] = B[19];
    C[38] = B[59];
    C[39] = B[27];
    C[40] = B[34];
    C[41] = B[2];
    C[42] = B[42];
    C[43] = B[10];
    C[44] = B[50];
    C[45] = B[18];
    C[46] = B[58];
    C[47] = B[26];
    C[48] = B[33];
    C[49] = B[1];
    C[50] = B[41];
    C[51] = B[9];
    C[52] = B[49];
    C[53] = B[17];
    C[54] = B[57];
    C[55] = B[25];
    C[56] = B[32];
    C[57] = B[0];
    C[58] = B[40];
    C[59] = B[8];
    C[60] = B[48];
    C[61] = B[16];
    C[62] = B[56];
    C[63] = B[24];
    return C
}
function A(B) {
    var C = "";
    switch (B) {
    case 0:
        C = "0000";
        break;
    case 1:
        C = "0001";
        break;
    case 2:
        C = "0010";
        break;
    case 3:
        C = "0011";
        break;
    case 4:
        C = "0100";
        break;
    case 5:
        C = "0101";
        break;
    case 6:
        C = "0110";
        break;
    case 7:
        C = "0111";
        break;
    case 8:
        C = "1000";
        break;
    case 9:
        C = "1001";
        break;
    case 10:
        C = "1010";
        break;
    case 11:
        C = "1011";
        break;
    case 12:
        C = "1100";
        break;
    case 13:
        C = "1101";
        break;
    case 14:
        C = "1110";
        break;
    case 15:
        C = "1111";
        break
    }
    return C
}
function w(D) {
    var F = new Array(56);
    var G = new Array();
    G[0] = new Array();
    G[1] = new Array();
    G[2] = new Array();
    G[3] = new Array();
    G[4] = new Array();
    G[5] = new Array();
    G[6] = new Array();
    G[7] = new Array();
    G[8] = new Array();
    G[9] = new Array();
    G[10] = new Array();
    G[11] = new Array();
    G[12] = new Array();
    G[13] = new Array();
    G[14] = new Array();
    G[15] = new Array();
    var B = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];
    for (E = 0; E < 7; E++) {
        for (j = 0,
        k = 7; j < 8; j++,
        k--) {
            F[E * 8 + j] = D[8 * k + E]
        }
    }
    var E = 0;
    for (E = 0; E < 16; E++) {
        var I = 0;
        var C = 0;
        for (j = 0; j < B[E]; j++) {
            I = F[0];
            C = F[28];
            for (k = 0; k < 27; k++) {
                F[k] = F[k + 1];
                F[28 + k] = F[29 + k]
            }
            F[27] = I;
            F[55] = C
        }
        var H = new Array(48);
        H[0] = F[13];
        H[1] = F[16];
        H[2] = F[10];
        H[3] = F[23];
        H[4] = F[0];
        H[5] = F[4];
        H[6] = F[2];
        H[7] = F[27];
        H[8] = F[14];
        H[9] = F[5];
        H[10] = F[20];
        H[11] = F[9];
        H[12] = F[22];
        H[13] = F[18];
        H[14] = F[11];
        H[15] = F[3];
        H[16] = F[25];
        H[17] = F[7];
        H[18] = F[15];
        H[19] = F[6];
        H[20] = F[26];
        H[21] = F[19];
        H[22] = F[12];
        H[23] = F[1];
        H[24] = F[40];
        H[25] = F[51];
        H[26] = F[30];
        H[27] = F[36];
        H[28] = F[46];
        H[29] = F[54];
        H[30] = F[29];
        H[31] = F[39];
        H[32] = F[50];
        H[33] = F[44];
        H[34] = F[32];
        H[35] = F[47];
        H[36] = F[43];
        H[37] = F[48];
        H[38] = F[38];
        H[39] = F[55];
        H[40] = F[33];
        H[41] = F[52];
        H[42] = F[45];
        H[43] = F[41];
        H[44] = F[49];
        H[45] = F[35];
        H[46] = F[28];
        H[47] = F[31];
        switch (E) {
        case 0:
            for (m = 0; m < 48; m++) {
                G[0][m] = H[m]
            }
            break;
        case 1:
            for (m = 0; m < 48; m++) {
                G[1][m] = H[m]
            }
            break;
        case 2:
            for (m = 0; m < 48; m++) {
                G[2][m] = H[m]
            }
            break;
        case 3:
            for (m = 0; m < 48; m++) {
                G[3][m] = H[m]
            }
            break;
        case 4:
            for (m = 0; m < 48; m++) {
                G[4][m] = H[m]
            }
            break;
        case 5:
            for (m = 0; m < 48; m++) {
                G[5][m] = H[m]
            }
            break;
        case 6:
            for (m = 0; m < 48; m++) {
                G[6][m] = H[m]
            }
            break;
        case 7:
            for (m = 0; m < 48; m++) {
                G[7][m] = H[m]
            }
            break;
        case 8:
            for (m = 0; m < 48; m++) {
                G[8][m] = H[m]
            }
            break;
        case 9:
            for (m = 0; m < 48; m++) {
                G[9][m] = H[m]
            }
            break;
        case 10:
            for (m = 0; m < 48; m++) {
                G[10][m] = H[m]
            }
            break;
        case 11:
            for (m = 0; m < 48; m++) {
                G[11][m] = H[m]
            }
            break;
        case 12:
            for (m = 0; m < 48; m++) {
                G[12][m] = H[m]
            }
            break;
        case 13:
            for (m = 0; m < 48; m++) {
                G[13][m] = H[m]
            }
            break;
        case 14:
            for (m = 0; m < 48; m++) {
                G[14][m] = H[m]
            }
            break;
        case 15:
            for (m = 0; m < 48; m++) {
                G[15][m] = H[m]
            }
            break
        }
    }
    return G
}
o("PASSWORD")
''';
