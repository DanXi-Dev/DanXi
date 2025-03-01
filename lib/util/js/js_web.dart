/*
 *     Copyright (C) 2022  DanXi-Dev
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

// fixme: json_serializable conflicts with @JS() annotation in [dart:js_interop]. (https://github.com/google/json_serializable.dart/issues/1391, https://github.com/google/json_serializable.dart/issues/1480)
// As a workaround, we use the dart:_js_annotations library directly. It should be replaced with [dart:js_interop] when the issue is resolved.
// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_annotations' as js;

@js.JS()
external dynamic eval(dynamic arg);

String evaluate(String jsCode) {
  return eval(jsCode).toString();
}
