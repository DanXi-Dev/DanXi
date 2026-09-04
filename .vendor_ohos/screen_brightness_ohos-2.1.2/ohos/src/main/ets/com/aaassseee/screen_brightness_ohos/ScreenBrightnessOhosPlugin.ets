import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodChannel,
  MethodResult,
  AbilityPluginBinding,
  MethodCallHandler,
  FlutterManager,
  Log,
  EventChannel
} from "@ohos/flutter_ohos";
import settings from '@ohos.settings';
import { window } from "@kit.ArkUI";
import ScreenBrightnessChangedStreamHandler from "./stream_handler/ScreenBrightnessChangedStreamHandler";

const TAG = "ScreenBrightnessOhosPlugin"

export default class ScreenBrightnessOhosPlugin implements FlutterPlugin, MethodCallHandler {
  private methodChannel?: MethodChannel;
  private systemScreenBrightness?: number;
  private applicationScreenBrightness?: number;
  private abilityPluginBinding: AbilityPluginBinding | null = null;
  private mainWindow: window.Window | null = null;
  private systemScreenBrightnessChangedEventChannel?: EventChannel;
  private systemScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler | null = null;
  private applicationScreenBrightnessChangedEventChannel?: EventChannel;
  private applicationScreenBrightnessChangedStreamHandler: ScreenBrightnessChangedStreamHandler | null = null;
  private isAutoReset: boolean = true;
  private isAnimate: boolean = true;

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (!this.mainWindow) {
      this.getWindow();
    }
    switch (call.method) {
      case "getSystemScreenBrightness":
        this.handleGetSystemScreenBrightnessMethodCall(result);
        break;
      case "setSystemScreenBrightness":
        this.handleSetSystemScreenBrightnessMethodCall(call, result);
        break;
      case "getApplicationScreenBrightness":
        this.handleGetApplicationScreenBrightnessMethodCall(result);
        break;
      case "setApplicationScreenBrightness":
        this.handleSetApplicationScreenBrightnessMethodCall(call, result);
        break;
      case "resetApplicationScreenBrightness":
        this.handleResetApplicationScreenBrightnessMethodCall(result);
        break;
      case "hasApplicationScreenBrightnessChanged":
        this.handleHasApplicationScreenBrightnessChangedMethodCall(result);
        break;
      case "isAutoReset":
        this.handleIsAutoResetMethodCall(result);
        break;
      case "setAutoReset":
        this.handleSetAutoResetMethodCall(call, result);
        break;
      case "isAnimate":
        this.handleIsAnimateMethodCall(result);
        break;
      case "setAnimate":
        this.handleSetAnimateMethodCall(call, result);
        break;
      case "canChangeSystemBrightness":
        this.handleCanChangeSystemBrightness(result);
        break;
      default:
        result.notImplemented(); break;
    }
  }

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), "github.com/aaassseee/screen_brightness");
    this.methodChannel.setMethodCallHandler(this);

    this.applicationScreenBrightnessChangedEventChannel = new EventChannel(binding.getBinaryMessenger(),
      "github.com/aaassseee/screen_brightness/application_brightness_changed");

    this.systemScreenBrightnessChangedEventChannel = new EventChannel(binding.getBinaryMessenger(),
      "github.com/aaassseee/screen_brightness/system_brightness_changed");

    try {
      this.systemScreenBrightness = this.getSystemScreenBrightness();
    } catch (e) {
      Log.e(TAG, e);
    }

    const systemStreamHandler = new ScreenBrightnessChangedStreamHandler(null);
    this.systemScreenBrightnessChangedStreamHandler = systemStreamHandler;
    this.systemScreenBrightnessChangedEventChannel.setStreamHandler(systemStreamHandler);

    const applicationStreamHandler = new ScreenBrightnessChangedStreamHandler(null);
    this.applicationScreenBrightnessChangedStreamHandler = applicationStreamHandler;
    this.applicationScreenBrightnessChangedEventChannel.setStreamHandler(applicationStreamHandler);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
  }

  private getWindow(): void {
    this.mainWindow = FlutterManager.getInstance()
      .getWindowStage(FlutterManager.getInstance().getUIAbility(this.abilityPluginBinding?.getAbility().context))
      .getMainWindowSync();
  }

  private getSystemScreenBrightness(): number {
    let value = settings.getValueSync(
      getContext(this),
      settings.display.SCREEN_BRIGHTNESS_STATUS,
      '100',
    );
    return parseFloat(value) / 255;
  }

  private handleGetSystemScreenBrightnessMethodCall(result: MethodResult): void {
    result.success(this.systemScreenBrightness);
  }

  private handleSetSystemScreenBrightnessMethodCall(call: MethodCall, result: MethodResult) {
    result.error("-1", "Unable to change system screen brightness", null);
  }

  private handleGetApplicationScreenBrightnessMethodCall(result: MethodResult): void {
    let brightness = this.mainWindow?.getWindowProperties().brightness;
    if (brightness != undefined && brightness >= 0) {
      result.success(brightness);
      return;
    }

    try {
      brightness = this.getSystemScreenBrightness();
      result.success(brightness);
    } catch (e) {
      result.error("-11", "Could not found application screen brightness", null);
    }
  }

  private handleSetApplicationScreenBrightnessMethodCall(call: MethodCall, result: MethodResult): void {
    let brightness = parseFloat(call.argument("brightness"))
    if (brightness == null) {
      result.error("-2", "Unexpected error on null brightness", null);
      return;
    }
    try {
      this.mainWindow?.setWindowBrightness(brightness);
      this.applicationScreenBrightness = this.mainWindow?.getWindowProperties().brightness;
      this.handleApplicationScreenBrightnessChanged(brightness);
      result.success(null);
    } catch (e) {
      result.error("-1", "Unable to change application screen brightness", null);
    }
  }

  private handleResetApplicationScreenBrightnessMethodCall(result: MethodResult): void {
    try {
      this.mainWindow?.setWindowBrightness(-1);
      this.applicationScreenBrightness = -1;
      this.handleApplicationScreenBrightnessChanged(this.systemScreenBrightness!);
      result.success(null);
    } catch (e) {
      result.error("-1", "Unable to change application screen brightness", null);
    }
  }

  private handleApplicationScreenBrightnessChanged(brightness: number) {
    this.applicationScreenBrightnessChangedStreamHandler?.addScreenBrightnessToEventSink(brightness);
  }

  private handleHasApplicationScreenBrightnessChangedMethodCall(result: MethodResult) {
    result.success(this.applicationScreenBrightness != null);
  }

  private handleIsAutoResetMethodCall(result: MethodResult) {
    result.success(this.isAutoReset)
  }

  private handleSetAutoResetMethodCall(call: MethodCall, result: MethodResult) {
    let isAutoReset: boolean = call.argument("isAutoReset");
    if (isAutoReset == null) {
      result.error("-2", "Unexpected error on null isAutoReset", null);
      return;
    }

    this.isAutoReset = isAutoReset;
    result.success(null);
  }

  private handleIsAnimateMethodCall(result: MethodResult) {
    result.success(this.isAnimate);
  }

  private handleSetAnimateMethodCall(call: MethodCall, result: MethodResult) {
    let isAnimate: boolean = call.argument("isAnimate");
    if (isAnimate == null) {
      result.error("-2", "Unexpected error on null isAnimate", null);
      return;
    }

    this.isAnimate = isAnimate;
    result.success(null);
  }

  private handleCanChangeSystemBrightness(result: MethodResult): void {
    result.success(false);
  }
}
