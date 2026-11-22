# 重负载子树的分帧提交

供转场、启动和滑动复用共同使用。它处理同一 UI 帧中的集中构建/测量，不负责把 CPU 计算迁移到后台。

## 成立条件与机制

进入目标页或复用更新时，一次提交的数据实际驱动大量复杂节点在同一帧内创建/测量，且业务允许部分内容晚一帧或多帧显示。先核对布局约束、可见范围和数据通知；LazyForEach 中一次追加 200 条数据，不等于当帧创建或测量全部 200 条。

原文转场 ProductList 用 6 个复杂条目示例，先提交 2 个、后续再提交 4 个，分散首帧负载。批量与数量是案例参数，不是“超过 20/50 项必分帧”的阈值。数据总量不大也可能存在复杂子树集中成本。

## 检查方法

1. 先找到本次数据提交的触发位置，例如页面切换按钮的 onClick、目标组件的 aboutToAppear，或复用组件的 aboutToReuse。沿其中调用的方法，找到状态赋值或数据源的 append/增量通知，再查看哪些子组件依赖这批数据，判断其创建和测量是否集中在本次入场或复用更新的同一帧。这些是不同场景下可能的触发位置，不是依次执行的步骤。
2. 先排除不必要的重复创建、跨结构拆建和纯计算；复用与结构规则读取[复用与 key](reuse-and-keys.md)，CPU 计算读取[生命周期执行边界](../startup/lifecycle-work.md)。同一根因不重复报告。
3. 保留首批关键内容和稳定占位；对允许渐进展示的后续部分按预算提交，保留顺序、最终数量、点击身份和数据变更通知。每批本身仍过重时，应减少子树成本或批量。
4. DisplaySync 回调仍在 UI 主线程执行，不把整批计算搬进 frame 回调。不要为拆工作强制请求 120fps，也不要把每次数据通知视为一个独立送显帧。
5. 完成、隐藏、回收和销毁时停止并解注册。复用到新记录时，先停旧任务、重置游标与当前数据；快速再次进入不能重复注册或混入旧批次。页面保留但隐藏时，按真实导航回调停任务，重新可见后按当前状态继续。

## Bad / Good 对照

前提：API 12、V1；ProductSource 实现完整 IDataSource，append 发出正确增量通知。PRODUCT_DATA 有 6 条本地已就绪数据，复杂 ItemView 均落入此次首屏测量范围，允许先显示 2 条及稳定占位。

```ts
// Bad：目标页进入时整批提交，复杂子树集中在首帧。
aboutToAppear(): void {
  this.products.append(PRODUCT_DATA);
}
```

本例从目标组件的 aboutToAppear 查起：它调用 products.append(PRODUCT_DATA) 提交全部数据，再沿数据绑定检查列表中的复杂 ItemView 是否集中创建和测量。“提交数据”和“后续 UI 布局”分别观察，不能把 append 方法的耗时当作全部布局耗时。

保留原数据源和展示代码；以下是目标组件中的字段与方法，不是独立应用工程。每批 2 条仅用于建立对照。

```ts
import { displaySync } from '@kit.ArkGraphics2D';

private sync: displaySync.DisplaySync | undefined = undefined;
private cursor: number = 0;
private batchSize: number = 2;

private onFrame = (): void => {
  const end = Math.min(this.cursor + this.batchSize, PRODUCT_DATA.length);
  this.products.append(PRODUCT_DATA.slice(this.cursor, end));
  this.cursor = end;
  if (this.cursor >= PRODUCT_DATA.length) {
    this.stopBatches();
  }
};

private startBatches(): void {
  if (this.sync !== undefined || this.cursor >= PRODUCT_DATA.length) {
    return;
  }
  this.sync = displaySync.create();
  this.sync.on('frame', this.onFrame);
  this.sync.start();
}

private stopBatches(): void {
  const current = this.sync;
  this.sync = undefined;
  if (current !== undefined) {
    current.stop();
    current.off('frame', this.onFrame);
  }
}

aboutToAppear(): void { this.startBatches(); }
aboutToDisappear(): void { this.stopBatches(); }
// 同一 NavDestination 可结合 onWillHide 停止、onShown 恢复；
// aboutToRecycle 同样停止；新记录另按当前数据重置任务与游标。
```

在有效 UI 上下文中启动，并按实际导航生命周期接入显示/隐藏事件。示例没有在 startBatches 中清空数据源，恢复时从 cursor 继续，避免重复追加。替换新记录时由业务提供新的数据和失效标识，不沿用上一记录的剩余任务。

## 建议与验证

已有有效按需创建、条目很轻、只测量少量可见项、或业务要求同步完整出现时，不机械分帧。

按同一交互比较每批提交、目标节点 Create/Measure/Layout 和实际帧分布。首批工作应减少、其余工作转到后续帧；完整内容可能更晚，总工作量未必减少。应用 append 的打点只覆盖提交，不包含随后全部布局。缺少可靠帧关联时不承诺“一批恰好一帧”。

原文“转场场景”的[集中处理 Trace](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/figures/highly_loaded_component_transition_normal.png)与[分帧 Trace](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/figures/highly_loaded_component_transition_displaysync.png)可用于解释测量分布；图中数据不是当前工程实测，firstFrame/secondFrame 是示例业务打点。

## 依据

- [合理处理高负载组件的渲染：转场场景](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonably-dispose-highly-loaded-component-render.md)。
- [DisplaySync API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkgraphics2d/js-apis-graphics-displaySync.md)：从 @kit.ArkGraphics2D 导入，核对 create/on/start/stop/off 及接口版本。
