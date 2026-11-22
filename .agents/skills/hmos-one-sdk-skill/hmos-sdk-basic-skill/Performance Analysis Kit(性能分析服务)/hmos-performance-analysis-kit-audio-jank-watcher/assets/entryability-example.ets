import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        console.info('EntryAbility onCreate');
        
        testNapi.registerAudioJankWatcher();
    }
    
    onDestroy(): void {
        console.info('EntryAbility onDestroy');
        
        testNapi.unregisterAudioJankWatcher();
    }
    
    onWindowStageCreate(windowStage: window.WindowStage): void {
        console.info('EntryAbility onWindowStageCreate');
        
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                console.error('Failed to load content. Cause: ' + JSON.stringify(err));
                return;
            }
            console.info('Succeeded in loading content.');
        });
    }
}