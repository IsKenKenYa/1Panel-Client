# 应用接续数据迁移策略

> 数据来源：HarmonyOS 官方文档（bpta-continue-data 等）
> 最后同步：2026-09

---

## 决策矩阵

按以下优先级逐项判断，命中即选：

| 优先级 | 数据特征 | 推荐方式 | 适用场景 |
|-------|---------|---------|---------|
| 1 | 任何大小，数据可重拉取 | 只传**数据标识**，目标端按 ID 重新拉取 | 业务数据已有后端/云存储的场景 |
| 2 | 涉及文件（图片/视频/文档，任何大小） | 文件资产迁移（文件落分布式目录 + **Asset 作为 DDO 根属性**） | 附件、图片、音视频文件 |
| 3 | **< 100KB** 轻量可序列化数据 | `want.parameters` | 页面标识、短字符串、单页滚动位置、Tab 索引 |
| 4 | **≥ 100KB** 或可变对象 | 分布式数据对象（DDO） | 长列表数据、表单内容、编辑器状态、复杂 JSON |

> ⚠️ **易错红线："只传文件引用"不会迁移文件**（本条为真机返工教训）
>
> `distributedFilesDir` 只解决"文件放在哪"，**不解决"文件怎么到对端"**：
> - 对端分布式目录**不保证**自动同步源端写入的文件——即使双端同账号、同 WLAN/蓝牙组网，也不可把"自动同步"当作设计前提；
> - 仅通过 `want.parameters` 或 DDO 传"文件名 / URI 字符串"、目标端再去读 `distributedFilesDir` → **对端读不到文件**。这是"接续后文本正常、图片却空白"的头号根因；
> - 接续场景下可靠的文件通道只有两种：
>   1. **Asset 根属性随 DDO 迁移**（方式三，API 11+；动态数量的资产数组**必须展平**为 `attachments0..N` 根属性，官方不支持数组整体作为根属性）；
>   2. **`setAsset` / `setAssets`**（API 20+，框架托管传输，可配 `on('progressChanged')` 等待落盘，见 `references/api-reference.md` §4.8/§4.9）。

---

## 方式一：want.parameters（轻量数据）

**适用条件**：≤ 100KB、可序列化、无需实时同步。

### 源端保存

```typescript
import { UIAbility, AbilityConstant } from '@kit.AbilityKit';

export default class EntryAbility extends UIAbility {
  onContinue(wantParam: Record<string, Object | undefined>): AbilityConstant.OnContinueResult {
    // 简单键值对保存
    wantParam['pageId'] = 'detail_123';
    wantParam['scrollOffset'] = 450;
    wantParam['isLogin'] = false;
    return AbilityConstant.OnContinueResult.AGREE;
  }
}
```

### 目标端恢复

```typescript
// 在 onCreate() / onNewWant() 中暂存迁移数据，并触发页面恢复
if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
  if (want.parameters !== undefined) {
    AppStorage.setOrCreate('pageId', want.parameters['pageId']);
    AppStorage.setOrCreate('scrollOffset', want.parameters['scrollOffset']);
    AppStorage.setOrCreate('isLogin', want.parameters['isLogin']);
  }
  // 页面恢复（官方契约：在 onCreate()/onNewWant() 执行完成前、同步调用）：
  // ① Router 默认（系统页面栈恢复）：restoreWindowStage() 恢复带页面栈的页面，
  //    onWindowStageRestore 中不要 loadContent；
  // ② 禁用页面栈迁移（Navigation/按需）：官方示例同样先调用 restoreWindowStage()，
  //    再在 onWindowStageRestore() 中 loadContent 指定落地页。
  this.context.restoreWindowStage(new LocalStorage());
}
```

### 注意事项

- 建议控制在 **100KB 以下**
- 实际硬上限：API 22 及之前 **100KB**，API 23+ **200KB**
- 只支持可序列化数据（基本类型、JSON 可序列化对象）
- 不要使用系统预占字段名（`version`、`targetDevice`、`sessionId`）

---

## 方式二：分布式数据对象 DDO（大数据/可变数据）

