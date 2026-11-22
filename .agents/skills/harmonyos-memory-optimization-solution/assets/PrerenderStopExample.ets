/**
 * PrerenderStopExample.ets
 * 离线组件预渲染完成后停止渲染示例
 */

import { UIContext, NodeController, BuilderNode, Size, FrameNode } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';

// Data为入参封装类
class Data {
  public url: string = 'www.example.com';
  public controller: WebviewController = new webview.WebviewController();
}

// 通过布尔变量shouldInactive控制网页在后台完成预渲染后停止渲染
let shouldInactive: boolean = true;

@Builder
function webBuilder(data: Data) {
  Column() {
    Web({ src: data.url, controller: data.controller })
      .onPageBegin(() => {
        // 调用onActive，开启渲染
        data.controller.onActive();
      })
      .onFirstMeaningfulPaint(() => {
        if (!shouldInactive) {
          return;
        }
        // 在预渲染完成时触发，停止渲染
        data.controller.onInactive();
        shouldInactive = false;
      })
      .width('100%')
      .height('100%')
  }
}

let wrap = wrapBuilder<Data[]>(webBuilder);

// 用于控制和反馈对应的NodeContainer上的节点的行为
export class MyNodeController extends NodeController {
  private rootNode: BuilderNode<Data[]> | null = null;

  // 必须要重写的方法，用于构建节点树、返回节点挂载在对应NodeContainer中
  makeNode(uiContext: UIContext): FrameNode | null {
    console.info('uiContext is undefined : ' + (uiContext === undefined));
    if (this.rootNode !== null) {
      // 返回FrameNode节点
      return this.rootNode.getFrameNode();
    }
    // 返回null控制动态组件脱离绑定节点
    return null;
  }

  // 当布局大小发生变化时进行回调
  aboutToResize(size: Size) {
    console.info('aboutToResize width : ' + size.width + ' height : ' + size.height);
  }

  // 当controller对应的NodeContainer在Appear的时候进行回调
  aboutToAppear() {
    console.info('aboutToAppear');
    // 切换到前台后，不需要停止渲染
    shouldInactive = false;
  }

  // 当controller对应的NodeContainer在Disappear的时候进行回调
  aboutToDisappear() {
    console.info('aboutToDisappear');
  }

  // 此函数为自定义函数，可作为初始化函数使用
  initWeb(url: string, uiContext: UIContext, control: WebviewController) {
    if (this.rootNode !== null) {
      return;
    }
    // 创建节点，需要uiContext
    this.rootNode = new BuilderNode(uiContext);
    // 创建动态Web组件
    this.rootNode.build(wrap, { url: url, controller: control });
  }
}

// 创建Map保存所需要的NodeController
let nodeMap: Map<string, MyNodeController | undefined> = new Map();
// 创建Map保存所需要的WebviewController
let controllerMap: Map<string, WebviewController | undefined> = new Map();

// 初始化需要UIContext 需在Ability获取
export const createNWeb = (url: string, uiContext: UIContext) => {
  // 创建NodeController
  let baseNode = new MyNodeController();
  let controller = new webview.WebviewController();
  // 初始化自定义Web组件
  baseNode.initWeb(url, uiContext, controller);
  controllerMap.set(url, controller);
  nodeMap.set(url, baseNode);
}

// 自定义获取NodeController接口
export const getNWeb = (url: string): MyNodeController | undefined => {
  return nodeMap.get(url);
}

/**
 * 使用示例:
 *
 * // EntryAbility.ets
 * import { createNWeb } from '../pages/Common';
 * import { window } from '@kit.ArkUI';
 *
 * onWindowStageCreate(windowStage: window.WindowStage): void {
 *   windowStage.loadContent('pages/Index', (err, data) => {
 *     if (err && err.code) {
 *       console.info('loadContent failed. errorCode: ' + err.code);
 *       return;
 *     }
 *     let windowClass: window.Window = windowStage.getMainWindowSync();
 *     if (!windowClass) {
 *       console.info('windowClass is null');
 *       return;
 *     }
 *     // 创建Web动态组件并预渲染
 *     createNWeb('www.example.com', windowClass.getUIContext());
 *   });
 * }
 *
 * // Index.ets - 展示预渲染结果
 * import { getNWeb } from './Common'
 *
 * @Entry
 * @Component
 * struct Index {
 *   build() {
 *     Row() {
 *       Column() {
 *         NodeContainer(getNWeb('www.example.com'))
 *           .height('90%')
 *           .width('100%')
 *       }
 *       .width('100%')
 *     }
 *     .height('100%')
 *   }
 * }
 *
 * 预渲染停止工作流程:
 * 1. EntryAbility.onWindowStageCreate 中调用 createNWeb 创建离线Web组件
 * 2. Web组件创建后 onPageBegin 触发，调用 onActive() 开启渲染
 * 3. 页面渲染完成，onFirstMeaningfulPaint 触发
 * 4. shouldInactive 为 true，调用 onInactive() 停止渲染
 * 5. 用户进入Web页面时，aboutToAppear 将 shouldInactive 设为 false
 * 6. 页面继续正常渲染，不再停止
 */
