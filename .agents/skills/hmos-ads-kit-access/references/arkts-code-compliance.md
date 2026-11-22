# ArkTS 语法合规规范

> 文档ID: arkts-code-compliance
> 来源: arkts-code-compliance.md

---

生成广告代码时，**必须**遵守以下 ArkTS 语法约束，否则会导致编译失败。

## 1. 禁止对象字面量作为类型声明（arkts-no-obj-literals-as-types）

```typescript
// ❌ 错误：对象字面量不能直接用作参数类型
constructor(callbacks?: { onReward?: (type: string, amount: number) => void }) { ... }
new Handler({ onReward: (t, a) => {} })

// ✅ 正确：先定义 interface，再使用
export interface RewardCallbacks {
  onReward?: (type: string, amount: number) => void;
}
constructor(callbacks?: RewardCallbacks) { ... }
const cb: RewardCallbacks = { onReward: (t, a) => {} };
new Handler(cb);
```

**规则**：所有回调参数、构造函数参数中的对象类型，必须先声明为 `interface` 或 `class`，再引用。

## 2. Context 类型必须为 UIAbilityContext

```typescript
// ❌ 错误：Context 是基类，不能直接传给需要 UIAbilityContext 的 API
const context = this.getUIContext().getHostContext();
new advertising.AdLoader(context);  // 编译报错

// ✅ 正确：显式转换为 UIAbilityContext
import { common } from '@kit.AbilityKit';
const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
new advertising.AdLoader(context);
```

**规则**：`getHostContext()` 返回 `Context`，传给 `AdLoader`、`showAd` 等需要 `UIAbilityContext` 的 API 时，必须 `as common.UIAbilityContext` 显式转换。

## 3. 系统资源名称必须存在

```typescript
// ❌ 错误：comp_background_quaternary 不是系统内置资源
.backgroundColor($r('sys.color.comp_background_quaternary'))

// ✅ 正确：使用实际存在的系统资源
.backgroundColor($r('sys.color.comp_background_tertiary'))
```

**规则**：使用 `$r('sys.color.xxx')` 或 `$r('sys.float.xxx')` 时，必须确认资源名称在 HarmonyOS 系统资源中存在。常见可用值：`comp_background_primary`、`comp_background_secondary`、`comp_background_tertiary`、`font_primary`、`font_secondary`、`icon_primary` 等。

## 4. 必须导入 common 命名空间

```typescript
// ❌ 错误：使用 common.UIAbilityContext 但未导入
import { AppStorageV2 } from '@kit.ArkUI';
// 缺少 common 导入 → "Cannot find namespace 'common'"

// ✅ 正确
import { common } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
```

**规则**：任何使用 `common.UIAbilityContext` 的文件，必须显式 `import { common } from '@kit.AbilityKit'`。

## 5. AdLoadListener 和 AdInteractionListener 类型约束

```typescript
// ✅ 正确：这些是系统定义的接口，可以直接赋值对象字面量
const adLoadListener: advertising.AdLoadListener = {
  onAdLoadFailure: (errorCode: number, errorMsg: string) => { },
  onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => { }
};

const interactionListener: advertising.AdInteractionListener = {
  onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => { }
};
```

**规则**：`advertising.AdLoadListener` 和 `advertising.AdInteractionListener` 是系统 SDK 定义的接口，对象字面量赋值给已声明类型的变量是合规的。只有**自定义的**回调参数类型才需要先声明 interface。

## 6. 广告请求失败提示

测试广告位 ID 在以下情况下可能加载失败：
- 设备未登录华为账号
- 设备网络环境受限（企业网络/防火墙）
- 测试广告位 ID 配额耗尽
- 设备区域不支持（部分海外区域）
- 应用未在鲸鸿动能平台注册

**代码中必须处理 `onAdLoadFailure` 回调**，且在广告加载失败时不应阻塞用户正常使用应用的流程。推荐模式：

```typescript
// 开屏广告：超时 + 加载失败都应跳转到主页
onAdLoadFailure: () => { this.navigateToMainPage(); }

// Banner/Native：加载失败时隐藏广告组件（Visibility.None）
onStatusChanged: (status, ad, data) => {
  if (status === 'onAdFail' || status === 'onAdClose') {
    this.adVisible = Visibility.None;
  }
}

// 激励/插屏：加载失败时取消事件订阅，继续正常流程
onAdLoadFailure: () => { this.rewardHandler?.unRegisterPPSReceiver(); }
```

**接入完成后，应向用户明确提示**：
> 测试广告位 ID 可能因设备/网络/区域等因素加载失败，这属于正常现象。正式发布前需在鲸鸿动能媒体服务平台申请正式广告位 ID 替换。
