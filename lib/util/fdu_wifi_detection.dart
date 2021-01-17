class FDUWiFiConverter {
  static const WIFI_MAP = {
    "iFudan.stu": "宿舍区公共开放付费热点",
    "iFudan.stu.1x": "宿舍区公共加密付费热点",
    "iFudan": "教学区公共开放热点",
    "iFudan.1x": "教学区公共加密热点",
    "iFudanNG.1x": "教学区公共(下一代)加密热点",
    "iSJTU.stu": "405寝室热点",
    "eduroam": "Eduroam 全球漫游服务热点"
  };

  static String recognizeWiFi(String wifiName) {
    if (wifiName == null || wifiName.length == 0) {
      return "未知热点";
    } else {
      return WIFI_MAP.containsKey(wifiName)
          ? WIFI_MAP[wifiName]
          : "$wifiName (未识别热点)";
    }
  }
}
