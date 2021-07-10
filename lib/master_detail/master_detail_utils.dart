import 'package:flutter/widgets.dart';

const kTabletMasterContainerWidth = 350.0;

/// TODO: this standard seems unreliable and potentially dangerous. Maybe adding a ratio condition is better.
bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.width >= 768.0;
}
