import testNapi from 'libentry.so';
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        console.info('EntryAbility onCreate');
        testNapi.registerWatcher();
    }

    onDestroy(): void {
        console.info('EntryAbility onDestroy');
        testNapi.destroyWatcher();
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

@Entry
@Component
struct Index {
    build() {
        RelativeContainer() {
            Column() {
                Button("Trigger Freeze Warning")
                    .width('75%')
                    .height(50)
                    .margin(15)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .onClick(() => {
                        const t = Date.now();
                        while (Date.now() - t <= 6500) {}
                    })
            }
            .width('100%')
        }
        .height('100%')
        .width('100%')
    }
}