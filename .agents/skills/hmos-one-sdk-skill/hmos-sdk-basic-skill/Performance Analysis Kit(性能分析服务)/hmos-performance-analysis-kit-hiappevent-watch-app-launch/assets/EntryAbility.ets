import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        console.info('[EntryAbility] onCreate');
        
        testNapi.registerWatcherReceive();
        testNapi.registerWatcherTrigger();
    }

    onDestroy(): void {
        console.info('[EntryAbility] onDestroy');
        
        testNapi.cleanupWatchers();
    }
}