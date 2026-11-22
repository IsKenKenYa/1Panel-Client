# 前置页展示期间提前构建首页

## 前提与机制

启动先显示前置页面，进入首页时才集中创建复杂子树，且这段构建工作进入响应关键路径。首页去向和所需数据已确定、业务允许提前创建，并有不妨碍前置页显示与交互的准备时机时，可提前构建首页。启动与转场共用本规则。

Bad 是“前置页展示 → 点击进入 → 此时才首次 BuilderNode.build → 挂载首页”；Good 是“前置页已稳定 → 提前首次 build 并持有节点 → 点击进入时更新参数并挂载”。提前的是 UI 子树构建，不是仅请求数据，也不是让首页提前盖住前置页。与[骨架方案](staged-display.md)相比，本项处理构建成本前移，而非先展示占位等待数据。

按[预创建与回收复用选型](../component/buildernode-and-global-reuse.md#预创建与回收复用的选型)，本项优先 BuilderNode；不把 GlobalReuse 的实例预创建等同于子树已展开。节点寿命、容量、绑定与释放只在共享 BuilderNode 规则维护。

读取前置页显示、首页进入、节点创建和挂载的实际调用路径；确认等待发生在 UI 构建阶段。首次直接进入首页、没有可利用的前置阶段，或主要耗时来自数据尚未就绪时，不要求增加预构建。无前置页、应用直接进入首页时，在 `aboutToAppear` 中调用 `prepare` 完成必要构建是合理初始化，不因该调用本身认定首帧耗时问题，也不据此建议延迟或增加前置阶段。

## 检查方法

1. 从进入首页的处理跟到 BuilderNode.build 或目标子树构建，确认工作是否全部集中在进入动作之后。前置内容稳定展示后，在合适时机准备确定会使用的首页内容，进入时使用已准备的节点；不要在前置页首帧之前无条件构建全部首页。
2. 核对构建参数是否已就绪、是否会过期，以及生命周期中的订阅、计时器或请求是否允许提前启动。节点需要在有效 UIContext 中创建；UI 节点构建不搬到 TaskPool/Worker。
3. NodeController.makeNode 返回准备好的节点，进入时不再次 new/build 或提前 dispose。若准备尚未完成或被取消，保留正常创建的处理；挂载前核对最新参数。
4. 预构建范围以首页实际需求为准，记录未进入首页时的内存成本，并在放弃进入或所属窗口结束时释放。参数更新、单容器绑定和最终释放要求直接沿用[BuilderNode 规则](../component/buildernode-and-global-reuse.md#buildernode-更新与回收)，不另建一套复用机制。

BuilderNode 的基础 build/update 从 API 11 起支持；使用 dispose 时要求 API 12+。按实际使用接口核对工程版本，不依赖 API 26.0.0 的全局复用池。

## Bad case

前提：前置页已显示，首页参数已确定，同一 UIContext 内允许提前创建该子树。

```ts
// 若只在进入时调用，构建工作仍集中在进入动作之后
enterHome(context: UIContext): void {
  this.controller.prepare(context);
  this.showHome = true;
}
```

## Good case

在现有前置页稳定显示、首页参数已就绪的业务路径中，提前调用准备方法：

```ts
this.controller.prepare(this.getUIContext());
```

后续进入首页时，使用已准备的节点，同时保留未提前准备时的正常创建路径：

```ts
enterHome(context: UIContext): void {
  this.controller.prepare(context);
  this.showHome = true;
}
```

prepare 应复用同一 UIContext 内已持有的 BuilderNode，只有尚未创建时才 build，并在挂载前更新最新参数；makeNode 返回该节点。进入方法可以保留相同调用，优化来自更早的实际准备和避免重复构建。不能只换函数名，或仅定义准备方法却仍只在进入时调用。

## 建议与验证

回归快速跳过、准备未完成、参数变化、放弃进入和窗口结束，避免为减少进入等待而劣化前置页首帧或保留无用节点。首次直接进入首页且没有可利用前置阶段的代码，不要求增加前置页或预构建流程。

## 打点与预期变化

分别比较前置页首次显示及交互、进入首页动作到首页显示、启动到首页初始内容就绪，并记录 new/build、挂载、最终释放与存活数量。预期构建工作前移、进入时的集中创建减少；首次创建总量未必减少，启动总时长也未必缩短。

BuilderNode.build 表示创建组件树，不能仅凭 build 完成断言首页布局、绘制和送显全部完成。挂载之后仍可能有布局与渲染工作，应关联实际帧观察。

## 依据

[提升应用响应速度：使用 NodeContainer 提前渲染降低响应时延](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/improve-application-response.md#使用nodecontainer提前渲染降低响应时延)、[BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)、[NodeController](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-nodeController.md)。
