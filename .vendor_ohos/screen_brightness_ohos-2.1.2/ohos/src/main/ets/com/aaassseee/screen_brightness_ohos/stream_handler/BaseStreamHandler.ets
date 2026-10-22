import { Any } from '@ohos/flutter_ohos';
import { StreamHandler, EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

export class BaseStreamHandler implements StreamHandler {
  protected eventSink: EventSink | null = null;

  onListen(args: Any, events: EventSink): void {
    this.eventSink = events;
  }

  onCancel(args: Any): void {
    this.eventSink = null;
  }
}
