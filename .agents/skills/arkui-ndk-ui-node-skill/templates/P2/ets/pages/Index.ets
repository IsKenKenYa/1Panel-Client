import { NodeContent, ComponentContent } from '@kit.ArkUI';
import nativeModule from 'libarkui_ndk_p2.so';

@Builder
function arktsComponentBuilder(message: string) {
  Column() {
    Text('Hello from ArkTS!')
      .fontSize(18)
    Text(message)
      .fontSize(14)
      .fontColor('#666666')
  }
  .padding(12)
  .backgroundColor('#F5F5F5')
  .borderRadius(8)
}

@Entry
@Component
struct Index {
  private nodeContent: NodeContent = new NodeContent();
  private arktsContent: ComponentContent<string> | null = null;

  build() {
    Column() {
      Text('P2: Native → ArkTS 组件')
        .fontSize(20)
        .margin({ top: 20, bottom: 20 })

      // ContentSlot 占位符，Native 侧将父节点挂载到此 NodeContent
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
    // 创建 ComponentContent（API 12+ 构造须传三个参数）：
    // 1. UIContext — 通过 this.getUIContext() 获取（自定义组件内置方法，详见 references/api-facts.md）
    // 2. WrappedBuilder — 通过 wrapBuilder() 包装 @Builder 函数，不得直接传 @Builder 函数本身
    // 3. args — builder 参数，类型须与泛型 T 一致
    // 详见 references/component-content-constructor.md
    this.arktsContent = new ComponentContent<string>(
      this.getUIContext(),
      wrapBuilder(arktsComponentBuilder),
      'mounted as child'
    );

    // 将 NodeContent 和 ComponentContent 传入 Native 侧
    // Native 侧：创建父节点挂到 NodeContent，再从 ComponentContent 取 handle addChild
    nativeModule.mountArktsComponent(this.nodeContent, this.arktsContent);
  }

  aboutToDisappear() {
    // dispose 防泄漏：先释放 Native 侧（napi_ref + disposeNode），再释放 ArkTS 侧 ComponentContent
    nativeModule.dispose();
    if (this.arktsContent !== null) {
      this.arktsContent.dispose();
      this.arktsContent = null;
    }
  }
}
