/**
 * 示例：内容编辑场景接续数据处理（编辑类）——含图片文件资产迁移的完整实现
 *
 * 用途：展示文本编辑器 / 表单页面的接续实现模式。
 *   编辑器三态（可得的缺一不可，组件可得性见 checklist-edit §二）：
 *   文本内容 + 滚动位置 + 光标位置（TextArea 无公开光标 API，记为已知缺口上报）。
 *   实现模式与官方 ContinuePublish 示例（DDO + 文件资产迁移）一致，已经真机项目验证。
 *
 * 核心组件：
 *   1. ContentInfo 数据模型 —— DDO 数据结构（所有字段可选）+ flatAssets() 资产展平
 *   2. getAssetInfo（源端） / fileCopyAndDecode（目标端）—— 文件资产迁移工具函数
 *   3. EntryAbility 接线 —— 源端 onContinue 保存 + 目标端 restored 回调恢复
 *   4. 编辑器三态 —— text / scrollOffset / caretPosition（见文末页面侧模式）
 *
 * ⚠️ DDO 与文件资产关键规则（违反任何一条都会导致接续"看起来成功、图片却丢失"）：
 *   - 目标端创建空 DDO 时，所有字段必须为 undefined（防止覆盖源端数据）
 *   - 先注册 on('status') 再 setSessionId()（防止错过恢复完成事件）
 *   - setSessionId() 必须在 save() 之前完成（先激活再持久化）
 *   - ❗ distributedFilesDir 不会自动同步到对端：文件必须由 Asset 作为 DDO **根属性**
 *     携带、经接续框架传输。资产数组不能整体作根属性，必须 flatAssets() 展平为
 *     attachments0..N；只传文件名/URI 引用 = 对端图片必丢
 *   - ❗ PixelMap / Resource 等原生对象不可序列化，禁止进入 DDO
 *   - status 恢复完成字面量随版本而异：'restored' 与 'restore' 需双兼容判断
 *   - ❗ 编译通过 ≠ 文件迁移成功；图片/文件恢复必须双端真机实测验收
 *     （清单：assets/checklists/checklist-edit-progress.md §五/§八）
 *
 * 使用方式：把本文件中的关键代码复制到项目中按需修改。
 *   ⚠️ 页面侧代码为 V1 装饰器写法（@StorageLink）；@ComponentV2 页面不支持，
 *   改造规则见 references/state-decorator-migration.md
 *
 * 双端数据流方向对照（红线：方向不可颠倒/自循环）：
 * | 端     | 回调               | 数据方向                                       |
 * | 源端   | onContinue         | AppStorage / 本地状态 → DDO + wantParam（只出）|
 * | 目标端 | onCreate/onNewWant | want.parameters → AppStorage（页面恢复引导）  |
 * | 目标端 | restored 回调      | DDO 属性 → AppStorage / 页面状态              |
 * ⚠️ 目标端禁止 setOrCreate(k, AppStorage.get(k) ?? v) 式同端自循环——
 *    迁移数据永不落地，编译/静态检查全过，仅表现为对端打开空白/初始页。
 *
 * 配套文件：
 *   - Ability 接线模板：assets/templates/EntryAbility.ets
 *   - 方案说明：references/edit-progress-continuity.md
 *   - 数据迁移选型：references/data-migration-strategies.md（方式三：文件资产迁移）
 *   - API 详情：references/api-reference.md（§2.1 / §4.5 / §4.8 / §4.9）
 */

import { commonType, distributedDataObject } from '@kit.ArkData';
import { AbilityConstant, common, UIAbility, Want, wantConstant } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;
const TAG = 'EditProgress';

// ============================================================
// 0. 图片显示模型（仅本机 UI 使用，PixelMap 不进 DDO）
// ============================================================

export interface ImageInfo {
  imagePixelMap: PixelMap;
  imageName: string;
}

// ============================================================
// 1. 数据模型（DDO 数据结构）
// ============================================================

/**
 * 编辑内容信息，用于分布式数据对象。
 * ⚠️ 所有字段必须为可选类型（| undefined），目标端空 DDO 全部传 undefined。
 * ⚠️ imageNames 与 attachments 顺序严格一一对应：目标端按 attachments{i} 读回、
 *    数量以 imageNames 为准（Asset 缺失时可用名称做回退校验）。
 */
