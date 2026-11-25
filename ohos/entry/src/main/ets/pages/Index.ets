
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { FlutterPage } from '@ohos/flutter_ohos';
import { HarmonyNativeShell } from '../native_ui/HarmonyNativeShell';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';

@Entry(storage)
@Component
struct Index {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = '';
  @StorageLink('harmonyNativeVisible') @Watch('nativeVisibilityChanged') private nativeVisible: boolean = false;
  @State private nativeMounted: boolean = false;

  aboutToAppear(): void {
    this.nativeVisibilityChanged();
  }

  private nativeVisibilityChanged(): void {
    if (this.nativeVisible) {
      this.nativeMounted = true;
    }
  }

  build() {
    Stack() {
      FlutterPage({ viewId: this.viewId, shouldPauseWhenInvisible: false })
        .width('100%')
        .height('100%')
        .visibility(this.nativeVisible ? Visibility.Hidden : Visibility.Visible)
      if (this.nativeMounted) {
        if (deviceInfo.apiAvailable('26.0.0')) {
          HarmonyNativeShell()
            .visibility(this.nativeVisible ? Visibility.Visible : Visibility.Hidden)
        }
      }
    }
    .width('100%')
    .height('100%')
  }

  onBackPress(): boolean {
    if (this.nativeVisible) {
      return false;
    }
    this.context.eventHub.emit(EVENT_BACK_PRESS);
    return true;
  }
}
