# reuse/recycle 复用事件传递检查

## 检查条件

代码中存在 `@Reusable` / `@ReusableV2` 自定义组件，且该组件内部（或其子组件中）包含 BuilderNode。当外部 @Reusable 组件被复用/回收时，`aboutToReuse` / `aboutToRecycle` 事件无法自动传递到 BuilderNode 内部的自定义组件。凡 @Reusable 组件包裹 BuilderNode 的场景，都需检查是否手动转发了复用事件。

## 检查步骤

1. **检查 @Reusable 组件内是否包含 BuilderNode**：检查 `@Reusable` / `@ReusableV2` 装饰的自定义组件的 `build()` 中是否有 `NodeContainer`（可能承载 BuilderNode）。若有，BuilderNode 会隔断复用事件。
2. **检查 aboutToReuse 中是否调用了 builderNode.reuse**：外部 @Reusable 组件被复用时，`aboutToReuse(params)` 回调触发，但事件不会自动传递到 BuilderNode 内部。需在 `aboutToReuse(params)` 中显式调用 `builderNode.reuse(params)` 转发。
3. **检查 aboutToRecycle 中是否调用了 builderNode.recycle**：同理，需在 `aboutToRecycle()` 中显式调用 `builderNode.recycle()` 转发回收事件。

## 诊断与修复

### 发现问题时

- **诊断**：@Reusable 组件的 aboutToReuse/aboutToRecycle 触发了，但 BuilderNode 内部组件的 aboutToReuse/aboutToRecycle 未触发，复用事件被 BuilderNode 隔断。
- **原因**：BuilderNode 是命令式节点，隔断声明式组件树的复用事件传递链路。外部 @Reusable 组件的复用事件可以传递给直接子组件（不在 BuilderNode 内的），但无法自动广播到 BuilderNode 内部的自定义组件。
- **修复方向**：在 @Reusable 组件的 `aboutToReuse(params)` 中显式调用 `builderNode.reuse(params)`，在 `aboutToRecycle()` 中显式调用 `builderNode.recycle()`，手动转发复用事件。
- **修复代码模式**：
```typescript
@Reusable
@Component
struct ReusableChildComponent {
  @Prop text: string = '';
  private controller: MyNodeController = new MyNodeController();

  aboutToReuse(params: object): void {
    // ✅ 手动转发复用事件到 BuilderNode 内部
    this.controller.builderNode?.reuse(params);
  }

  aboutToRecycle(): void {
    // ✅ 手动转发回收事件到 BuilderNode 内部
    this.controller.builderNode?.recycle();
  }

  build() {
    Row({ space: 8 }) {
      ChildComponent3({ text: this.text })  // 直接子组件，复用事件自动传递
      NodeContainer(this.controller)          // BuilderNode 内部组件，需手动转发
    }
  }
}
```

### 未发现问题时

@Reusable 组件内不包含 BuilderNode，或已在 aboutToReuse/aboutToRecycle 中显式调用了 builderNode.reuse()/recycle()。不报告。

## 规则依据

- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："BuilderNode调用reuse和recycle接口实现节点复用能力"章节——调用reuse和recycle接口，将复用和回收事件传递至BuilderNode中的自定义组件。
- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：reuse() / recycle() 接口说明。
