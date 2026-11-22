// Bridge{{name}}.java — 六件套④：Android BridgePlugin
// 基于ohos.ace.adapter.capability.bridge.BridgePlugin
// 注册：BridgeManager.getInstance().registerBridgePlugin("{{bridgeName}}", new Bridge{{name}}(context, manager));
package com.arkuix.bridge;

import android.content.Context;
import ohos.ace.adapter.capability.bridge.BridgeManager;
import ohos.ace.adapter.capability.bridge.BridgePlugin;

public class Bridge{{name}} extends BridgePlugin {
    public Bridge{{name}}(Context context, BridgeManager bridgeManager) {
        super(context, "{{bridgeName}}", bridgeManager);
    }

 // 方法名与③ArkUIX.ets 的 callMethod methodName 对应（①{{name}}Interface 契约派生）
{{methodDecls}}
}
