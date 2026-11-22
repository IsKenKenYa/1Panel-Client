# 六件套范式模版（agent 参照基准——生成/补全/审查时对齐，勿偏离）

> 定位：ArkUI-X 桥接产物的**唯一范式基准**。任何 agent 为本工具族生成、补全、代填或审查桥接代码时，
> 先读本模版对齐形态，再动手。出处：ArkUI-X docs《跨平台Bridge最佳实践》Camera 范式 + SDK 26.0.0 三方实证。
> 硬约束：偏离本范式的产物 = 审查不通过（F3  自检 + 本模版双闸）。

## 一、整体架构（一码三平台）

```
业务调用点（零平台感知）
    │  import { XxxImpl } from '<commons-har>';
    │  XxxImpl.getInterface().method(...)
    ▼
⑥ XxxImpl（平台分发器）
    ├─ Android/iOS ──→ ③ XxxArkUIX（class，Bridge.createBridge + callMethod）
    │                      │  ArkUI-X 跨语言桥
    │                      ├─→ ④ BridgeXxx.java（extends BridgePlugin）
    │                      └─→ ⑤ BridgeXxx.h/.m（: BridgePlugin）
    └─ HarmonyOS ───→ ② XxxLocal（class，直调 @ohos.*）
① XxxInterface（契约，②③共同 implements——签名唯一真相源）
```

## 二、目录与命名（相对工程根）

```
commons/<module-har>/
├── Index.ets                        # HAR 导出（namespace 镜像）
├── oh-package.json5                 # HAR 声明（name=模块名下划线小写）
├── build-profile.json5 / hvigorfile.ts / src/main/module.json5
└── src/main/ets/
    ├── interface/XxxInterface.ets   # ①
    ├── impl/XxxImpl.ets             # ⑥
    └── utils/
        ├── XxxLocal.ets             # ②
        ├── XxxArkUIX.ets            # ③
        └── PlatformInfo.ets         # 工程级件（每 HAR 一份分发，import '../utils/PlatformInfo'）
.arkui-x/android/.../bridge/BridgeXxx.java    # ④
.arkui-x/ios/app/BridgeSrc/BridgeXxx.h/.m     # ⑤
```

命名规则：`Xxx` = 接口名（bridgeName）；HAR 目录 = 模块名去 `@ohos.` 前缀、`-`→`_` 小写（`multimedia-camera`→`multimedia_camera`）；Java/ObjC 类 = `Bridge` + bridgeName。

## 三、各件形态模版（金标准）

### ① Interface（契约——签名唯一真相源）

```typescript
import Bridge from '@arkui-x.bridge';

export interface XxxInterface {
  method(paramName: string, other: number): Promise<Bridge.ResultValue>;  // 返回恒为 Promise<Bridge.ResultValue>（③callMethod 的 Bridge 契约形态）
}
```

**不变式**：
- 方法集 = SDK d.ts 声明面（namespace 函数 + 入口对象接口方法）∪ 源码调用面 ∪ Local 调用面——**优先 d.ts 声明面**（真实方法名/参数名）
- 参数类型限 Bridge 可映射集：`string | number | boolean | ESObject`（非可映射一律 ESObject——由签名检查"需人工"通道兜底）
- ②③④⑤⑥ 的签名**全部由本契约派生**——禁止任何一侧自行发明签名

### ② Local（HarmonyOS 端实现——直调 @ohos.*）

```typescript
import Bridge from '@arkui-x.bridge';
import { XxxInterface } from '../interface/XxxInterface';
import <ns> from '@ohos.<module>';    // kit import 必须已改写为 @ohos 直导入（@kit.* 在 ArkUI-X 编译集不可解析）

export class XxxLocal implements XxxInterface {
  private static instance: XxxLocal;
  public static getInstance(): XxxLocal {
    if (!XxxLocal.instance) { XxxLocal.instance = new XxxLocal(); }
    return XxxLocal.instance;
  }
  public method(paramName: string): Promise<Bridge.ResultValue> {
    // 迁移原语句（源工程 <file:line>）——参数/返回值接线待补：
    <原语句整体（多行嵌套回调保持完整）>
    return Promise.resolve(null);     // 保底返回（方法可编译）；接线后换真实返回
  }
}
```

