#import "FlutterProgressDialogPlugin.h"
#import <flutter_progress_dialog/flutter_progress_dialog-Swift.h>

@implementation FlutterProgressDialogPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterProgressDialogPlugin registerWithRegistrar:registrar];
}
@end
