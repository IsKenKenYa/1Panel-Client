import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import Window from '@ohos.window';
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want, launchParam) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
        
        testNapi.registerWatcher();
        hilog.info(0x0000, 'testTag', 'App freeze watcher registered');
    }

    onDestroy() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
        
        testNapi.removeWatcher();
        testNapi.destroyWatcher();
        hilog.info(0x0000, 'testTag', 'App freeze watcher cleaned up');
    }

    onWindowStageCreate(windowStage: Window.WindowStage) {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/Index', (err, data) => {
            if (err.code) {
                hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
                return;
            }
            hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
        });
    }

    onWindowStageDestroy() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
    }

    onBackground() {
        hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
    }
}