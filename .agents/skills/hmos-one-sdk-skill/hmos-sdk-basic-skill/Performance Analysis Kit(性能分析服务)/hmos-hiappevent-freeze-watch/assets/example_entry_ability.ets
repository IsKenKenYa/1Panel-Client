// example_entry_ability.ets
// ArkTS调用示例 - 在应用启动时注册冻屏事件观察者

import freezeNapi from 'libentry.so';  // 导入Native模块
import hilog from '@ohos.hilog';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'FreezeEventApp';

export default class EntryAbility extends UIAbility {
    // 应用创建时回调
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Application onCreate called');
        
        // 在应用启动时注册冻屏事件观察者
        try {
            freezeNapi.registerFreezeWatcher();  // 注册onReceive模式观察者
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Freeze event watcher registered successfully');
            
            // 如果需要使用onTrigger模式，可以调用：
            // freezeNapi.registerFreezeTriggerWatcher();
            // hilog.info(LOG_DOMAIN, LOG_TAG, 'Freeze trigger watcher registered');
            
        } catch (error) {
            hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to register freeze watcher: %{public}s', 
                        error.message || 'unknown error');
        }
    }
    
    // 应用销毁时回调
    onDestroy(): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Application onDestroy called');
        
        // 应用退出时移除并销毁观察者
        try {
            // 先移除观察者（停止监听）
            freezeNapi.removeFreezeWatcher();
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Freeze watcher removed');
            
            // 然后销毁观察者（释放内存）
            freezeNapi.destroyFreezeWatcher();
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Freeze watcher destroyed and memory released');
            
        } catch (error) {
            hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to cleanup watcher: %{public}s', 
                        error.message || 'unknown error');
        }
    }
    
    // 其他生命周期回调
    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Window stage create');
        
        // 加载主页面
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to load content: %{public}s', err.message);
                return;
            }
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Succeeded in loading content');
        });
    }
}

// ========================================
// index.d.ts 接口定义文件
// ========================================
// 文件位置：entry/src/main/cpp/types/libentry/index.d.ts
// 内容如下：

// export const registerFreezeWatcher: () => void;      // 注册onReceive模式观察者
// export const removeFreezeWatcher: () => void;        // 移除观察者
// export const destroyFreezeWatcher: () => void;       // 销毁观察者
// export const registerFreezeTriggerWatcher: () => void;  // 注册onTrigger模式观察者
// export const removeFreezeTriggerWatcher: () => void;    // 移除观察者
// export const destroyFreezeTriggerWatcher: () => void;   // 销毁观察者

// ========================================
// 注意事项：
// ========================================
// 1. 调用时机：
//    - 建议在 onCreate 时注册观察者
//    - 建议在 onDestroy 时移除并销毁观察者
//
// 2. Native模块导入：
//    - libentry.so 为Native C++模块编译产物
//    - 需在 cpp/types/libentry/index.d.ts 定义接口
//
// 3. 触发冻屏测试：
//    - 可通过代码模拟应用卡顿触发冻屏事件
//    - 在Index.ets中添加测试按钮
//
// 4. 日志查看：
//    - 使用 hilog 查看冻屏事件日志
//    - 日志标签：FreezeEventReceiver 或 FreezeEventTrigger
//    - 可通过 DevEco Studio Log 窗口查看
//
// 5. 错误处理：
//    - 所有Native调用应包裹在 try-catch 中
//    - 检查返回值和错误日志
// ========================================