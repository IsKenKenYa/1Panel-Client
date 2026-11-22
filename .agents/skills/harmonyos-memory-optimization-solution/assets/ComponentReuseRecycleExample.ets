/**
 * ComponentReuseRecycleExample.ets
 * 复用和释放离线Web组件完整示例
 * 模式：createNWeb 直接以目标 url 创建（构建即加载）+ 空闲件复用（仅复用时 loadUrl）
 *      + 退后台释放（dispose + rebuild）/ 回前台恢复（按原 key 重建）
 *
 * API 26 签名要点（照抄早期示例会编译失败，写前 grep 本机 d.ts）：
 *  - NodeController/BuilderNode/FrameNode/UIContext/Size 必须显式 import from '@kit.ArkUI'
 *  - BuilderNode 为元组泛型：BuilderNode<[WebData]> + wrapBuilder<[WebData]>(webBuilder)
 *  - NodeController.onBind/onUnbind 签名为 (containerId: number)（非 detached: FrameNode）
 */

import { UIContext, NodeController, BuilderNode, Size, FrameNode } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

/** BuilderNode 构建入参封装（@Builder 收单参数） */
class WebData {
  public url: ResourceStr = '';
  public controller: webview.WebviewController = new webview.WebviewController();
}

@Builder
function webBuilder(data: WebData) {
  Column() {
    Web({ src: data.url, controller: data.controller })
      .width('100%')
      .height('100%')
  }
}

let wrap = wrapBuilder<[WebData]>(webBuilder);

/** 离线 Web 组件控制器：onBind/onUnbind 跟踪绑定状态，blanked 跟踪内容空白态 */
export class MyNodeController extends NodeController {
  private bindCount: number = 0;
  /** 内容是否处于空白态（loadUrl('about:blank') 置位 / 加载目标页复位；空闲件复用判定依据） */
  private blanked: boolean = false;
  private rootNode: BuilderNode<[WebData]> | null = null;
  private webController: webview.WebviewController = new webview.WebviewController();

  // 必须要重写的方法，用于构建节点树、返回节点挂载在对应NodeContainer中
  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.rootNode !== null) {
      return this.rootNode.getFrameNode();
    }
    return null;
  }

  aboutToResize(size: Size) {
    console.info('aboutToResize width : ' + size.width + ' height : ' + size.height);
  }

  aboutToAppear() {
    console.info('aboutToAppear');
  }

  aboutToDisappear() {
    console.info('aboutToDisappear');
  }

  // 在 controller 与 NodeContainer 绑定后执行（API 26 签名为 containerId: number）
  onBind(containerId: number) {
    this.bindCount += 1;
    console.info('onBind, containerId:' + containerId + ', count: ' + this.bindCount);
  }

  // 在 controller 与 NodeContainer 解除绑定后执行
  onUnbind(containerId: number) {
    this.bindCount -= 1;
    console.info('onUnbind, containerId:' + containerId + ', count: ' + this.bindCount);
  }

  // 判断离线组件是否已被绑定
  isBound(): boolean {
    return this.bindCount > 0;
  }

  // 判断内容是否已置空为 about:blank（空闲件判定：未绑定且内容已置空）
  isBlanked(): boolean {
    return this.blanked;
  }

  // 初始化：按传入 url 直接创建，BuilderNode 构建即加载目标页（无需再 loadUrl）
  initWeb(url: ResourceStr, uiContext: UIContext) {
    if (this.rootNode !== null) {
      return;
    }
    this.rootNode = new BuilderNode<[WebData]>(uiContext);
    this.rootNode.build(wrap, { url: url, controller: this.webController });
    this.blanked = String(url).startsWith('about:blank');
  }

  // 获取对应的webController
  getWebController(): webview.WebviewController {
    return this.webController;
  }

  // 加载页面（复用空闲件时把目标页装回）；waitForAttached 等待 controller 关联，加载成功后同步空白态
  // 注意：waitForAttached 返回后 loadUrl 仍可能静默失败（引擎未就绪、无异常），
  // 可靠兜底 = 加载后时间维度校验重试（如 300ms × 5 次，getUrl() 仍 about:blank 前缀则重载）
  async loadUrl(url: ResourceStr | undefined): Promise<void> {
    if (url === undefined) {
      return;
    }
    try {
      await this.webController.waitForAttached(5000);
      this.webController.loadUrl(url);
      this.blanked = String(url).startsWith('about:blank');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.info('loadUrl error: ' + err.code + ' ' + err.message);
    }
  }

  // 释放 BuilderNode（销毁组件树；随后须调用 rebuild() 使节点脱离绑定）
  release(): void {
    this.rootNode?.dispose();
  }
}

// 创建Map保存所需要的NodeController
let nodeMap: Map<ResourceStr, MyNodeController | undefined> = new Map();
// 创建保存uiContext的全局变量
let globalUiContext: UIContext | undefined = undefined;
// 创建Set保存已释放的离线组件url信息
let recycledNWebs: Set<ResourceStr> = new Set();
// 前后台标志（router 架构守卫：后台引起的 onPageHide 跳过置空解绑；NavDestination 架构可省略）
let backgroundFlag: boolean = false;

export const isBackground = (): boolean => {
  return backgroundFlag;
}

// 创建离线Web组件：直接以传入 url 创建（目标页或 about:blank 均可，构建即加载）
export const createNWeb = (url: ResourceStr, uiContext: UIContext) => {
  console.info('createNWeb, url = ' + String(url));
  if (!globalUiContext) {
    globalUiContext = uiContext;
  }
  if (getNWeb(url)) {
    console.info('createNWeb, already exit this node, url:' + String(url));
    return;
  }

  let baseNode = new MyNodeController();
  baseNode.initWeb(url, uiContext);
  nodeMap.set(url, baseNode);
  recycledNWebs.delete(url);
}

