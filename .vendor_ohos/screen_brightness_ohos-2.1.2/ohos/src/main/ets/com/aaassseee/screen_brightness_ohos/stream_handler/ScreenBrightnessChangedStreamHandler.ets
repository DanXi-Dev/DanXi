import { Any } from '@ohos/flutter_ohos';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { BaseStreamHandler } from './BaseStreamHandler';

type OnListenStartCallback = (eventSink: EventSink) => void;

export default class ScreenBrightnessChangedStreamHandler extends BaseStreamHandler {
  private onListenStart: OnListenStartCallback | null;

  constructor(onListenStart: OnListenStartCallback | null) {
    super();
    this.onListenStart = onListenStart;
  }

  onListen(args: Any, events: EventSink): void {
    super.onListen(args, events);
    if (!this.eventSink) {
      return;
    }
    this.onListenStart?.(this.eventSink);
  }

  addScreenBrightnessToEventSink(brightness: number): void {
    if (!this.eventSink) {
      return;
    }
    this.eventSink.success(brightness);
  }
}
