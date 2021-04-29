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

import 'package:catcher/catcher.dart';
import 'package:catcher/model/platform_type.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';

class FirebaseHandler extends ReportHandler {
  static FirebaseCrashlytics crashlytics;

  static initFirebase() async {
    if (PlatformX.isMobile) {
      await Firebase.initializeApp();
      crashlytics = FirebaseCrashlytics.instance;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  }

  @override
  List<PlatformType> getSupportedPlatforms() {
    return [PlatformType.android, PlatformType.iOS];
  }

  @override
  Future<bool> handle(Report error, BuildContext context) async {
    if (crashlytics != null) {
      await crashlytics.recordError(error.error, error.stackTrace);
    }
    return true;
  }
}
