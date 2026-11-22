// Bridge{{name}}.h — 六件套⑤：iOS BridgePlugin 头文件
// 基于libarkui_ios.framework/Headers/BridgePlugin.h
#import <Foundation/Foundation.h>
#import "BridgePlugin.h"

@interface Bridge{{name}} : BridgePlugin

// 方法名与③ArkUIX.ets 的 callMethod methodName 对应（①{{name}}Interface 契约派生；多参选择器为 name:arg2: 形态——接线时按调用侧校正）
{{methodSigs}}

@end