**适用条件**：≥ 100KB、需要实时同步、数据结构复杂。

### 源端保存流程

> 顺序：`create()` → 填充数据 → `genSessionId()` → `setSessionId()` → `save()` → 将 sessionId 通过 want 传递

```typescript
import { distributedDataObject } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';

// 接续数据结构定义
export class ContinuationData {
  public basicDataStr: string | undefined;
  public basicDataNum: number | undefined;
  public curPageInfos: string | undefined;

  constructor(
    basicDataStr: string | undefined,
    basicDataNum: number | undefined,
    curPageInfos: string | undefined,
  ) {
    this.basicDataStr = basicDataStr;
    this.basicDataNum = basicDataNum;
    this.curPageInfos = curPageInfos;
  }
}

export default class EntryAbility extends UIAbility {
  private distributedObject: distributedDataObject.DataObject | undefined;

  async onContinue(wantParam: Record<string, Object | undefined>): Promise<AbilityConstant.OnContinueResult> {
    // 1. 生成 sessionId
    let sessionId: string = distributedDataObject.genSessionId();
    // 使用自定义 key 保存 sessionId，避免与系统预占的 "sessionId" 冲突
    wantParam['distributedSessionId'] = sessionId;

    // 2. 准备数据
    let contentInfo: ContinuationData = new ContinuationData(
      AppStorage.get('basicDataStr') ?? '',
      AppStorage.get('basicDataNum') ?? undefined,
      'pages/Index',
    );

    // 3. 创建 DDO
    this.distributedObject = distributedDataObject.create(this.context, contentInfo);

    // 4. 激活 DDO（加入组网）——必须 await 确保激活完成后再持久化
    await this.distributedObject.setSessionId(sessionId).catch((err: BusinessError) => {
      console.error(`setSessionId failed. Code: ${err.code}`);
    });

    // 5. 持久化（确保源端退出后对端仍可获取）
    await this.distributedObject.save(wantParam['targetDevice'] as string).catch((err: BusinessError) => {
      console.error(`save failed. Code: ${err.code}`);
    });

    return AbilityConstant.OnContinueResult.AGREE;
  }
}
```

### 目标端恢复流程

> 顺序：创建空 DDO（属性为 undefined）→ 读 sessionId → **先注册 `on('status')` 监听** → `setSessionId()` 加入组网

```typescript
export default class EntryAbility extends UIAbility {
  private distributedObject: distributedDataObject.DataObject | undefined;
  private storage: LocalStorage = new LocalStorage();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.appContinuity(want, launchParam);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.appContinuity(want, launchParam);
  }

  appContinuity(want: Want, launchParam: AbilityConstant.LaunchParam) {
    if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) return;

    // 1. 创建空 DDO（属性必须为 undefined，否则会覆盖源端数据）
    let mailInfo: ContinuationData = new ContinuationData(undefined, undefined, undefined);
    this.distributedObject = distributedDataObject.create(this.context, mailInfo);

    // 2. 先注册 status 监听（避免错过恢复完成事件；'restored'/'restore' 字面量随版本而异，双兼容）
    this.distributedObject.on('status', (_sessionId, _networkId, status: string) => {
      if (status === 'restored' || status === 'restore') {
        if (!this.distributedObject) return;
        // 从 DDO 中读取恢复的数据
        AppStorage.setOrCreate('basicDataStr', this.distributedObject['basicDataStr'] ?? '');
        AppStorage.setOrCreate('basicDataNum', this.distributedObject['basicDataNum'] ?? undefined);
      }
    });

    // 3. 读取 sessionId 并加入组网
    let sessionId: string = want.parameters?.['distributedSessionId'] as string;
    this.distributedObject.setSessionId(sessionId).catch((err: BusinessError) => {
      console.error(`setSessionId failed. Code: ${err.code}`);
    });

    // 4. 页面恢复：restoreWindowStage() 需在 onCreate()/onNewWant() 执行完成前、
    //    同步调用——本示例 appContinuity 为同步方法且由 onCreate/onNewWant 直接调用，
    //    可置于其末尾；⚠️ 禁止放进 Promise/异步回调（否则迁移后页面加载失败）。
    //    Router 默认：恢复带页面栈的页面；禁栈场景（Navigation/按需）的落地页
    //    在 onWindowStageRestore() 中 loadContent。
    this.context.restoreWindowStage(new LocalStorage());
  }
}
```

