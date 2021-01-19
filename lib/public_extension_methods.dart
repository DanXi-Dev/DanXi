extension StringEx on String {
  String between(String a, String b, {bool headGreedy = true}) {
    if (indexOf(a) < 0) return null;
    if (headGreedy) {
      if (indexOf(b, indexOf(a) + a.length) < 0) return null;
      return substring(
          indexOf(a) + a.length, indexOf(b, indexOf(a) + a.length));
    } else {
      if (indexOf(b, lastIndexOf(a) + a.length) < 0) return null;
      return substring(
          lastIndexOf(a) + a.length, indexOf(b, lastIndexOf(a) + a.length));
    }
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
