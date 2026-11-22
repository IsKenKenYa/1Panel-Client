# 生命周期检查

## 检查条件

代码中 BuilderNode 内部的自定义组件（`@Builder` 函数体内使用的 `@Component` 组件）依赖 `aboutToDisappear` 回调执行资源清理逻辑。典型特征：在 `aboutToDisappear` 中调用了 `clearInterval`、`clearTimeout`、事件解绑、关闭连接等清理操作，且期望该回调在节点移除或页面销毁时自动触发。

## 检查步骤

1. **检查 aboutToDisappear 的使用预期**：对 BuilderNode 内部自定义组件的 `aboutToDisappear` 回调，检查其中是否包含资源清理逻辑（定时器清除、事件解绑、连接关闭等）。若开发者期望该回调在 BuilderNode 被移除或页面销毁时自动触发，则需进一步检查。
2. **检查 dispose 调用路径**：检查是否在不再需要 BuilderNode 时主动调用了 `dispose()`。BuilderNode 是命令式对象，不绑定声明式组件树的生命周期管理机制，`aboutToDisappear` 不保证触发。
3. **边界条件**：
   - BuilderNode 内部组件的 `aboutToAppear` 在创建时会触发，但 `aboutToDisappear` 的触发取决于组件是否被声明式树正确销毁，当 BuilderNode 持有后端强引用时组件不会自动销毁；
   - **调用 `dispose()` 释放节点时，内部组件的 `aboutToDisappear` 也不会同步触发**（实测确认）。dispose 仅解除前后端引用关系，回调即便触发也在 GC 或进程退出等不确定时机，不可作为清理时机的依据；
   - BuilderNode 本身没有 `aboutToAppear` / `aboutToDisappear` 生命周期，它是命令式对象；
   - 宿主 `@Component` 的 `aboutToDisappear` 会正常触发，可在其中调用 NodeController 的清理方法。

## 诊断与修复

### 发现问题时

- **诊断**：BuilderNode 内部自定义组件的 `aboutToDisappear` 未被触发，导致其中的资源清理逻辑未执行，出现定时器泄漏、事件未解绑等问题。
- **原因**：BuilderNode 不是声明式自定义组件，不触发 `@Component` 的 `aboutToDisappear` 生命周期回调。BuilderNode 持有后端实体节点的强引用，组件不会随声明式树的销毁流程自动销毁，`aboutToDisappear` 的触发与声明式树的渲染流程不一致。这是设计行为，非缺陷。
- **修复方向**：不依赖 `aboutToDisappear` 自动触发，分两步修复（均为必选）：
  1. **清理逻辑前移（剪切而非复制）**：将内部组件 `aboutToDisappear` 中的清理逻辑**剪切**到 NodeController 的释放方法中，在调用 `dispose()` 之前显式执行。**内部组件 `aboutToDisappear` 中的原清理语句必须删除**（方法本身保留即可），否则 GC 或进程退出时回调触发会导致清理逻辑重复执行（重复关闭连接、重复解绑等）；
  2. **宿主兜底**：在宿主 `@Component` 的 `aboutToDisappear` 中调用该释放方法，覆盖页面退出路径。
- **修复代码模式**（三处改动：①剪切 ②新增 ③兜底）：
```typescript
// ① 内部组件：aboutToDisappear 方法保留，但清理语句已剪切走（防止回调晚触发时重复执行清理）
@Component
struct MyComponent {
  @Prop text: string = '';
  aboutToDisappear() {
    // 清理逻辑已前移到 release()（dispose 前显式执行），不依赖此回调
  }
  build() { Text(this.text).fontSize(20) }
}

// ② NodeController 释放方法：清理逻辑前移到这里，dispose 前显式执行
class LifecycleController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  release() {
    console.log('清理资源')           // 从内部组件 aboutToDisappear 中剪切过来的清理逻辑
    this.builderNode?.dispose();      // 释放后端引用
    this.builderNode = null;
  }

  makeNode(context: UIContext): FrameNode | null { /* ... */ }
}

// ③ 宿主组件 aboutToDisappear 兜底（页面退出路径也走 release）
@Entry
@Component
struct HostPage {
  private controller: LifecycleController = new LifecycleController();

  aboutToDisappear() {
    this.controller.release();        // 宿主销毁时兜底：先清理再 dispose
  }

  build() {
    Column() {
      NodeContainer(this.controller)
      Button('Release').onClick(() => { this.controller.release(); })
    }
  }
}
```

修复后：点击释放按钮或页面退出时，清理逻辑在 `dispose()` 前确定性执行**且仅执行一次**（内部组件回调已清空，GC/进程退出时不会重复执行），不依赖 `aboutToDisappear` 回调时机。

### 未发现问题时

BuilderNode 内部组件的资源清理逻辑已剪切前移到 NodeController 释放方法中、在 `dispose()` 前显式执行，内部组件 `aboutToDisappear` 中不再包含清理逻辑；宿主组件的 `aboutToDisappear` 中调用了该释放方法。不报告。

## 规则依据

- [节点 FAQ](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-node-faq.md)："自定义组件的 aboutToDisappear 回调异常"章节——4 种原因及解决方案，BuilderNode 不触发 aboutToDisappear 是设计行为。
- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："解除实体节点引用关系"章节——BuilderNode 持有后端强引用，须通过 dispose 主动管理生命周期。
