import '../data_plugin.dart';
import 'bmob_query.dart';
import 'table/bmob_installation.dart';

class BmobInstallationManager {
  static Future<String> getInstallationId() async {
    var installationId = await DataPlugin.installationId;
    return installationId;
  }

  static Future<BmobInstallation> init() async {
    String installationId = await getInstallationId();
    BmobQuery<BmobInstallation> bmobQuery = BmobQuery();
    bmobQuery.addWhereEqualTo("installationId", installationId);

    List<dynamic> responseData = await bmobQuery.queryInstallations();
    List<BmobInstallation> installations =
        responseData.map((i) => BmobInstallation.fromJson(i)).toList();

    if (installations.isNotEmpty) {
      BmobInstallation installation = installations[0];
      return installation;
    } else {
      BmobInstallation bmobInstallation = BmobInstallation();
      bmobInstallation.installationId = installationId;
      bmobInstallation.save();
      return bmobInstallation;
    }
  }
}
