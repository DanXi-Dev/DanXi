extension StringEx on String {
  String between(String a, String b) {
    if (indexOf(a) < 0 || indexOf(b, indexOf(a) + a.length) < 0) return null;
    return substring(indexOf(a) + a.length, indexOf(b, indexOf(a) + a.length));
  }
}

extension MapEx on Map {
  String encodeMap() {
    return keys.map((key) {
      var k = key.toString();
      var v = Uri.encodeComponent(this[key].toString());
      return '$k=$v';
    }).join('&');
  }
}