### 关键规则

| 规则 | 说明 |
|------|------|
| **先激活再持久化** | `setSessionId()` 必须在 `save()` 之前调用 |
| **对端属性设 undefined** | 创建空 DDO 时属性设为 `undefined`，否则会覆盖源端数据 |
| **先监听再激活** | 对端必须先注册 `on('status')` 再 `setSessionId()`，防止错过恢复完成事件（`'restored'`/`'restore'` 字面量随版本而异，判断需双兼容，见 `references/api-reference.md` §4.5） |
| **防止空指针** | DDO 不能是临时变量（`on()` 回调在 `onCreate/onNewWant` 结束之后才执行） |
| **await save** | 源端退出场景务必 `await save()`（需 Promise 版 onContinue，API 18+，12–17 的必验口径见 `references/api-reference.md` §2.1） |
| **自定义 key** | sessionId 使用非 `"sessionId"` 的 key（如 `"distributedSessionId"`）传递 |
| **权限** | API 12+ 无需申请权限；API 11 及以前需声明并申请 `ohos.permission.DISTRIBUTED_DATASYNC` |

---

## 方式三：文件资产迁移（Asset + DDO）

**适用条件**：需要迁移图片、视频、文档等文件。

### 核心机制（务必先读）

文件本体先写入 `distributedFilesDir`，再为其构建 `commonType.Asset`（`name/uri/path` 指向该文件），
**把 Asset 作为 DDO source 的根属性**传入；接续框架据此在迁移时把文件实际传输到对端分布式目录。

- 官方约束（bpta-continue-data 原文）：**"当前不支持直接将资产数组作为根属性传递"**
  → 动态数量的文件必须**展平**为 `attachments0、attachments1 …` 逐个根属性（即 `flatAssets()`，实现见下文单点引用）；
- `commonType.Asset`（@since 11）六个字段全部为 `string`：`name` / `uri` / `path` / `createTime` / `modifyTime` / `size`；
- 单个/固定数量文件可以把每个 Asset 直接作为独立根属性；动态列表必须展平；
- API 20+ 的替代通道 `setAsset` / `setAssets` 见本节末与 `references/api-reference.md` §4.8/§4.9。

### 文件资产迁移流程

```
源端：文件 → 写入 distributedFilesDir → 构建 Asset → flatAssets() 展平为根属性 → DDO create/setSessionId/save
对端：空 DDO → 先 on('status') 再 setSessionId → restored/restore 回调
     → 按 attachments{i} 读回 Asset → 从对端 distributedFilesDir+'/'+name 复制到 filesDir → 解码 PixelMap → 写 AppStorage
```

### 源端：将文件写入分布式文件目录

```typescript
import { fileIo } from '@kit.CoreFileKit';
import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 1. 将文件写入分布式文件目录（选图/生成时尽早执行；onContinue 前必须已落盘）
export async function writeDistributedFile(context: Context, buf: ArrayBuffer, displayName: string): Promise<void> {
  let filePath: string = context.distributedFilesDir + '/' + displayName;
  let file: fileIo.File | undefined = undefined;
  try {
    file = await fileIo.open(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    await fileIo.write(file.fd, buf);
  } catch (err) {
    console.error(`write failed. Code: ${(err as BusinessError).code}`);
  } finally {
    if (file) {
      await fileIo.close(file);
    }
  }
}
```

### 完整实现（单点引用）

`getAssetInfo`（构建 Asset）、`ContentInfo` + `flatAssets()`（数据模型与展平）、源端 `onContinue` 组装、对端按 `attachments{i}` 读回并复制解码的**完整实现只在编辑场景文档与示例中维护**（本文件不复述代码，避免多处复制失守）：

