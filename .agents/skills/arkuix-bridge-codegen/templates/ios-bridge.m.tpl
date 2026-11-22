// Bridge{{name}}.m — 六件套⑤：iOS BridgePlugin 实现
// 注册：经 StageViewController 的 bridgeManager 创建
#import "Bridge{{name}}.h"

@implementation Bridge{{name}}

- (instancetype)initBridgePlugin:(NSString*)bridgeName bridgeManager:(BridgePluginManager*)bridgeManager {
    self = [super initBridgePlugin:bridgeName bridgeManager:bridgeManager];
    return self;
}

{{methodImpls}}

@end
