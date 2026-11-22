# 编辑类接续方案说明

> 数据来源：HarmonyOS 官方示例项目（ContinuePublish）
> 最后同步：2026-09

---

## 1. 方案原理

编辑类接续的核心挑战是**数据量大且可能包含文件资产**。官方 ContinuePublish 示例采用 **DDO（分布式数据对象）+ 文件资产迁移**的方案：

- 文本内容、表单状态等 → DDO 自动同步
- 图片等文件附件 → 写入 `distributedFilesDir` 后构建 `commonType.Asset`，并**作为 DDO 的根属性**传入，由接续框架在迁移时把文件实际传输到对端
  - ⚠️ 官方约束：资产**数组**不能直接作为根属性传递，动态数量必须经 `flatAssets()` 展平为 `attachments0..N`（实现见 §2.1）
  - ⚠️ 只传"文件名/URI 引用"、指望 `distributedFilesDir` 自动同步到对端 → **对端读不到文件**，这是"图片接续空白"的头号根因（详见 `references/data-migration-strategies.md` 方式三）

**数据流：**

```
源端                                       目标端
─────                                      ─────
页面编辑 → AppStorage                       onCreate / onNewWant
  ↓                                          ↓
onContinue() (async)                        restoreDistributedObject()
  ① genSessionId()                            创建空 DDO（字段全部 undefined）
  ② 从 AppStorage 构建 ContentInfo             先注册 on('status') 监听
  ③ DDO.create(context,                        再 setSessionId() 加入组网
       contentInfo.flatAssets())  ← Asset 展平   ↓
  ④ DDO.setSessionId(sessionId)                status 'restored'/'restore' 回调（双兼容）
  ⑤ await DDO.save(targetDevice)             从 DDO 读取数据写入 AppStorage
  ⑥ wantParam 写入 distributedSessionId         按 attachments{i} 复制附件到本地目录+解码
  返回 AGREE
                                               ↓
                                             页面 aboutToAppear()
                                               从 AppStorage 恢复编辑状态
```

---

## 2. 数据模型设计

### 2.1 ContentInfo 类（DDO 数据结构）

**关键原则：**
1. 所有字段必须为可选类型（`| undefined`），目标端创建空 DDO 时字段设为 `undefined`，否则会覆盖源端数据；
2. **原生对象禁止进 DDO**：`PixelMap`、`Resource`、函数引用均不可序列化——图片以"文件名列表 + Asset 根属性"迁移，`Resource` 迁移前用 `resourceManager.getStringSync()` 解析为字符串；
3. 资产**数组**不能整体作为 DDO 根属性（官方不支持），必须用 `flatAssets()` 展平为 `attachments0..N`。

```typescript
import { commonType } from '@kit.ArkData';

// ⚠️ PixelMap 是原生对象，不可序列化，禁止进入 DDO；
//    图片迁移 = imageNames（顺序锚点）+ attachments（Asset 展平后的根属性）
export class ContentInfo {
  public mainTitle: string | undefined;
  public textContent: string | undefined;
  public imageNames: Array<string> | undefined;
  public isShowLocalInfo: boolean | undefined;
  public isAddLocalInfo: boolean | undefined;
  public selectLocalInfo: string | undefined;
  // 业务侧容器；进 DDO 前由 flatAssets() 展平为根属性
  public attachments: commonType.Assets | undefined;

  constructor(
    mainTitle: string | undefined,
    textContent: string | undefined,
    imageNames: Array<string> | undefined,
    isShowLocalInfo: boolean | undefined,
    isAddLocalInfo: boolean | undefined,
    selectLocalInfo: string | undefined,
    attachments: commonType.Assets | undefined
  ) {
    this.mainTitle = mainTitle;
    this.textContent = textContent;
    this.imageNames = imageNames;
    this.isShowLocalInfo = isShowLocalInfo;
    this.isAddLocalInfo = isAddLocalInfo;
    this.selectLocalInfo = selectLocalInfo;
    this.attachments = attachments;
  }

  /**
   * 构建 DDO source：仅保留可序列化字段，并把每个 Asset 展平为独立根属性
   * attachments0、attachments1 …（官方多文件资产迁移要求：资产数组不能直接作根属性）。
   * Record 写法兼容 ArkTS 严格模式，与官方示例 obj[`attachments${i}`] = asset 语义相同。
   */
  flatAssets(): Record<string, Object> {
    let obj: Record<string, Object> = {};
    if (this.mainTitle !== undefined) {
      obj['mainTitle'] = this.mainTitle;
    }
    if (this.textContent !== undefined) {
      obj['textContent'] = this.textContent;
    }
    if (this.imageNames !== undefined) {
      obj['imageNames'] = this.imageNames;
    }
    if (this.isShowLocalInfo !== undefined) {
      obj['isShowLocalInfo'] = this.isShowLocalInfo;
    }
    if (this.isAddLocalInfo !== undefined) {
      obj['isAddLocalInfo'] = this.isAddLocalInfo;
    }
    if (this.selectLocalInfo !== undefined) {
      obj['selectLocalInfo'] = this.selectLocalInfo;
    }
    if (this.attachments !== undefined) {
      for (let i = 0; i < this.attachments.length; i++) {
        obj['attachments' + i] = this.attachments[i];
      }
    }
    return obj;
  }
}
```

