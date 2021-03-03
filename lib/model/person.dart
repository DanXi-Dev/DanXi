import 'package:shared_preferences/shared_preferences.dart';

class PersonInfo {
  String id, password, name;

  PersonInfo(this.id, this.password, this.name);

  PersonInfo.createNewInfo(this.id, this.password) {
    name = "";
  }

  factory PersonInfo.fromSharedPreferences(SharedPreferences preferences) {
    return new PersonInfo(preferences.getString("id"),
        preferences.getString("password"), preferences.getString("name"));
  }

  Future<void> saveAsSharedPreferences(SharedPreferences preferences) async {
    await preferences.setString("id", id);
    await preferences.setString("password", password);
    await preferences.setString("name", name);
  }
}