// 自定义获取NodeController接口（按 key 取件，含「目标 url 创建后置空回池」的组件）
export const getNWeb = (url: ResourceStr | undefined): MyNodeController | undefined => {
  if (url === undefined) {
    return undefined;
  }
  return nodeMap.get(url);
}

// 获取空闲的NWebNode接口：未绑定 且（key 以 about:blank 开头，或内容已置空白态）
// 注意：目标 url 创建的组件置空回池后 key 不变（不以 about:blank 开头），仅按 key 前缀判定会漏掉
export const getFreeWebNode = (): MyNodeController | undefined => {
  for (let url of nodeMap.keys()) {
    let node = nodeMap.get(url);
    if (node && !node.isBound() &&
      (String(url).startsWith('about:blank') || node.isBlanked())) {
      console.info('getFreeWebNode url = ' + String(url));
      return node;
    }
  }
  console.warn('getFreeWebNode, no offline web node returned');
  return undefined;
}

// 释放/回收单个离线Web组件：dispose + rebuild，从池移除并记入 recycledNWebs
// 当离线组件没有被NodeContainer绑定时，允许安全释放，否则节点在不重绘时会显示空白
export const recycleNWeb = (url: ResourceStr, force: boolean = false): boolean => {
  console.info('recycleNWeb, url = ' + String(url));
  let baseNode = nodeMap.get(url);
  if (!baseNode) {
    console.info('no such node, url: ' + String(url));
    return false;
  }
  if (!force && baseNode.isBound()) {
    console.info('the node is in bound and not force, can not delete');
    return false;
  }
  baseNode.release();
  baseNode.rebuild();
  nodeMap.delete(url);
  recycledNWebs.add(url);
  return true;
}

// 释放所有离线Web组件（UIAbility.onBackground 触发；默认非强制，可见页绑定组件不回收）
export const recycleNWebs = (force: boolean = false) => {
  backgroundFlag = true;
  nodeMap.forEach((_node: MyNodeController | undefined, url: ResourceStr) => {
    recycleNWeb(url, force);
  });
}

// 恢复之前释放的离线Web组件（UIAbility.onForeground 触发，按原 key 重建，构建即加载）
export const restoreNWebs = (uiContext: UIContext | undefined = undefined) => {
  if (!uiContext) {
    uiContext = globalUiContext;
  }
  for (let url of recycledNWebs) {
    if (uiContext) {
      createNWeb(url, uiContext);
    }
  }
  recycledNWebs.clear();
  backgroundFlag = false;
}

/**
 * 使用示例（@Entry router 页面架构）:
 *
 * // EntryAbility.ets - 退后台释放和前台恢复
 * import { recycleNWebs, restoreNWebs } from '../pages/Common';
 *
 * onForeground(): void {
 *   restoreNWebs();  // 恢复离线Web组件（按原 url 重建，构建即加载）
 * }
 * onBackground(): void {
 *   recycleNWebs();  // 释放空闲池组件（非强制；可见页仍绑定的组件存活不回收）
 * }
 *
 * // Page2.ets — 空闲件复用 + 池空直接创建（仅复用件才 loadUrl）
 * import { createNWeb, getFreeWebNode, getNWeb, MyNodeController, isBackground } from './Common'
 *
 * @Entry
 * @Component
 * struct Page2 {
 *   @State private node: MyNodeController | undefined = getFreeWebNode();
 *   // rawfile 本地页用 'resource://rawfile/xxx.html' 字符串（勿用 $rawfile 对象作池 key）
 *   private targetUrl: string = 'https://www.example.com';
 *
 *   onPageShow(): void {
 *     if (!this.node) {
 *       this.node = getFreeWebNode();                     // ① 复用路径：内容已置空的空闲件
 *     }
 *     if (!this.node) {
 *       createNWeb(this.targetUrl, this.getUIContext());  // ② 池空：直接以目标 url 创建，构建即加载
 *       this.node = getNWeb(this.targetUrl);
 *     }
 *     // 仅内容已置空的复用件才 loadUrl；新建件不 loadUrl，已在显示目标页的绑定件不重载
 *     if (this.node && this.node.isBlanked()) {
 *       this.node.loadUrl(this.targetUrl);
 *     }
 *   }
 *
 *   onPageHide(): void {
 *     if (isBackground()) {
 *       return;  // 后台引起的 hide：内容与绑定不动（router 架构守卫）
 *     }
 *     this.node?.loadUrl('about:blank');   // 置空为复用做准备（不调 dispose，释放仅退后台触发）
 *     setTimeout(() => {
 *       this.node = undefined;             // 延迟解绑 → onUnbind → 可被 getFreeWebNode 再次取到
 *     }, 100)
 *   }
 *
 *   build() {
 *     Column() {
 *       if (this.node) {
 *         NodeContainer(this.node)
 *           .height('100%')
 *           .width('100%')
 *       } else {
 *         Text('webNode NodeContainer')
 *           .height('100%')
 *           .width('100%')
 *       }
 *     }
 *   }
 * }
 *
 * // NavDestination 架构：onPageShow/onPageHide 换成 .onWillShow/.onWillHide（纯导航事件，
 * // 不随应用前后台触发，isBackground 守卫可省略），取件与 loadUrl 逻辑完全一致。
 *
 * // 可选变体：目标 url 未知的页面可预创建 about:blank 空白件（createNWeb('about:blank?tab=1')），
 * // 取用时 loadUrl 装载目标页；空闲判定对「空白 key」与「置空回池的目标 key」均生效。
 */