### 2.2 编辑器三态

编辑器场景须同步以下三个独立状态（组件可得的缺一不可；组件不可得的记为已知缺口上报，不伪造实现——可得性见 `assets/checklists/checklist-edit-progress.md` §二）：

| 状态 | 采集方式 | 恢复方式 |
|------|---------|---------|
| **文本内容** | `TextInput` / `TextArea` 的 `onChange` 回调 | 赋值给组件的 `text` 属性 |
| **滚动位置** | `scroller.currentOffset().yOffset` | `setTimeout(50)` 后 `scrollTo()` |
| **光标位置** | `TextInputController.caretPosition` | 通过控制器恢复 |

---

## 3. 源端：onContinue 中保存

### 3.1 同步版本（轻量数据，无文件附件）

```typescript
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  // 轻量编辑状态走 want.parameters
  wantParam['mainTitle'] = AppStorage.get<string>('mainTitle') as string;
  wantParam['textContent'] = AppStorage.get<string>('textContent') as string;
  return AbilityConstant.OnContinueResult.AGREE;
}
```

### 3.2 异步版本（大数据 / 文件附件；onContinue 的 Promise 形态见 `references/api-reference.md` §2.1 版本口径）

```typescript
async onContinue(wantParam: Record<string, Object | undefined>):
    Promise<AbilityConstant.OnContinueResult> {
  // 1. 收集编辑状态；每张图片校验分布式目录文件并构建 Asset（名称列表与 Asset 索引严格对齐）
  let imageInfos: Array<ImageInfo> = (AppStorage.get('imageUriArray') as Array<ImageInfo>) ?? [];
  let imageNames: Array<string> = [];
  let attachments: commonType.Asset[] = [];
  for (const info of imageInfos) {
    let asset: commonType.Asset | undefined = getAssetInfo(this.context, info.imageName); // 实现见 §5.1
    if (asset) {
      imageNames.push(asset.name);
      attachments.push(asset);
    }
    // 构建失败（文件未落盘）：记日志跳过该张，勿中断迁移
  }
  let contentInfo: ContentInfo = new ContentInfo(
    AppStorage.get('mainTitle') ?? '',
    AppStorage.get('textContent') ?? '',
    imageNames,
    AppStorage.get('isShowLocalInfo') ?? false,
    AppStorage.get('isAddLocalInfo') ?? false,
    this.resolveSelectLocalInfo(AppStorage.get('selectLocalInfo')),  // Resource → string，见 §2.1 原则2
    attachments.length > 0 ? attachments : undefined);

  // 2. 生成 sessionId（自定义 key，避开系统预占 "sessionId"）
  let sessionId: string = distributedDataObject.genSessionId();
  wantParam['distributedSessionId'] = sessionId;

  // 3. 创建 DDO（source 必须是 flatAssets() 展平结果，Asset 才能以根属性触发文件传输）
  let distributedObject = distributedDataObject.create(this.context, contentInfo.flatAssets());

  // 4. 加入组网
  await distributedObject.setSessionId(sessionId);

  // 5. 持久化到目标设备（await 确保完成后再返回 AGREE）
  await distributedObject.save(wantParam['targetDevice'] as string);

  // 6. 保存分布式对象引用（供后续清理）
  this.distributedObject = distributedObject;

  return AbilityConstant.OnContinueResult.AGREE;
}
```

