import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want, launchParam) {
        console.info('[EntryAbility] onCreate');

        testNapi.registerWatcherClickCrash();
        testNapi.registerWatcherCrashEvent();
    }

    onDestroy() {
        console.info('[EntryAbility] onDestroy');
        testNapi.removeWatcherCrash();
        testNapi.destroyWatcherCrash();
    }

    onWindowStageCreate(windowStage) {
        console.info('[EntryAbility] onWindowStageCreate');

        windowStage.loadContent('pages/Index', (err, data) => {
            if (err.code) {
                console.error('Failed to load content. Cause: ' + JSON.stringify(err));
                return;
            }
            console.info('Succeeded in loading content. Data: ' + JSON.stringify(data));
        });
    }

    onWindowStageDestroy() {
        console.info('[EntryAbility] onWindowStageDestroy');
    }

    onForeground() {
        console.info('[EntryAbility] onForeground');
    }

    onBackground() {
        console.info('[EntryAbility] onBackground');
    }
}