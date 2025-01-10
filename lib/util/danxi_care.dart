import 'package:dan_xi/common/constant.dart';

Future<bool> detectCareWords(String? target) async {
  if (target == null) {
    return false;
  }

  List<String> careWords = await Constant.careWords;

  for (var word in careWords) {
    if (target.contains(word)) {
      return true;
    }
  }

  return false;
}
