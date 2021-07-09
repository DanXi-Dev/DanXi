import 'package:flutter/widgets.dart';

const kTabletMasterContainerWidth = 350.0;

bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width >= 768.0;
}
