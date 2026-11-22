/**
 * FrameNode 骨架代码模板
 * 演示自定义组件节点的四个核心结构：创建 / 挂载 / commonAttribute 属性设置 / dispose 释放
 * 含 Create/Dispose 交互，演示完整生命周期：创建→挂载→释放→重新挂载
 * API 版本要求：API 12+
 */
import { FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class MyNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private childNode: FrameNode | null = null;

  makeNode(context: UIContext): FrameNode | null {
    // ===== 核心结构 1：创建 =====
    // new FrameNode(context) 创建实体节点（必传 UIContext）
    this.rootNode = new FrameNode(context);
    // commonAttribute 设置节点属性（width/height/backgroundColor 等）
    this.rootNode.commonAttribute
      .width('100%')
      .height(100)
      .backgroundColor(Color.Gray);

    // 创建子节点并通过 appendChild 挂载到父节点
    this.childNode = new FrameNode(context);
    this.childNode.commonAttribute
      .width(50)
      .height(50)
      .backgroundColor(Color.Pink);
    this.rootNode.appendChild(this.childNode);

    // ===== 核心结构 2：挂载 =====
    // makeNode 返回 FrameNode，通过 NodeContainer 占位上树
    return this.rootNode;
  }

  // ===== 核心结构 4：dispose 释放 =====
  // 主动调用 disposeTree() 释放整棵节点树，避免内存泄漏
  disposeNodes() {
    this.rootNode?.disposeTree();
    this.rootNode = null;
    this.childNode = null;
  }
}

// ===== 核心结构 3：占位 =====
// NodeContainer 作为占位容器，接收 NodeController 并触发 makeNode
@Entry
@Component
struct Index {
  @State controller: MyNodeController | undefined = new MyNodeController();

  build() {
    Column({ space: 16 }) {
      NodeContainer(this.controller)
        .width('100%')
        .height(100)
        .backgroundColor('#FFF0F0F0')

      Button('Dispose')
        .width('100%')
        .onClick(() => {
          this.controller?.disposeNodes();
          this.controller = undefined;
        })

      Button('Create')
        .width('100%')
        .onClick(() => {
          if (this.controller === undefined) {
            this.controller = new MyNodeController();
          }
        })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
