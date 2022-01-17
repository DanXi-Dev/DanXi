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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A simple error page, usually shown as full-screen.
class ErrorPageWidget extends StatelessWidget {
  final Widget? icon;
  final String buttonText;
  final String errorMessage;
  final dynamic error;
  final StackTrace? trace;
  final VoidCallback? onTap;

  const ErrorPageWidget(
      {Key? key,
      this.icon,
      required this.buttonText,
      required this.errorMessage,
      this.onTap,
      this.error,
      this.trace})
      : super(key: key);

  /// Try to parse error information from [error].
  static String generateUserFriendlyDescription(S locale, dynamic error,
      {StackTrace? stackTrace}) {
    if (error == null) return locale.unknown_error;
    String errorType = error.toString();

    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.connectTimeout:
        case DioErrorType.sendTimeout:
        case DioErrorType.receiveTimeout:
          errorType = locale.connection_timeout;
          break;
        case DioErrorType.response:
          try {
            errorType = error.response?.data['message'];
          } catch (ignored) {
            errorType = locale.response_error +
                (error.response?.statusCode?.toString() ??
                    locale.unknown_error);
          }
          break;
        case DioErrorType.cancel:
          errorType = locale.connection_cancelled;
          break;
        case DioErrorType.other:
          return generateUserFriendlyDescription(locale, error.error);
          break;
      }
    } else if (error is StateError) {
      switch (error.message) {
        case 'No element':
          errorType = locale.no_data_error;
          break;
      }
    } else if (error is NotLoginError) {
      errorType = locale.require_login;
    } else if (error is FormatException) {
      errorType = locale.format_exception;
    } else if (error is ArgumentError) {
      if (error.message is String &&
          error.message.contains("must return a value of the future's type")) {
        errorType = locale.no_data_error;
      }
    }
    return errorType;
  }

  factory ErrorPageWidget.buildWidget(BuildContext context, dynamic error,
      {StackTrace? stackTrace, String? buttonText, VoidCallback? onTap}) {
    buttonText ??= S.of(context).retry;
    return ErrorPageWidget(
        buttonText: buttonText,
        errorMessage: generateUserFriendlyDescription(S.of(context), error,
            stackTrace: stackTrace),
        error: error,
        trace: stackTrace,
        onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(height: 8)],
          Text(errorMessage),
          const SizedBox(height: 8),
          PlatformElevatedButton(
            child: Text(buttonText),
            onPressed: onTap,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            PlatformTextButton(
              child: Text(S.of(context).error_detail),
              onPressed: () {
                String errorInfo = error.toString();
                // DioError will insert its stack trace in the result of [toString] method.
                if (trace != null && error is! DioError) {
                  errorInfo += ("\n$trace");
                }
                Noticing.showModalNotice(context,
                    title: S.of(context).error_detail, message: errorInfo);
              },
            )
          ],
        ],
      ),
    );
  }
}