export class ContentInfo {
  public mainTitle: string | undefined;
  public textContent: string | undefined;
  public imageNames: Array<string> | undefined;
  public isShowLocalInfo: boolean | undefined;
  public isAddLocalInfo: boolean | undefined;
  public selectLocalInfo: string | undefined; // Resource 必须在迁移前解析为 string（见 resolveResourceText）
  // attachments 只是业务侧容器；进 DDO 前由 flatAssets() 展平为根属性
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
   * attachments0、attachments1 …（官方约束：资产数组不能直接作为根属性传递）。
   * 只有以根属性进入 DDO 的文件，接续框架才会把它传输到对端。
   * Record 写法兼容 ArkTS 严格模式（与官方 obj[`attachments${i}`] 语义相同）。
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

// ============================================================
// 2. 源端工具：为 distributedFilesDir 中的文件构建 Asset
// ============================================================

/**
 * stat 失败 = 文件不存在/尚未落盘 → 返回 undefined，调用方跳过该张并记日志，
 * 绝不能把 undefined 塞进 attachments（会造成对端索引错位）。
 * ⚠️ Asset 六个字段（name/uri/path/createTime/modifyTime/size）均为 string（@since 11）。
 */
export function getAssetInfo(context: common.UIAbilityContext, imageName: string): commonType.Asset | undefined {
  let filePath: string = context.distributedFilesDir + '/' + imageName;
  try {
    let stat: fileIo.Stat = fileIo.statSync(filePath);
    if (stat.size <= 0) {
      hilog.warn(DOMAIN, TAG, 'getAssetInfo: file empty, skip %{public}s', imageName);
      return undefined;
    }
    let asset: commonType.Asset = {
      name: imageName,
      uri: fileUri.getUriFromPath(filePath),
      path: filePath,
      createTime: stat.ctime.toString(),
      modifyTime: stat.mtime.toString(),
      size: stat.size.toString()
    };
    return asset;
  } catch (err) {
    hilog.warn(DOMAIN, TAG, 'getAssetInfo stat failed %{public}s: %{public}d',
      imageName, (err as BusinessError).code);
    return undefined;
  }
}

/** Resource → string（$r 对象不可序列化，进 DDO 前必须解析；带占位符时传形参） */
export function resolveResourceText(context: common.UIAbilityContext, value: Object | undefined): string | undefined {
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value === 'string') {
    return value;
  }
  try {
    // 形如 $r('app.key', params) 的 Resource：用 id + params 解析回文案
    let res = value as Resource;
    return context.resourceManager.getStringSync(res.id, ...(res.params ?? []));
  } catch (err) {
    hilog.warn(DOMAIN, TAG, 'resolveResourceText failed: %{public}d', (err as BusinessError).code);
    return undefined;
  }
}

// ============================================================
// 3. 目标端工具：从本地分布式目录复制文件并解码
// ============================================================

/**
 * ⚠️ 入参是文件名：路径必须用【对端本地】distributedFilesDir + name 拼接；
 *    asset.path / asset.uri 是源端设备的绝对路径/URI，对端不能直接使用。
 * 先复制到 filesDir（脱离分布式文件生命周期）再解码；单张失败返回 null，调用方跳过。
 */
export async function fileCopyAndDecode(context: common.UIAbilityContext,
  imageName: string): Promise<ImageInfo | null> {
  let srcPath: string = context.distributedFilesDir + '/' + imageName;
  let destPath: string = context.filesDir + '/' + imageName;
  try {
    if (!fileIo.accessSync(srcPath)) {
      hilog.warn(DOMAIN, TAG, 'fileCopyAndDecode: distributed file not arrived: %{public}s', imageName);
      return null;
    }
    fileIo.copyFileSync(srcPath, destPath);
    let imageSource: image.ImageSource = image.createImageSource(destPath);
    try {
      let pixelMap: PixelMap = await imageSource.createPixelMap();
      let info: ImageInfo = { imagePixelMap: pixelMap, imageName: imageName };
      return info;
    } finally {
      imageSource.release().catch((err: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'release imageSource failed: %{public}d', err.code);
      });
    }
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'fileCopyAndDecode failed %{public}s: %{public}d',
      imageName, (err as BusinessError).code);
    return null;
  }
}

// ============================================================
// 4. Ability 接线：源端保存 + 目标端恢复
// ============================================================

export default class EntryAbility extends UIAbility {
  private distributedObject: distributedDataObject.DataObject | undefined = undefined;
  // 页面栈是否走系统恢复：源端设 SUPPORT_CONTINUE_PAGE_STACK_KEY=false 时目标端读回 false
  private isPageStackMigrated: boolean = true;
  // restoreWindowStage 失败兜底标记（该接口可抛异常，见 api-reference §3.2）
  private isWindowRestoreFailed: boolean = false;

  // ---------------- 源端：onContinue 保存 ----------------

