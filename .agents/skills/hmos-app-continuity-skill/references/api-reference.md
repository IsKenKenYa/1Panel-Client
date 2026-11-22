# 应用接续 API 参考

> 数据来源：HarmonyOS 官方文档（API Version 9–26）
> 最后同步：2026-09

> **签名信源纪律（重要）**：实施期间 API 的签名、参数、版本**以本文件和 `assets/examples/*.ets` 为准**，**读取用户本机 SDK 的 d.ts 文件核验签名**仅作为兜底手段，完全不推荐使用——SDK 目录在项目工作区之外，读取需要权限申请且严重拖慢执行流程；官方文档/SDK 版本间的差异本文档已给出兼容写法。签名正确性的最终验证统一走编译检查（步骤 5），不要用 d.ts 对照代替。

---

## 目录

- [1. 核心接口总览](#1-核心接口总览)
- [2. UIAbility 生命周期接口](#2-uiability-生命周期接口)
  - [onContinue](#oncontinue)
  - [onCreate](#oncreate)
  - [onNewWant](#onnew-want)
  - [onWindowStageRestore](#onwindowstagerestore)
- [3. UIAbilityContext 接口](#3-uiabilitycontext-接口)
  - [setMissionContinueState](#setmissioncontinuestate)
  - [restoreWindowStage](#restorewindowstage)
  - [3-B. NavPathStack 接口（Navigation 路由栈，接续相关）](#3-b-navpathstack-接口navigation-路由栈接续相关)
    - [getPathStack](#getpathstack)
    - [setInterception](#setinterception)
- [4. 分布式数据对象 (DDO)](#4-分布式数据对象-ddo)
  - [create](#ddo-create)
  - [genSessionId](#ddo-gensessionid)
  - [setSessionId](#ddo-setsessionid)
  - [save](#ddo-save)
  - [on('status')](#ddo-on-status)
  - [on('change')](#ddo-on-change)
  - [off（注销监听）](#ddo-off-change)
  - [setAsset / setAssets（文件资产传输）](#ddo-asset-transfer)
  - [on('progressChanged')（资产传输进度）](#ddo-on-progress)
- [5. Want 常量](#5-want-常量)
- [6. AbilityConstant 枚举](#6-abilityconstant-枚举)
  - [OnContinueResult](#oncontinueresult)
  - [ContinueState](#continuestate)
  - [LaunchReason](#launchreason)
- [7. API 版本矩阵](#7-api-版本矩阵)
- [8. Want 参数系统预置字段](#8-want-参数系统预置字段)
- [9. 错误码参考](#9-错误码参考)

---

## 1. 核心接口总览

| 接口 | 端 | 作用 | API 版本 |
|------|----|------|----------|
| `module.json5` → `abilities[].continuable: true` | 配置 | 声明 UIAbility 可被接续 | API 9+ |
| `UIAbility.onContinue(wantParam)` | 源端 | 保存待迁移数据，返回同意/拒绝 | API 9+ |
| `UIAbility.onCreate(want, launchParam)` | 目标端 | 冷启动时恢复数据和页面栈 | API 9+ |
| `UIAbility.onNewWant(want, launchParam)` | 目标端 | 热启动时接收新迁移请求 | API 9+ |
| `UIAbility.onWindowStageRestore(windowStage)` | 目标端 | 迁移启动时替代 onWindowStageCreate 的窗口阶段恢复回调 | API 9+ |
| `UIAbilityContext.setMissionContinueState(state, callback)` | 双端 | 动态开启/关闭迁移能力 | API 10+ |
| `UIAbilityContext.restoreWindowStage(localStorage)` | 目标端 | 在 onCreate/onNewWant 执行完成前调用，触发带页面栈的页面恢复 | API 9+ |
| `distributedDataObject.create(context, source)` | 双端 | 创建分布式数据对象 | API 9+ |
| `distributedDataObject.genSessionId()` | 双端 | 生成 DDO 组网 sessionId | API 9+ |
| `DataObject.setSessionId(sessionId, callback)` | 双端 | 加入/退出 DDO 组网 | API 9+ |
| `DataObject.save(deviceId)` | 源端 | 持久化 DDO 数据 | API 9+ |
| `DataObject.on('status', callback)` | 双端 | 监听 DDO 组网状态变化 | API 9+ |
| `DataObject.on('change', callback)` | 双端 | 监听 DDO 数据变更 | API 9+ |
| `wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY` | 源端 | 控制是否迁移页面栈 | API 10+ |
| `wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY` | 源端 | 控制源端是否退出 | API 10+ |

---

## 2. UIAbility 生命周期接口

### 2.1 onContinue <a id="oncontinue"></a>

```typescript
// 同步版本（API 17 及以下）
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult;

// Promise 异步版本（API 18+）
onContinue(wantParam: Record<string, Object>): Promise<AbilityConstant.OnContinueResult>;
```

**说明：**
- 当 UIAbility 准备跨端迁移时在**源端**触发
- 开发者通过 `wantParam` 保存待迁移数据（键值对）
- 返回 `AGREE` 同意迁移，`REJECT` 拒绝迁移，`MISMATCH` 版本不匹配
- **Promise 异步形态版本口径**：官方 API 参考（js-apis-app-ability-uiability）明确标注"API version 18 之前的版本仅支持同步调用；API version 18 及后续版本支持 Promise 异步调用"；
  **实施基线**：运行端 API 18+ 可放心 `await`（DDO/文件场景必须用异步版）；项目 `compatibleSdkVersion` 落在 12–17 时**仅可用同步版** onContinue——把"源端退出后对端可读到 save 数据"列为人工验证项（save 可能未完成即退出），或将 compatible 升至 18+（需用户决策）
- 源端保存的 `wantParam` 由目标端 `onCreate()` / `onNewWant()` 读取恢复（配合 `restoreWindowStage()` 触发页面恢复）
- 元服务 API：从 API 11 起支持
- 系统能力：`SystemCapability.Ability.AbilityRuntime.AbilityCore`
- 该回调中 `wantParam` 内系统预置 `version`（对端应用版本号）和 `targetDevice`（对端设备 networkId）
- 建议 wantParam 传输数据控制在 **100KB 以下**，大数据使用 DDO

**示例（同步）：**

```typescript
import { UIAbility, AbilityConstant } from '@kit.AbilityKit';

export default class MyUIAbility extends UIAbility {
  onContinue(wantParams: Record<string, Object>) {
    console.info('onContinue');
    wantParams['myData'] = 'my1234567';
    return AbilityConstant.OnContinueResult.AGREE;
  }
}
```

**示例（异步 API 18+）：**

```typescript
import { UIAbility, AbilityConstant } from '@kit.AbilityKit';

export default class MyUIAbility extends UIAbility {
  async setWant(wantParams: Record<string, Object>) {
    console.info('setWant start');
    for (let time = 0; time < 1000; ++time) {
      wantParams[time] = time;
    }
    console.info('setWant end');
  }

  async onContinue(wantParams: Record<string, Object>) {
    console.info('onContinue');
    return this.setWant(wantParams).then(() => {
      return AbilityConstant.OnContinueResult.AGREE;
    });
  }
}
```

### 2.2 onCreate <a id="oncreate"></a>

```typescript
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void;
```

**说明：**
- 当 UIAbility 实例创建完成时触发
- **同步接口**，不支持异步回调
- 仅在 UIAbility **冷启动**时触发
- 接续场景下，通过 `launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION` 判断是否为迁移启动
- 若配置了快速启动（`_ContinueQuickStart`），会先收到 `PREPARE_CONTINUATION` 再收到 `CONTINUATION`
- 元服务 API：API 11 起支持

### 2.3 onNewWant <a id="onnew-want"></a>

```typescript
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void;
```

**说明：**
- 当已启动的 UIAbility 实例再次被拉起时触发
- **同步接口**，不支持异步回调
- 接续场景：单实例（`singleton`）应用热启动时进入此回调
- 通过 `launchParam.launchReason` 判断启动原因

### 2.4 onWindowStageRestore <a id="onwindowstagerestore"></a>

```typescript
onWindowStageRestore(windowStage: window.WindowStage): void;
```

**说明：**
- 当 UIAbility **跨端迁移**时，目标端恢复窗口阶段时回调
- 无论是冷启动还是热启动，都会在执行完 `onCreate()` / `onNewWant()` 后触发本回调，**不执行 `onWindowStageCreate()`**
- **镜像原则（官方口径）**：开发者如果在 `onWindowStageCreate()` 中进行了应用启动时必要的初始化，那么迁移后需要在 `onWindowStageRestore()` 中执行**同样的初始化操作**，避免应用异常 → **仅当 `onWindowStageCreate()` 有初始化时才需要重写本回调**，内容为镜像同样的初始化（如窗口属性设置）；无初始化时不添加（最小侵入）
- 页面加载分两种情况：
  - **系统页面栈恢复**（Router 默认）：页面栈已由 `onCreate()`/`onNewWant()` 中调用的 `restoreWindowStage()` 恢复，本回调中**不要 `loadContent`**（会破坏已恢复的页面栈）
  - **禁用页面栈迁移**（`SUPPORT_CONTINUE_PAGE_STACK_KEY = false`，Navigation 必须走此路）：在本回调中 `loadContent()` 加载迁移后进入的页面
- 元服务 API：API 11 起支持
- 系统能力：`SystemCapability.Ability.AbilityRuntime.AbilityCore`

**示例（官方"按需迁移页面栈"模式）：**

```typescript
import { UIAbility, Want, AbilityConstant, wantConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class MyUIAbility extends UIAbility {
  // 源端设置了 SUPPORT_CONTINUE_PAGE_STACK_KEY = false 时目标端读回 false
  private isPageStackMigrated: boolean = true;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      const flag: Object | undefined = want.parameters?.[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY];
      if (typeof flag === 'boolean') {
        this.isPageStackMigrated = flag as boolean;
      }
      // 必须在 onCreate 执行完成前、同步调用（约束与异常兜底见 §3.2）
      this.context.restoreWindowStage(new LocalStorage());
    }
  }

  onWindowStageRestore(windowStage: window.WindowStage) {
    // ① 镜像 onWindowStageCreate() 中的初始化（如有），避免迁移后异常
    // ② 页面栈迁移被禁用时才 loadContent 落地页；
    //    系统页面栈恢复（Router 默认）时不要 loadContent（会破坏已恢复的栈）
    if (!this.isPageStackMigrated) {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
      });
    }
  }
}
```

---

## 3. UIAbilityContext 接口

### 3.1 setMissionContinueState <a id="setmissioncontinuestate"></a>

```typescript
// Promise 形态
setMissionContinueState(state: AbilityConstant.ContinueState): Promise<void>;

// callback 形态
setMissionContinueState(
  state: AbilityConstant.ContinueState,
  callback: AsyncCallback<void>
): void;
```

**说明：**
- API 10+，设置 UIAbility 任务的流转状态
- 支持 **Promise** 与 **callback** 两种调用形态（下方示例用 Promise 形态）
- `ACTIVE` = 可迁移（默认）、`INACTIVE` = 关闭迁移
- 元服务 API：API 11 起支持
- 不支持分布式业务的 Wearable 设备调用不生效
- **重要**：在 `onCreate` / `onNewWant` 迁移判断中应将状态设为 `ACTIVE`，保证迁移过的应用仍可迁回

**示例：**

```typescript
import { UIAbility, AbilityConstant } from '@kit.AbilityKit';

export default class EntryAbility extends UIAbility {
  onForeground() {
    this.context.setMissionContinueState(AbilityConstant.ContinueState.INACTIVE)
      .then(() => console.info('success'))
      .catch((err) => console.error(`failed, code: ${err.code}`));
  }
}
```

### 3.2 restoreWindowStage <a id="restorewindowstage"></a>

```typescript
restoreWindowStage(localStorage: LocalStorage): void;
```

**说明：**
- 恢复 UIAbility 中的 WindowStage 数据，触发带页面栈的页面恢复
- **官方口径**：若开发者使用系统页面栈恢复功能，则需要在 `onCreate()`/`onNewWant()` **执行完成前**调用 `restoreWindowStage()`，来触发带有页面栈的页面恢复（页面栈自动恢复仅支持 Router 路由；不需要迁移页面栈时参考"按需迁移页面栈"——官方该场景示例同样先调用本接口，再在 `onWindowStageRestore()` 中按开关决定是否 `loadContent`）
- 仅支持**主线程**调用
- **必须**在同步接口方法中执行（不可在异步回调中调用，否则页面加载失败）
- **可抛出异常**（运行时错误，如无可恢复的 WindowStage 数据）：调用须 `try/catch` 兜底——失败时置失败标记，并在 `onWindowStageRestore()` 中兜底 `loadContent` 落地页，避免对端白屏（模式见 `assets/templates/EntryAbility.ets`）
- 元服务 API：API 11 起支持
- 系统能力：`SystemCapability.Ability.AbilityRuntime.Core`

**示例（官方 bpta-continue-cast）：**

```typescript
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      // 恢复业务数据（want.parameters → AppStorage 等）...
      // 在 onCreate 执行完成前、同步调用，触发带页面栈的页面恢复
      this.context.restoreWindowStage(new LocalStorage());
    }
  }
}
```

---

## 4. 分布式数据对象 (DDO) <a id="4-分布式数据对象-ddo"></a>

导入模块：

```typescript
import { distributedDataObject } from '@kit.ArkData';
```

### 4.1 create <a id="ddo-create"></a>

```typescript
create(context: Context, source: object): DataObject;
```

- API 9+
- 创建一个分布式数据对象
- 属性支持基本类型（数字、布尔、字符串）及复杂类型（数组、基本类型嵌套）
- **不可序列化对象禁止入 source**：PixelMap、Resource、函数引用等需先降级（Resource → `getStringSync`；图片 → Asset 方案）
- **文件资产规则**：单个 `commonType.Asset` 可作为根属性；**资产数组不能整体作为根属性传递**（官方不支持），动态数量必须展平为 `attachments0..N`——只有以根属性进入 DDO 的文件才会被接续框架传输（见 `references/data-migration-strategies.md` 方式三）
- 系统能力：`SystemCapability.DistributedDataManager.DataObject.DistributedObject`
- 错误码：401（参数错误）

**示例（Stage 模型）：**

```typescript
import { UIAbility } from '@kit.AbilityKit';

class SourceObject {
  name: string = '';
  age: number = 0;
  isVis: boolean = false;
}

let source: SourceObject = new SourceObject();
source.name = 'jack';
source.age = 18;
source.isVis = false;
let g_object = distributedDataObject.create(this.context, source);
```

### 4.2 genSessionId <a id="ddo-gensessionid"></a>

```typescript
genSessionId(): string;
```

- API 9+
- 随机创建一个 sessionId（DDO 组网唯一标识）
- 返回值：长度不大于 128 字节的字符串（字母、数字、下划线）

### 4.3 setSessionId <a id="ddo-setsessionid"></a>

```typescript
setSessionId(sessionId: string, callback: AsyncCallback<void>): void;
```

- API 9+
- 设置 sessionId，加入分布式组网
- 多个设备设为同一 sessionId 即可自动同步数据
- 需要权限：**ohos.permission.DISTRIBUTED_DATASYNC**（API 11 及以前需申请，API 12+ 无需）
- 传 `""` 或 `null` 表示退出分布式组网
- sessionId 长度 ≤ 128 字节，仅含字母、数字、下划线
- 错误码：201、401、15400001

### 4.4 save <a id="ddo-save"></a>

```typescript
save(deviceId?: string): Promise<SaveSuccessResponse>;
save(deviceId: string, callback: AsyncCallback<SaveSuccessResponse>): void;
```

- API 9+
- 持久化 DDO 数据，确保源端退出后对端仍能获取
- **必须先 setSessionId 再 save**（先激活再持久化）
- 源端迁移后要退出的场景，应 `await save()` 等待完成（需 Promise 版 onContinue，API 18+，12–17 的必验口径见 §2.1）
- `SaveSuccessResponse`：`{ sessionId: string, version: number, deviceId: string }`

### 4.5 on('status') <a id="ddo-on-status"></a>

```typescript
on(
  type: 'status',
  callback: (sessionId: string, networkId: string, status: 'online' | 'offline' | 'restored') => void
): void;

// 部分 SDK 版本另有 @since 20 的 StatusObserver 重载，status 类型为 string
on(type: 'status', callback: StatusObserver): void;
```

- 监听 DDO 组网状态变化
- **恢复完成字面量随系统/SDK 版本而异（背景说明，无需查证本机 SDK）**：
  - 官方最佳实践（bpta-continue-data）示例代码比较 `'restored'`；
  - 部分历史 SDK 版本类型声明写 `'restore'`；
  - @since 9 回调类型只声明 `'online' | 'offline'`，@since 20 起才以 `StatusObserver(status: string)` 补充。
- **推荐写法（已覆盖上述全部差异，直接使用）**：回调 `status` 参数声明为 `string`，判断 `status === 'restored' || status === 'restore'` 双兼容，最终以真机日志为准
- 状态恢复完成后，在此回调中读取 DDO 属性并更新 UI
- **对端必须先在 setSessionId 之前注册 on('status') 监听**，避免错过恢复完成事件

### 4.6 on('change') <a id="ddo-on-change"></a>

```typescript
on(
  type: 'change',
  callback: (sessionId: string, fields: Array<string>) => void
): void;
```

- 监听 DDO 属性数据变更
- `fields` 标识发生变化的属性名

### 4.7 off（注销监听） <a id="ddo-off-change"></a>

```typescript
off(type: 'change', callback?: (sessionId: string, fields: Array<string>) => void): void;
off(type: 'status', callback?: (sessionId: string, status: string) => void): void;
// API 20+（随 on('progressChanged')）：
off(type: 'progressChanged', callback?: (sessionId: string, progress: number) => void): void;
```

- 删除对象对应类型的监听；**不传 callback 则删除该类型全部监听**
- 对于`on()`方法创建的监听，都应该在窗口生命周期结束前，例如 `onDestroy()`中通过 `off()`删除掉，

### 4.8 setAsset / setAssets <a id="ddo-asset-transfer"></a>

```typescript
// API 20+（@since 20）
setAsset(assetKey: string, uri: string): Promise<void>;
setAssets(assetsKey: string, uris: Array<string>): Promise<void>;   // uris 数量 1–50
```

- 把 DDO 某个属性绑定为文件资产，加入组网时由框架把文件实际传输到对端；uri 必须是**分布式路径**对应的文件 URI（`fileUri.getUriFromPath(distributedFilesDir + '/' + name)`）
- **必须在 `setSessionId()` 之前调用**，否则报 15400003（sessionId 已设置）
- 与"Asset 根属性（flatAssets 展平）"方案的选型边界：
  - 运行端可能低于 API 20（compatibleSdkVersion < 20）→ 只能走 Asset 根属性方案（`references/data-migration-strategies.md` 方式三），或对 setAssets try/catch 降级；
  - API 20+ 且希望框架托管传输 / 需要进度反馈 → setAsset（数量少、键可枚举止逐个绑定）或 setAssets（动态列表）
- 错误码：15400002（assetKey/uris 非法、数量越界）、15400003（已在 setSessionId 之后调用）

### 4.9 on('progressChanged') <a id="ddo-on-progress"></a>

```typescript
// API 20+
on(type: 'progressChanged', callback: (sessionId: string, progress: number) => void): void;
```

- 观察 DDO 中文件资产的传输进度：`-1` 获取失败，`0–100` 进行中，`100` 传输完成
- 典型用途：对端等待文件落盘后再执行"复制到 filesDir → 解码/播放"，避免 restored 时文件未达的时序问题

---

## 5. Want 常量 <a id="5-want-常量"></a>

定义在 `@ohos.app.ability.wantConstant` 中：

```typescript
import { wantConstant } from '@kit.AbilityKit';
```

| 常量名 | 实际 Key 值 | API | 说明 |
|--------|-------------|-----|------|
| `Params.SUPPORT_CONTINUE_PAGE_STACK_KEY` | `ohos.extra.param.key.supportContinuePageStack` | 10+ | 是否迁移页面栈。默认 true。仅支持 Router 路由自动恢复（Navigation 需手动） |
| `Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY` | `ohos.extra.param.key.supportContinueSourceExit` | 10+ | 迁移后源端是否退出。默认 true |
| `Params.SHARE_URL_KEY` | `ohos.extra.param.key.shareUrl` | 10+ | 元服务分享的 URL 链接 |
| `Params.PAGE_PATH` | `ohos.param.atomicservice.pagePath` | 12+ | 元服务的页面路径 |

---

## 6. AbilityConstant 枚举 <a id="6-abilityconstant-枚举"></a>

### 6.1 OnContinueResult <a id="oncontinueresult"></a>

| 值 | 含义 |
|----|------|
| `AGREE` | 同意迁移 |
| `REJECT` | 拒绝迁移（如 onContinue 中异常） |
| `MISMATCH` | 版本不匹配，无法迁移 |

### 6.2 ContinueState <a id="continuestate"></a>

| 值 | 含义 |
|----|------|
| `ACTIVE` | 当前可迁移（默认状态） |
| `INACTIVE` | 当前关闭迁移能力 |

### 6.3 LaunchReason <a id="launchreason"></a>

| 值 | 含义 |
|----|------|
| `CONTINUATION` | 接续拉起 |
| `PREPARE_CONTINUATION` | 快速启动预拉起（配置了 `_ContinueQuickStart` 时先收到此值，再收到 `CONTINUATION`） |

---

## 7. API 版本矩阵 <a id="7-api-版本矩阵"></a>

| 接口 / 配置 | 最低版本 | 元服务支持 | 备注 |
|------------|---------|-----------|------|
| `module.json5` `continuable: true` | 9 | - | 默认 false |
| `onContinue`（同步） | 9 | 11 | - |
| `onContinue`（Promise 异步） | 18（口径见 §2.1） | - | compatible 12–17 仅可用同步版，"源端退出后对端可读"列为真机必验项 |
| `onCreate` | 9 | 11 | 同步 |
| `onNewWant` | 9 | 11 | 同步 |
| `onWindowStageRestore` | 9 | 11 | - |
| `restoreWindowStage` | 9 | 11 | 可抛异常：try/catch 兜底，失败时 `onWindowStageRestore` 兜底 `loadContent`（§3.2） |
| `NavPathStack.getPathStack` | 未官方标注（真机核验 API 20） | - | 路由栈快照采集；**栈不含 NavBar 根页**，entries[0] 为第一个子页（§3-B.1） |
| `NavPathStack.setInterception` | 12 | - | didShow 单一采集钩子，覆盖 push/replace/系统返回（§3-B.2） |
| `setMissionContinueState` | 10 | 11 | Wearable 不生效 |
| `DDO create` | 9 | - | 仅 `(context, source)` 两参；`@kit.ArkData` |
| `DDO genSessionId` | 9 | - | - |
| `DDO setSessionId` | 9 | - | 需 **DISTRIBUTED_DATASYNC** 权限（API 11-） |
| `DDO save` | 9 | - | 先 setSessionId 再 save |
| `commonType.Asset` / `Assets` | 11 | - | 六字段均为 string；Asset 作 DDO 根属性才会触发文件传输；资产数组须 `flatAssets()` 展平 |
| `DDO setAsset` / `setAssets` | 20 | - | 框架托管文件传输；须在 `setSessionId()` 之前调用；uris 数量 1–50 |
| `DDO on('progressChanged')` | 20 | - | 资产传输进度：-1 失败 / 0–100，100 完成 |
| `wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY` | 10 | 11 | - |
| `wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY` | 10 | 11 | - |
| `continueType`（同应用异 Ability） | - | - | 需两端一致 |
| `continueBundleName`（跨 BundleName 迁移） | - | - | 需申请接续服务 |
| `_ContinueQuickStart`（快速启动） | - | - | continueType 后缀配置 |
| `ohos.permission.DISTRIBUTED_DATASYNC` 权限 | 9 | - | API 9–11 需申请；API 12+ 无需申请 |

### Want 数据大小限制

| API 版本 | Want 最大传递数据 |
|---------|-----------------|
| API 22 及之前 | **100KB** |
| API 23+ | **200KB** |

> 接续场景下建议 wantParam 控制在 **100KB 以下**，超过请使用 DDO。

---

## 8. Want 参数系统预置字段 <a id="8-want-参数系统预置字段"></a>

`onContinue` 的 `wantParam` 中由系统预置以下字段，开发者可直接使用，**但不应使用同名字段**避免被覆盖：

| 字段 | 类型 | 含义 |
|------|------|------|
| `version` | string | 对端应用的版本号 |
| `targetDevice` | string | 对端设备的 networkId |

> `wantParam` 中的 `sessionId` key 被迁移流程系统占用，DDO 场景请使用其他 key（如 `distributedSessionId`）。

---

## 9. 错误码参考 <a id="9-错误码参考"></a>

### 通用错误码

| 错误码 | 说明 |
|--------|------|
| 401 | 参数错误（必填参数缺省、参数类型错误） |
| 201 | 权限校验未通过 |

### 元能力子系统错误码

| 错误码 | 说明 |
|--------|------|
| 16000011 | Context 不存在 |
| 16000050 | 内部错误 |
| 16000082 | 已存在的实例仍在启动过程中（组件启动规则约束） |

### DDO 错误码

| 错误码 | 说明 |
|--------|------|
| 15400001 | 创建内存数据库失败 |
| 15400002 | setAsset / setAssets 参数错误（assetKey/uri 非法，或 uris 数量越界 1–50） |
| 15400003 | setAsset / setAssets 在 sessionId 已设置之后调用（必须先于 setSessionId） |

---

> **参考链接**
> - [应用接续概述](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-continue-cast)
> - [应用接续数据迁移](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-continue-data)
> - [UIAbility API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
> - [UIAbilityContext API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext)
> - [DDO API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-distributedobject)
> - [Want API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)
> - [wantConstant](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-wantconstant)