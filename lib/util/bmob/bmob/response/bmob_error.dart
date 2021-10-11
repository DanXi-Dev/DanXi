import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_error.g.dart';

@JsonSerializable()
class BmobError extends Error {
  int? code;
  String? error;

  BmobError(this.code, this.error);

  //此处与类名一致，由指令自动生成代码
  factory BmobError.fromJson(Map<String, dynamic> json) =>
      _$BmobErrorFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobErrorToJson(this);

  String toString() => "BmobError [$code]:" + error!;

  //转化DioError错误为BmobError类型
  static BmobError? convert(e) {
    BmobError? bmobError;

    if (e is BmobError) {
      bmobError = e;
    } else if (e is DioError) {
      DioError dioError = e;
      switch (dioError.type) {
        case DioErrorType.sendTimeout:
          bmobError = BmobError(9015, dioError.message);
          break;
        case DioErrorType.other:
          bmobError = BmobError(9015, dioError.message);
          break;
        case DioErrorType.cancel:
          bmobError = BmobError(9015, dioError.message);
          break;
        case DioErrorType.receiveTimeout:
          bmobError = BmobError(9015, dioError.message);
          break;
        case DioErrorType.response:
          bmobError = BmobError(
              dioError.response!.data['code'], dioError.response!.data['error']);
          break;
        case DioErrorType.connectTimeout:
          bmobError = BmobError(9015, dioError.message);
          break;
      }
    } else {
      bmobError = BmobError(9015, e.toString());
    }

    return bmobError;
  }
}