**要点：**
- `setSessionId()` 必须在 `save()` 之前完成（先激活再持久化）
- `await save()` 确保源端退出前数据已持久化到目标端
- 文件附件写入 `distributedFilesDir`，构建 `commonType.Asset` 并经 `flatAssets()` **展平为根属性**——这一步决定文件是否真正传输，只传文件名引用 = 图片必丢

---

## 4. 目标端：恢复数据

### 4.1 创建空 DDO 并加入组网

```typescript
async function restoreDistributedObject(
    context: common.UIAbilityContext, want: Want,
    launchParam: AbilityConstant.LaunchParam,
    statusCallback: (sessionId: string, networkId: string, status: string) => void
): Promise<distributedDataObject.DataObject | undefined> {
  if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) {
    return undefined;
  }

  // ⚠️ 创建空 DDO：所有字段为 undefined，防止覆盖源端数据
  //（附件根属性 attachments0..N 会由框架动态同步进对象，无需预声明）
  let emptyInfo: ContentInfo = new ContentInfo(
    undefined, undefined, undefined, undefined, undefined, undefined, undefined
  );
  let distributedObject = distributedDataObject.create(context, emptyInfo);

  // ⚠️ 先注册 status 监听，再 setSessionId（防止错过恢复完成事件；
  //    回调参数按 string 接收：'restored'/'restore' 字面量随系统版本而异，判断需双兼容，
  //    见 references/api-reference.md §4.5）
  distributedObject.on('status', statusCallback);

  // 加入组网
  let sessionId: string = want.parameters?.distributedSessionId as string;
  distributedObject.setSessionId(sessionId);

  return distributedObject;
}
```

### 4.2 status 回调中恢复数据

```typescript
// 在 Ability 中定义 status 回调（restored/restore 双兼容）
private distributedStatusCallback = (sessionId: string, networkId: string, status: string) => {
  if ((status === 'restored' || status === 'restore') && this.distributedObject) {
    let ddo = this.distributedObject;
    // 从 DDO 读取数据写入 AppStorage
    AppStorage.setOrCreate('mainTitle', (ddo['mainTitle'] as string) ?? '');
    AppStorage.setOrCreate('textContent', (ddo['textContent'] as string) ?? '');
    // 附件按展平根属性 attachments0..N 读回（数量以 imageNames 为准，Asset 缺失回退名称列表）
    let names: Array<string> = (ddo['imageNames'] as Array<string>) ?? [];
    for (let i = 0; i < names.length; i++) {
      let asset = ddo['attachments' + i] as commonType.Asset | undefined;
      let imageName: string = asset?.name ?? names[i];
      // 复制 + 解码（⚠️ 用对端本地 distributedFilesDir 拼路径，不用 asset.path），实现见 §5.2
      // let imageInfo = await fileCopy(this.context, imageName);
    }
  }
};
```

---

## 5. 文件资产迁移

### 5.1 源端：将文件写入分布式目录并创建 Asset

```typescript
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { commonType } from '@kit.ArkData';

// 入参为文件名（不是 ImageInfo——PixelMap 原生对象不可序列化，也不应整体进 DDO）；
// stat 失败 = 文件不存在/未写完 → 返回 undefined，调用方跳过该张并记日志
function getAssetInfo(context: common.UIAbilityContext, imageName: string): commonType.Asset | undefined {
  let filePath = context.distributedFilesDir + '/' + imageName;
  try {
    let stat = fileIo.statSync(filePath);
    let uri: string = fileUri.getUriFromPath(filePath);
    let asset: commonType.Asset = {
      name: imageName,
      uri: uri,
      path: filePath,
      createTime: stat.ctime.toString(),
      modifyTime: stat.mtime.toString(),
      size: stat.size.toString()   // Asset 六个字段均为 string（@since 11 类型定义）
    };
    return asset;
  } catch (err) {
    return undefined;
  }
}
```

### 5.2 目标端：从分布式目录复制文件到本地并解码（完整实现）

