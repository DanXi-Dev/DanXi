import { FlutterEntry, FlutterPage, FlutterView } from '@ohos/flutter_ohos';
import { hilog } from '@kit.PerformanceAnalysisKit';
class RouteParams {
  route: Object = '/home';
  toRecord(): Record<string, Object> {
    let record: Record<string, Object> = {};
    record['route'] = this.route;
    return record;
  }
}

@Entry
@Component
struct Index {
  private flutterEntry: FlutterEntry | null = null;
  private flutterView?: FlutterView;
  @State private flutterViewId: string = '';

  aboutToAppear() {
    this.flutterEntry = new FlutterEntry(getContext(this), new RouteParams().toRecord());
    this.flutterEntry.aboutToAppear()
    this.flutterView = this.flutterEntry.getFlutterView()
    this.flutterViewId = this.flutterView.getId()
    hilog.info(0x0000, 'Harmony', `Index aboutToAppear, flutterViewId=${this.flutterViewId}`)
  }

  aboutToDisappear() {
    hilog.info(0x0000, 'Harmony', 'Index aboutToDisappear')
    this.flutterEntry?.aboutToDisappear()
  }

  onPageShow() {
    hilog.info(0x0000, 'Harmony', 'Index onPageShow')
    this.flutterEntry?.onPageShow()
  }

  onPageHide() {
    hilog.info(0x0000, 'Harmony', 'Index onPageHide')
    this.flutterEntry?.onPageHide()
  }

  build() {
    Stack() {
      FlutterPage({ viewId: this.flutterViewId })
    }
    .width('100%')
    .height('100%')
  }
}
