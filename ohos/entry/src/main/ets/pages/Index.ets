
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { FlutterPage } from '@ohos/flutter_ohos';
import { HarmonyNativeShell } from '../native_ui/HarmonyNativeShell';
import { HarmonyNativeBridge } from '../native_ui/HarmonyNativeBridge';
import { HarmonyEntryPage } from '../native_ui/onboarding/HarmonyEntryPage';

let storage = LocalStorage.getShared();
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';

@Entry(storage)
@Component
struct Index {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @LocalStorageLink('viewId') viewId: string = '';
  @StorageLink('harmonyNativeVisible') @Watch('nativeVisibilityChanged') private nativeVisible: boolean = false;
  @StorageLink('harmonyEntryPage') private entryPage: string = '';
  @StorageLink('harmonyAppLockVisible') private appLockVisible: boolean = false;
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
      FlutterPage({
        viewId: this.viewId,
        shouldPauseWhenInvisible: false,
        safeAreaTypes: [SafeAreaType.SYSTEM],
        safeAreaEdges: [SafeAreaEdge.BOTTOM],
      })
        .width('100%')
        .height('100%')
        .visibility(this.nativeVisible || this.appLockVisible || this.entryPage.length > 0 ?
          Visibility.Hidden : Visibility.Visible)
      if (this.nativeMounted) {
        if (deviceInfo.apiAvailable('26.0.0')) {
          HarmonyNativeShell()
            .visibility(this.nativeVisible ? Visibility.Visible : Visibility.Hidden)
        }
      }
      if (deviceInfo.apiAvailable('26.0.0')) {
        if (this.appLockVisible) {
          HarmonyEntryPage({ entryPage: 'appLock' })
        } else if (this.entryPage.length > 0) {
          HarmonyEntryPage({ entryPage: this.entryPage })
        }
      }
    }
    .width('100%')
    .height('100%')
  }

  onBackPress(): boolean {
    if (this.appLockVisible) {
      return false;
    }
    if (this.entryPage === 'warning' || this.entryPage === 'authRetry') {
      HarmonyNativeBridge.instance.entryAction(this.entryPage, this.entryPage === 'warning' ? 'exit' : 'cancel');
      return true;
    }
    if (this.nativeVisible) {
      return false;
    }
    this.context.eventHub.emit(EVENT_BACK_PRESS);
    return true;
  }
}