**不变式**：class implements ①；单例；方法体 = 源工程原语句**整体平铺**（括号平衡）；未匹配方法的语句进类尾"未分派原语句"参考块；**本文件已存在则增量再生成不覆盖**（手改区语义）。

**外围作用域收割**——方法体语句引用的源工程外围标识符按来源分类带入文件头部：
- `@ohos.*` 直导入 → 原样（kit import 自动改写为 @ohos）
- 模块名导入（`'sample_common'`）→ 原样 + `// [MIG] 模块名导入——需在 HAR 的 oh-package 声明该依赖`
- 相对路径导入（`'../model/X'`）→ 注释行 `// [MIG] ... 相对源工程路径，接线时按 HAR 内位置改写或迁入依赖`（HAR 内路径无效，不静默带错路径）
- 本地 const 字面量（`const TAG = 'X'`）→ `const TAG = 'X'; // [MIG] 源工程本地常量内联`（就地解析）
- 均未命中 → `// [MIG] 未解析标识符（源工程外围作用域——接线时补）: A, B`
接线时按 [MIG] 注释逐条处理——注释即工单，不留静默缺口。

### ③ ArkUIX（桥接实现——Android/iOS 分支）

```typescript
import Bridge from '@arkui-x.bridge';
import { XxxInterface } from '../interface/XxxInterface';

export class XxxArkUIX implements XxxInterface {
  private static instance: XxxArkUIX;
  private static bridgeImpl: Bridge.BridgeObject;
  public static getInstance(): XxxArkUIX {
    if (!XxxArkUIX.instance) {
      XxxArkUIX.instance = new XxxArkUIX();
      XxxArkUIX.bridgeImpl = Bridge.createBridge('Xxx');
    }
    return XxxArkUIX.instance;
  }
  public method(paramName: string): Promise<Bridge.ResultValue> {
    return XxxArkUIX.bridgeImpl.callMethod('method', paramName);   // methodName 与④⑤方法名严格一致
  }
}
```

**不变式**：单例持 bridge 实例；`callMethod('<name>', ...)` 的 name = ④Java/⑤ObjC 方法名（跨三端一致）；参数透传①签名形参。

### ⑥ Impl（平台分发器）

```typescript
import { PlatformInfo, PlatformTypeEnum } from '../utils/PlatformInfo';   // HAR 内层级（非 ../../）
import { XxxInterface } from '../interface/XxxInterface';
import { XxxArkUIX } from '../utils/XxxArkUIX';
import { XxxLocal } from '../utils/XxxLocal';

export class XxxImpl {
  public static getInterface(): XxxInterface {
    const platform = PlatformInfo.getPlatform();
    if (platform === PlatformTypeEnum.ANDROID || platform === PlatformTypeEnum.IOS) {
      return XxxArkUIX.getInstance();
    }
    return XxxLocal.getInstance();
  }
}
```

**不变式**：静态 `getInterface()` 返回①类型；平台判断**只用 PlatformInfo**（`@ohos.deviceInfo.osFullName`）——禁止业务码内散布 `canIUse`/设备判断分流。

### ④ Android BridgePlugin

```java
package com.arkuix.bridge;
import android.content.Context;
import ohos.ace.adapter.capability.bridge.BridgeManager;
import ohos.ace.adapter.capability.bridge.BridgePlugin;

public class BridgeXxx extends BridgePlugin {
    public BridgeXxx(Context context, BridgeManager bridgeManager) {
        super(context, "Xxx", bridgeManager);     // bridgeName 与③ createBridge 一致
    }
    // 每契约方法一个 public 方法（方法名=③callMethod name；类型映射 string→String/number→double/boolean→boolean/ESObject→Object）
    public String method(String paramName) {
// ARKUIX-BRIDGE-HANDOFF BEGIN
 // 等价原生 API：android.xxx（来自 native-api-map 策展；未收录则 TODO 三要素）
 // TODO(ARKUIX-BRIDGE): interface=Xxx platform=android category=equivalent_bridge — 业务逻辑待开发者补齐
// ARKUIX-BRIDGE-HANDOFF END
        return null;
    }
}
```

