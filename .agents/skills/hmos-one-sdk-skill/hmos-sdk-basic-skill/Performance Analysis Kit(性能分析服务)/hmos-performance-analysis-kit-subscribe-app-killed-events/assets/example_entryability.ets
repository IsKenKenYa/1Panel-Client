import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import testNapi from 'libentry.so';

const LOG_DOMAIN = 0xFF00;
const LOG_TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onCreate');
        
        testNapi.registerWatcher();
        hilog.info(LOG_DOMAIN, LOG_TAG, 'App killed event watcher registered');
    }

    onDestroy(): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onDestroy');
        
        testNapi.removeWatcher();
        testNapi.destroyWatcher();
        hilog.info(LOG_DOMAIN, LOG_TAG, 'App killed event watcher destroyed');
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/Index', (err, data) => {
            if (err.code) {
                hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to load the content. Cause: %{public}s', 
                    JSON.stringify(err));
                return;
            }
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Succeeded in loading the content. Data: %{public}s',
                JSON.stringify(data));
        });
    }

    onWindowStageDestroy(): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onWindowStageDestroy');
    }

    onForeground(): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onForeground');
    }

    onBackground(): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Ability onBackground');
    }
}