- `references/edit-progress-continuity.md` §2.1（数据模型与 `flatAssets()` 展平）/ §3.2（源端 `onContinue` 组装）/ §4.2 + §5（对端读回、复制与解码）
- `assets/examples/EditProgress.ets`（可直接复制的完整代码）

关键规则（详见上述单点）：

- 只有以**根属性**进入 DDO 的文件才会被接续框架传输；只传文件名/URI 引用 = 文件不会到达对端
- 对端复制路径用**对端本地** `distributedFilesDir + asset.name` 拼接；`asset.path` / `asset.uri` 是源端设备的路径，对端不可直接使用
- 对端先复制到本地 `filesDir` 再解码（脱离分布式文件生命周期）

### API 20+ 替代：setAssets（框架托管传输 + 进度回调）

运行端为 API 20+ 时，可不再手工展平根属性，改用 `setAssets(assetsKey, uris)`（数量 1–50，
**必须在 `setSessionId()` 之前调用**），并通过对端 `on('progressChanged')`（100 = 完成）等待文件落盘；
低于 API 20 的运行时调用会抛异常，需 try/catch 降级回根属性方案。签名与选型边界见 `references/api-reference.md` §4.8/§4.9。

---

## 方式四：数据标识重拉取

**适用条件**：业务数据已有后端/云存储。

### 流程

```typescript
// 源端：只传数据标识
onContinue(wantParam: Record<string, Object>) {
  wantParam['documentId'] = 'doc_20260901_001';  // 只传 ID
  wantParam['editPosition'] = 2048;               // 编辑位置
  return AbilityConstant.OnContinueResult.AGREE;
}

// 目标端：根据标识重新拉取
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
  if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
    let docId = want.parameters?.['documentId'] as string;
    let position = want.parameters?.['editPosition'] as number;
    // 向后端请求文档内容，再定位到编辑位置
    fetchDocument(docId, position);
  }
}
```

### 适用场景

- 文档/笔记类（后端存储文档内容，只传文档 ID + 编辑位置）
- 列表数据（只传列表查询参数，目标端重新查询）
- 音视频在线内容（只传播放列表 ID + 播放进度）
- **整库/多条记录迁移**（用户要求全量接续本地库时）：**首选本方式**（数据放后端/云侧，接续只传标识，迁移载荷最小、无传输上限风险）；无后端时次选整库 DDO + 文件资产（方式二 + 方式三组合，对端按记录 ID 合并入库，须处理合并冲突与传输体量，真机必验）。**默认方案只迁移当前打开页面的状态与关联文件**，整库迁移须用户显式确认（见 `assets/checklists/confirm-scene-inventory.md` §六）

---

## 选型判据总结

| 判据 | want.parameters | DDO | 文件资产迁移 | 数据标识重拉 |
|------|----------------|-----|-------------|-------------|
| 数据量上限 | ~200KB（API 23+） | 无硬限制 | 取决于分布式文件系统 | 无限制 |
| 序列化要求 | 可序列化（基本类型 + JSON） | 基本类型 + 数组/嵌套对象 | Asset **根属性**（数组须 flatAssets 展平，不能整体传递） | 无需序列化 |
| 文件是否真正传输 | —（不适用） | —（不适用） | 是：Asset 进 DDO 后由接续框架传输 | —（文件本就在后端） |
| 实时同步 | 一次性传递 | 可变对象自动同步 | Asset 随 DDO 同步；文件随迁移一次性传输 | 不适用 |
| 需网络 | 是（接续链路） | 是（软总线） | 是（接续框架传输文件） | 是（业务后端） |
| 源端退出后可用 | 是（数据在 want 中） | 是（save 持久化后） | 是——**前提是** Asset 作为根属性进 DDO；仅写 `distributedFilesDir` 传引用**不成立** | 是（数据在后端） |
| 实现复杂度 | 低 | 中 | 高（展平 + 对端复制解码） | 中（依赖后端） |
| 涉及文件 | 否 | 否 | 是 | 否 |

---

> **参考链接**
> - [应用接续数据迁移](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-continue-data)
> - [分布式数据对象 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-distributedobject)
> - [文件管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fs)