**不变式**：构造子 `(Context, String, BridgeManager)`；注册经 `BridgeRegistry.registerAll`（集中注册件，宿主 onCreate 一句调用）；**围栏内是手改区**——增量再生成不覆盖；native-api-map 条目含 `min_android` 时围栏内渲染 `// 最低版本要求：Android …`（低于此版本需升级开发环境或调整适配方案；未标注适用 F1 platform_baseline 工程基线）。

### ⑤ iOS BridgePlugin

```objc
// BridgeXxx.h
#import <Foundation/Foundation.h>
#import "BridgePlugin.h"
@interface BridgeXxx : BridgePlugin
- (NSString*)method:(NSString*)paramName;              // 多参选择器 method:arg2: 形态
- (NSString*)on:(NSString*)type arg2:(id)callback;
@end

// BridgeXxx.m
@implementation BridgeXxx
- (instancetype)initBridgePlugin:(NSString*)bridgeName bridgeManager:(BridgePluginManager*)bridgeManager {
    self = [super initBridgePlugin:bridgeName bridgeManager:bridgeManager];
    return self;
}
- (NSString*)method:(NSString*)paramName {
#pragma mark ARKUIX-BRIDGE-HANDOFF BEGIN
 // 等价原生 API：iOS xxx（native-api-map 策展）
#pragma mark ARKUIX-BRIDGE-HANDOFF END
    return nil;
}
@end
```

**不变式**：注册经宿主 ViewController `viewDidLoad`（无集中 Registry）；围栏 `#pragma mark` 形态为手改区；native-api-map 条目含 `min_ios` 时围栏内渲染 `// 最低版本要求：iOS …`（语义同④）。

## 四、跨三端一致性清单（agent 自查）

| # | 一致性项 | 校验法 |
|---|---|---|
| 1 | ①方法集 ⊇ ④⑤⑥方法集 = ③ callMethod name 集 | 逐方法名比对 |
| 2 | bridgeName 三端一致（③createBridge / ④super / ⑤initBridgePlugin） | 字符串相等 |
| 3 | 参数个数/顺序一致（①②③④⑤签名同源） | 逐参数比对 |
| 4 | 类型映射表：string→String/NSString、number→double/NSNumber*、boolean→boolean/NSNumber*、ESObject→Object/id | 逐参类型比对 |
| 5 | ②Local 的 kit import 已改写 @ohos 直导入；括号平衡 | netBracketDepth=0 |
| 6 | 围栏成对（BEGIN/END）且只包业务逻辑区 | 围栏计数 |

## 五、机器自检（——产物落盘后自动跑）

`bridge-artifact.json` 的 `audit` 字段：
- **deficient（硬残缺，必补）**：file-missing / interface-thin / local-unbalanced / local-shell / local-placeholder / arkuix-shape / android-shape / ios-shape / impl-shape
- **suggestions（建议级）**：contract-thin（单方法兜底契约）/ contract-incomplete（契约面 < SDK d.ts 声明面——语义覆盖缺口）

**agent 标准动作**：`audit.deficient` 非空 → 按 action 指引读取生成文件与源工程 locations 补全 → 重跑（幂等不覆盖手改区）→ `ace build apk` 编译验证（产物判定，勿信退出码）。

## 六、接线（产物 → 工程）

| 件 | 落位 | 接线动作 |
|---|---|---|
| commons HAR | 工程根 `commons/<har>/` | build-profile 注册 + 业务模块 oh-package `file:<真实相对路径>` 注入 + **Index.ets 恒生成**（导出 namespace 镜像供 rewire 兼容 + ⑥Impl 分发器供模版入口调用）|
| ④ Java | `.arkui-x/android/` 同路径 | 宿主 Activity onCreate：`BridgeRegistry.registerAll(this, BridgeManager.getInstance());` |
| ⑤ ObjC | `.arkui-x/ios/` 同路径 | pbxproj 四段引用 + ViewController 创建实例 |
| 业务调用点 | 源 .ets | `import { XxxImpl }; XxxImpl.getInterface().method()` 替换原 @ohos.* 直调 |

**禁止**：业务码直接 import ②③（绕过分发器 = 平台判断散布）；手改 ①签名（②③④⑤⑥全链失配）。
