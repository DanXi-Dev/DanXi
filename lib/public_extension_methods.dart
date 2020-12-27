extension StringEx on String {
  String between(String a, String b) {
    return substring(indexOf(a) + a.length, indexOf(b, indexOf(a) + a.length));
  }
}