  async onContinue(wantParam: Record<string, Object | undefined>): Promise<AbilityConstant.OnContinueResult> {
    // 1. 收集编辑状态；图片以 distributedFilesDir 中已落盘的文件为准构建 Asset
    let imageInfos: Array<ImageInfo> = (AppStorage.get('imageUriArray') as Array<ImageInfo>) ?? [];
    let imageNames: Array<string> = [];
    let attachments: Array<commonType.Asset> = [];
    for (const info of imageInfos) {
      let asset: commonType.Asset | undefined = getAssetInfo(this.context, info.imageName);
      if (asset) {
        imageNames.push(asset.name);
        attachments.push(asset);
      }
      // 构建失败（未落盘）：已记日志，跳过该张，不阻断整体迁移
    }
    let contentInfo: ContentInfo = new ContentInfo(
      AppStorage.get('mainTitle') ?? '',
      AppStorage.get('textContent') ?? '',
      imageNames,
      AppStorage.get('isShowLocalInfo') ?? false,
      AppStorage.get('isAddLocalInfo') ?? false,
      resolveResourceText(this.context, AppStorage.get('selectLocalInfo')),
      attachments.length > 0 ? attachments : undefined);

    // 2. sessionId（自定义 key，避开系统预占的 "sessionId"）
    let sessionId: string = distributedDataObject.genSessionId();
    wantParam['distributedSessionId'] = sessionId;

    // 3. 创建 DDO —— source 必须是 flatAssets() 展平结果（Asset 以根属性触发文件传输）
    //    注意：SDK 的 create() 只有 (context, source) 两个参数
    this.distributedObject?.off('status', this.distributedStatusCallback);
    let distributedObject: distributedDataObject.DataObject =
      distributedDataObject.create(this.context, contentInfo.flatAssets());

    // 4. 先激活（setSessionId）再持久化（save），await 保证源端退出前完成
    await distributedObject.setSessionId(sessionId);
    let targetDevice: string | undefined = wantParam['targetDevice'] as string | undefined;
    if (targetDevice) {
      await distributedObject.save(targetDevice);
    } else {
      hilog.warn(DOMAIN, TAG, 'onContinue: targetDevice missing, skip save');
    }
    this.distributedObject = distributedObject;
    return AbilityConstant.OnContinueResult.AGREE;
  }

