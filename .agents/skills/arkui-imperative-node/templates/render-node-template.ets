/**
 * RenderNode 骨架代码模板
 * 演示自定义渲染节点的四个核心结构：创建 / getRenderNode 挂载 / draw 绘制 / dispose 释放
 * 含 Create/Dispose 交互，演示完整生命周期：创建→挂载→释放→重新挂载
 * API 版本要求：API 12+
 */
import { FrameNode, NodeController, UIContext, RenderNode } from '@kit.ArkUI';
import { drawing } from '@kit.ArkGraphics2D';

// 自定义绘制 RenderNode
class MyRenderNode extends RenderNode {
  // ===== 核心结构 3：draw 绘制 =====
  // 重写 draw 方法，通过 DrawContext 获取 canvas 进行自定义绘制
  draw(context: DrawContext) {
    const canvas = context.canvas;
    const brush = new drawing.Brush();
    brush.setColor(0xFF00BFFF);
    canvas.attachBrush(brush);
    canvas.drawRect({ left: 0, right: 200, top: 0, bottom: 200 });
    canvas.detachBrush();
  }
}

class MyNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private myRenderNode: MyRenderNode | null = null;

  makeNode(context: UIContext): FrameNode | null {
    // ===== 核心结构 1：创建 =====
    // new FrameNode(context) 作为载体 + new RenderNode() 创建渲染节点
    this.rootNode = new FrameNode(context);

    this.myRenderNode = new MyRenderNode();
    // 设置渲染属性（frame / backgroundColor / opacity 等）
    this.myRenderNode.frame = { x: 0, y: 0, width: 200, height: 200 };
    this.myRenderNode.backgroundColor = 0xFF00BFFF;

    // ===== 核心结构 2：getRenderNode 挂载 =====
    // 通过 FrameNode.getRenderNode() 获取根 RenderNode，appendChild 挂载上树
    const rootRenderNode = this.rootNode.getRenderNode();
    if (rootRenderNode) {
      rootRenderNode.appendChild(this.myRenderNode);
    }

    return this.rootNode;
  }

  // ===== 核心结构 4：dispose 释放 =====
  // 主动调用 dispose() 释放 RenderNode 和 FrameNode 的后端实体节点
  disposeNodes() {
    this.myRenderNode?.dispose();
    this.rootNode?.dispose();
    this.myRenderNode = null;
    this.rootNode = null;
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
        .height(200)
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
