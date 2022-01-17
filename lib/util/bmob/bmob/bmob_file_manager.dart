import 'dart:io';
import 'bmob_dio.dart';
import 'bmob.dart';
import 'response/bmob_handled.dart';

import 'type/bmob_file.dart';
import 'response/bmob_error.dart';

class BmobFileManager {
  ///文件上传
  ///method:POST
  ///body:文本或者二进制流
  ///Content-Type:不同类型文件使用不同的值
  static Future<BmobFile> upload(File file) async {
    String allPath = file.path;
    int indexSlash = allPath.lastIndexOf("/");
    if (file == null) {
      throw BmobError(9016, "The file is null.");
    }
    if (indexSlash == -1) {
      throw BmobError(9016, "The file's path is available.");
    }
    String fileName = allPath.substring(indexSlash, allPath.length);
    int indexPoint = fileName.indexOf(".");
    bool one = indexPoint < fileName.length - 1;
    bool two = fileName.contains(".");
    bool hasSuffix = one && two;
    if (!hasSuffix) {
      throw BmobError(9016, "The file has no suffix.");
    }

    String path = "${Bmob.BMOB_API_FILE_VERSION}${Bmob.BMOB_API_FILE}$fileName";

    //获取所上传文件的二进制流
    Map responseData =
        await BmobDio.getInstance().upload(path, data: file.readAsBytes());
    BmobFile bmobFile = BmobFile.fromJson(responseData);
    return bmobFile;
  }

  ///文件删除
  ///method:delete
  ///http://bmob-cdn-18925.b0.upaiyun.com/2019/03/25/f425482f73e646a6a425d746764c3b6c.jpg
  static Future<BmobHandled> delete(String url) async {
    if (url == null || url.isEmpty) {
      throw BmobError(9015, "The url is null or empty.");
    }

    String domain = "upaiyun.com";
    int indexDomain = url.indexOf(domain);
    if (indexDomain == -1) {
      throw BmobError(9015, "The url is not a upaiyun's url.");
    }
    int indexHead = indexDomain + domain.length;
    int indexTail = url.length;
    String fileUrl = url.substring(indexHead, indexTail);
    String path =
        "${Bmob.BMOB_API_FILE_VERSION}${Bmob.BMOB_API_FILE}/upyun$fileUrl";

    Map responseData = await BmobDio.getInstance().delete(path);
    BmobHandled bmobHandled = BmobHandled.fromJson(responseData);

    return bmobHandled;
  }
}