  // ---------------- 目标端：onCreate / onNewWant 恢复 ----------------

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // ① 页面恢复：restoreWindowStage 必须在 onCreate/onNewWant 执行完成前、
    //    同步方法体中调用（放进异步回调会导致迁移后页面加载失败）
    this.restoreWindowOnContinuation(want, launchParam);
    // ② DDO 数据恢复（异步组网，不影响页面恢复时序）
    this.handleContinuation(want, launchParam).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'handleContinuation failed: %{public}d', err.code);
    });
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.restoreWindowOnContinuation(want, launchParam);
    this.handleContinuation(want, launchParam).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'handleContinuation failed: %{public}d', err.code);
    });
  }

  /** 页面恢复：读回页面栈开关，并按官方契约同步调用 restoreWindowStage */
  private restoreWindowOnContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) {
      return;
    }
    const flag: Object | undefined = want.parameters?.[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY];
    if (typeof flag === 'boolean') {
      this.isPageStackMigrated = flag as boolean;
    }
    // Router 默认（系统页面栈恢复）：恢复带页面栈的页面；
    // 禁栈场景（Navigation/按需）的落地页在 onWindowStageRestore 中 loadContent。
    // 本接口可抛异常：失败置标记，onWindowStageRestore 中兜底 loadContent。
    try {
      this.context.restoreWindowStage(new LocalStorage());
    } catch (err) {
      this.isWindowRestoreFailed = true;
      hilog.error(DOMAIN, TAG, 'restoreWindowStage failed: %{public}s', JSON.stringify(err));
    }
  }

  private async handleContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) {
      return; // 非接续启动，不建组网
    }
    // 允许后续再次迁出
    this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE, (err: BusinessError) => {
      hilog.info(DOMAIN, TAG, 'setMissionContinueState callback %{public}d', err ? err.code : 0);
    });

    let sessionId: string = want.parameters?.distributedSessionId as string;
    if (!sessionId) {
      hilog.warn(DOMAIN, TAG, 'handleContinuation: no distributedSessionId in want');
      return;
    }

    // 1. 空 DDO：所有字段 undefined，防止覆盖源端数据（attachments{i} 由框架动态同步进来）
    let emptyInfo: ContentInfo = new ContentInfo(
      undefined, undefined, undefined, undefined, undefined, undefined, undefined);
    this.distributedObject?.off('status', this.distributedStatusCallback);
    let ddo: distributedDataObject.DataObject = distributedDataObject.create(this.context, emptyInfo);

    // 2. ⚠️ 先注册 status 监听，再 setSessionId（防止错过恢复完成事件）
    ddo.on('status', this.distributedStatusCallback);

    // 3. 加入组网
    try {
      await ddo.setSessionId(sessionId);
      this.distributedObject = ddo;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'setSessionId failed: %{public}d', (err as BusinessError).code);
      ddo.off('status', this.distributedStatusCallback);
    }
  }

  /** status 回调：'restored'/'restore' 字面量随版本而异，双兼容（api-reference §4.5） */
  private distributedStatusCallback = (sessionId: string, networkId: string, status: string): void => {
    if ((status === 'restored' || status === 'restore') && this.distributedObject) {
      let ddo = this.distributedObject;
      // 标量状态 → AppStorage（页面用 @StorageLink 双向绑定，恢复后自动刷新）
      AppStorage.setOrCreate('mainTitle', (ddo['mainTitle'] as string) ?? '');
      AppStorage.setOrCreate('textContent', (ddo['textContent'] as string) ?? '');
      AppStorage.setOrCreate('isShowLocalInfo', (ddo['isShowLocalInfo'] as boolean) ?? false);
      AppStorage.setOrCreate('isAddLocalInfo', (ddo['isAddLocalInfo'] as boolean) ?? false);
      AppStorage.setOrCreate('selectLocalInfo', (ddo['selectLocalInfo'] as string) ?? '');
      // 图片：按展平根属性 attachments0..N 读回（数量以 imageNames 为准）
      this.restoreImages(ddo).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'restoreImages failed: %{public}d', err.code);
      });
    }
  };

  private async restoreImages(ddo: distributedDataObject.DataObject): Promise<void> {
    let names: Array<string> = (ddo['imageNames'] as Array<string>) ?? [];
    let restored: Array<ImageInfo> = [];
    for (let i = 0; i < names.length; i++) {
      let asset = ddo['attachments' + i] as commonType.Asset | undefined;
      let imageName: string = asset?.name ?? names[i];
      let info: ImageInfo | null = await fileCopyAndDecode(this.context, imageName);
      if (info) {
        restored.push(info);
      }
      // 单张缺失/解码失败：已在工具函数记日志，跳过该张，UI 呈现其余图片
    }
    AppStorage.setOrCreate('imageUriArray', restored);
  }

  // ---------------- 窗口：迁移启动不执行 onWindowStageCreate ----------------
  // 官方镜像原则：onWindowStageCreate() 中有启动必要的初始化时，才需要在
  // onWindowStageRestore() 中执行同样的初始化；onWindowStageCreate 无初始化、
  // 且系统页面栈恢复可用（Router 默认）时，onWindowStageRestore 可整段省略（最小侵入）。

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Home');
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
    // 页面栈迁移被禁用时（Navigation / SUPPORT_CONTINUE_PAGE_STACK_KEY=false）
    // 或 restoreWindowStage 失败兜底时，手动加载落地页；
    // 系统页面栈恢复（Router 默认）时不要 loadContent——
    // 页面栈已由 restoreWindowStage 恢复，重复加载会破坏已恢复的栈。
    if (!this.isPageStackMigrated || this.isWindowRestoreFailed) {
      windowStage.loadContent('pages/Home');
    }
  }

  onDestroy(): void {
    if (this.distributedObject) {
      this.distributedObject.off('status', this.distributedStatusCallback);
    }
  }
}

// ============================================================
// 5. 页面侧：编辑器三态（文本 + 滚动 + 光标）
// ============================================================

/**
 * 页面组件（示意，放入业务页面）：
 *
 *   private scroller: Scroller = new Scroller();                 // 滚动容器控制器
 *   private caretIndex: number = 0;                              // 光标位置（保持普通私有变量，勿加响应式装饰器）
 *   @StorageLink('textContent') textContent: string = '';        // 文本三态之一；@ComponentV2 页面改用 @Local + AppStorage 手动绑定
 *
 *   // onContinue 前采集（或 Ability 经 AppStorage 读取）：
 *   //   滚动：AppStorage.setOrCreate('scrollOffset', this.scroller.currentOffset().yOffset)
 *   //   光标：TextInputController.caretPosition 读取
 *   // 恢复：aboutToAppear / @Watch 中
 *   //   setTimeout(() => this.scroller.scrollTo({ yOffset: AppStorage.get('scrollOffset') }), 50)
 *   //   TextInputController.caretPosition(index)
 *   // ⚠️ 恢复写入对象需重新赋值（新引用），同名对象引用可能不触发 UI 刷新
 *   // ⚠️ 懒加载页面从未打开时，collect 不得给未初始化字段填默认值；restore 只覆盖 !== undefined 字段
 */