```typescript
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 从对端分布式目录复制文件到本地 filesDir（脱离分布式文件生命周期），再解码为 PixelMap。
// ⚠️ 入参是文件名（asset.name 或名称列表项）；禁止直接使用 asset.path/uri —— 那是源端设备的路径
export async function fileCopy(context: common.UIAbilityContext,
  imageName: string): Promise<ImageInfo | null> {
  let filePath: string = context.distributedFilesDir + '/' + imageName;
  let savePath: string = context.filesDir + '/' + imageName;
  try {
    if (!fileIo.accessSync(filePath)) {
      return null; // 文件未达/缺失：记日志跳过该张，勿中断整体恢复
    }
    fileIo.copyFileSync(filePath, savePath);
    let imageSource: image.ImageSource = image.createImageSource(savePath);
    try {
      let pixelMap: PixelMap = await imageSource.createPixelMap();
      let info: ImageInfo = { imagePixelMap: pixelMap, imageName: imageName };
      return info;
    } finally {
      imageSource.release().catch((err: BusinessError) => {
        console.error(`release imageSource failed. Code: ${err.code}`);
      });
    }
  } catch (err) {
    console.error(`fileCopy failed. Code: ${(err as BusinessError).code}`);
    return null;
  }
}
```

### 5.3 文件迁移失败排查速查

| 现象 | 检查点 | 建议日志关键字 |
|------|--------|---------------|
| 源端 Asset 构建失败 | 选图后 JPEG 是否已写入 `distributedFilesDir`（写文件是异步的，选完立即迁移可能未落盘） | `getAssetInfo` / `writeDistributedFile` |
| 对端 `attachments{i}` 为 undefined | source 是否用了 `flatAssets()` 展平结果（数组整体塞入不支持） | `Attachment asset missing` |
| 对端 restored 到达但复制失败 | 是否误用 `asset.path`（源端绝对路径）；对端须用本地目录 + `asset.name` | `Distributed file not found` |
| 恢复回调迟迟不触发 | 是否"先 on('status') 再 setSessionId"；字面量是否双兼容 | — |
| 文本正常但图片必丢 | 退化为"只传引用"：Asset 未进 DDO 根属性 | 对照本节 §3.2 要点逐条核 |

---

## 6. DDO 生命周期管理

> ⚠️ **DDO 回调红线（SKILL.md 硬约束，详见 api-reference §4.7）**：`on()` 回调（`'status'`/`'change'`/`'progressChanged'`）内**禁止** `off()` / `setSessionId('')` / 丢弃 DDO 引用 / 大 I/O（复制/解码）——真机实证回调内同步注销触发 SIGSEGV。注销落点：回调之外、延后（setTimeout ≥ 3s）或 onDestroy；收到 restored 只置标志位，重副作用交给后续事件循环。

```typescript
// Ability onDestroy 中清理（回调链外的最终兜底落点）
onDestroy(): void {
  if (this.distributedObject) {
    this.distributedObject.off('status', this.distributedStatusCallback);
  }
}

// 页面 aboutToDisappear 中退出组网（如需；同样不得在 DDO 回调内触发）
aboutToDisappear(): void {
  // off('change') + setSessionId('') 退出组网（延后执行模式见 api-reference §4.7）
}
```

---

## 7. 并发写冲突策略

> 多数编辑类垂类（笔记、邮箱、拍摄美化）官方推荐**源端退出**（设计为"应用按需适配"，须与用户确认）；保留源端属于用户明确要求的按需方案（见 `assets/checklists/confirm-scene-inventory.md` §附录 B）。

保留源端应用（`SUPPORT_CONTINUE_SOURCE_EXIT_KEY = false`）时，双端可能同时编辑同一数据，须按下表策略处理并发写冲突：

| 策略 | 实现方式 | 适用场景 |
|------|---------|---------|
| **乐观锁** | 数据带版本号，写入时比对，冲突提示 | 文档协作 |
| **后写者胜** | 明确声明，接受覆盖 | 简单表单 |
| **锁定模式** | 迁移期间禁止源端编辑 | 金融/安全场景 |

---

## 关联资源

- 代码示例：`assets/examples/EditProgress.ets`
- 自检清单：`assets/checklists/checklist-edit-progress.md`
- 数据迁移选型：`references/data-migration-strategies.md`
- API 详情：`references/api-reference.md`
