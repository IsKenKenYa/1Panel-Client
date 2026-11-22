import { NodeContent } from '@kit.ArkUI';
import nativeModule from 'libarkui_ndk_p1.so';

@Entry
@Component
struct Index {
  private nodeContent: NodeContent = new NodeContent();

  build() {
    Column() {
      Text('P1: ArkTS → Native 节点树')
        .fontSize(20)
        .margin({ top: 20, bottom: 20 })

      // ContentSlot 占位符，Native 侧将节点挂载到此 NodeContent
      // 注意：ContentSlot 不支持通用属性（width/height 等），须用带尺寸的容器包裹以约束占位区域
      Column() {
        ContentSlot(this.nodeContent)
      }
      .width('100%')
      .height('50%')
    }
    .width('100%')
    .height('100%')
  }

  aboutToAppear() {
    // 将 NodeContent 传入 Native 侧，Native 取得 NodeContentHandle 后挂载节点树
    // aboutToAppear 运行在主线程，符合 ArkUI NDK 线程约束（参见 references/thread-safety.md）
    nativeModule.mountNativeNodes(this.nodeContent);
  }

  aboutToDisappear() {
    // dispose 防泄漏：组件销毁时释放 Native createNode 创建的节点（参见 references/node-dispose.md）
    nativeModule.disposeNodes();
  }
}
