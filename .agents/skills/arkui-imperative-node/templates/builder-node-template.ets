/**
 * BuilderNode 骨架代码模板
 * 演示自定义声明式节点的四个核心结构：创建 / 挂载 / 占位 / dispose 释放
 * 含 Create/Dispose 交互，演示完整生命周期：创建→挂载→释放→重新挂载
 * API 版本要求：API 12+
 */
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

// 1. 定义参数类（@Builder 入参类型）
class Params {
  text: string = '';

  constructor(text: string) {
    this.text = text;
  }
}

// 2. 定义 @Builder 函数（全局无状态 UI 方法，最多一个入参）
@Builder
function buildContent(params: Params) {
  Column() {
    Text(params.text)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
  }
}

// 3. NodeController（创建 + 挂载 + dispose）
class MyNodeController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;
  private message: string = 'Hello BuilderNode';

  constructor(message: string) {
    super();
    this.message = message;
  }

  makeNode(context: UIContext): FrameNode | null {
    // ===== 核心结构 1：创建 =====
    // new BuilderNode(context) 创建节点，build(wrapBuilder, params) 构建组件树
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder(buildContent), new Params(this.message));

    // ===== 核心结构 2：挂载 =====
    // getFrameNode() 获取根 FrameNode，通过 makeNode 返回值挂载到 NodeContainer
    return this.builderNode.getFrameNode();
  }

  // ===== 核心结构 4：dispose 释放 =====
  // 主动调用 dispose() 与后端实体节点解除引用关系，避免内存泄漏
  disposeNode() {
    this.builderNode?.dispose();
    this.builderNode = null;
  }

  // 更新组件树（可选）
  updateMessage(message: string) {
    this.message = message;
    this.builderNode?.update(new Params(message));
  }
}

// ===== 核心结构 3：占位 =====
// NodeContainer 作为占位容器，接收 NodeController 并触发 makeNode
@Entry
@Component
struct Index {
  @State message: string = 'Hello BuilderNode';
  @State controller: MyNodeController | undefined = new MyNodeController('Hello BuilderNode');

  build() {
    Column({ space: 16 }) {
      NodeContainer(this.controller)
        .width('100%')
        .height(100)
        .backgroundColor('#FFF0F0F0')

      Button('Dispose')
        .width('100%')
        .onClick(() => {
          this.controller?.disposeNode();
          this.controller = undefined;
        })

      Button('Create')
        .width('100%')
        .onClick(() => {
          if (this.controller === undefined) {
            this.controller = new MyNodeController(this.message);
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
