import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Button('WatchAppCrash ArkTS&C++')
        .type(ButtonType.Capsule)
        .margin({ top: 20 })
        .backgroundColor('#0D9FFB')
        .width('80%')
        .height('5%')
        .onClick(() => {
          let result: object = JSON.parse('');
        })

      Button('writeEvent ArkTS')
        .type(ButtonType.Capsule)
        .margin({ top: 20 })
        .backgroundColor('#0D9FFB')
        .width('80%')
        .height('5%')
        .onClick(() => {
          let eventParams: Record<string, number> = { 'clickTime': 100 };
          let eventInfo: hiAppEvent.AppEventInfo = {
            domain: 'button',
            name: 'click',
            eventType: hiAppEvent.EventType.BEHAVIOR,
            params: eventParams,
          };
          
          hiAppEvent.write(eventInfo).then(() => {
            hilog.info(0x0000, 'testTag', 'writeEvent ArkTS success');
          }).catch((err: BusinessError) => {
            hilog.error(0x0000, 'testTag', `err.code: ${err.code}, err.message: ${err.message}`);
          });
        })
    }
    .width('100%')
    .height('100%')
  }
}

export function setupButtonWatcher(): void {
  hiAppEvent.addWatcher({
    name: 'ButtonClickWatcher',
    appEventFilters: [{ domain: 'button' }],
    triggerCondition: { row: 1 },
    
    onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
      if (holder == null) {
        hilog.error(0x0000, 'testTag', 'holder is null');
        return;
      }
      
      hilog.info(0x0000, 'testTag', 'HiAppEvent success to read event with onTrigger callback');
      hilog.info(0x0000, 'testTag', `onTrigger: curRow=${curRow}, curSize=${curSize}`);
      
      let eventPkg: hiAppEvent.AppEventPackage | null = null;
      while ((eventPkg = holder.takeNext()) != null) {
        hilog.info(0x0000, 'testTag', `packageId=${eventPkg.packageId}`);
        hilog.info(0x0000, 'testTag', `row=${eventPkg.row}`);
        hilog.info(0x0000, 'testTag', `size=${eventPkg.size}`);
        
        for (const eventInfo of eventPkg.data) {
          hilog.info(0x0000, 'testTag', `eventInfo=${eventInfo}`);
        }
      }
    }
  });
  
  hilog.info(0x0000, 'testTag', 'Button watcher added successfully');
}

export function cleanupButtonWatcher(): void {
  let watcher: hiAppEvent.Watcher = {
    name: 'ButtonClickWatcher'
  };
  hiAppEvent.removeWatcher(watcher);
  hilog.info(0x0000, 'testTag', 'Button watcher removed successfully');
}