# 初始隐藏组件

## 前提与机制

初始不显示但仍创建复杂子树，且没有必须保留实例的业务需求。visibility 隐藏并不等于不创建。

Hidden 保留布局占位，None 不占位，但二者均不等同条件分支不创建。需要占位、频繁切换或保持实例状态时，保留 visibility 可能更合适。

区分“创建”与“参与布局/送显”：Visibility.None 的隐藏子树不参与布局、不送显，但实例与子树仍创建（aboutToAppear 仍执行、构建工作仍发生，只是不进入布局/绘制流程）；Hidden 参与布局占位。不能用“实例已创建”推断“参与首帧布局”，创建成本需结合实际构建记录判断，不能断言隐藏子树已完成布局或参与布局流程。

## 检查方法

1. 读取初始可见性、实际子树、是否占位、显隐频率及组件内部状态保持要求，不凭变量名推断。
2. 初始不显示且不频繁切换时，评估 if 条件创建；确认从显隐改为创建/销毁对生命周期与状态的影响。
3. 缺少 show 初值、占位要求或切换路径时，先补充对应信息。

## Bad case

前提：show 初始为 false，面板复杂、无需占位、极少打开，也没有必须保留实例的业务需求。

```ts
ComplexPanel().visibility(this.show ? Visibility.Visible : Visibility.None)
```

## Good case

```ts
if (this.show) {
  ComplexPanel()
}
```

未打开时不创建该面板，首次打开时再创建。

**合理反例**：高频显隐或需占位的场景应保留 visibility（Hidden 保留布局占位），不应改用 if 条件渲染移除；必须保持实例状态的场景同样保留。

## 建议与验证

核对初始界面、切换后布局、内部状态与生命周期副作用；需要占位不能直接删除。
代码与条件足够时直接给建议，不要求 Trace。必要信息已检查仍无法解释持续慢，再使用 [Trace 指导](../trace-guidance.md) 选择相关阶段。

## 打点与预期变化

日志方法可在目标面板的初始化位置记录执行，比较相同启动和打开动作。改为 if 条件创建后，预期未打开时不执行面板初始化，首次打开时再执行。Trace 方法可同时给出两个观察窗口：在应用 UI 线程搜索首页实际路径的 `load page:`，例如 `load page: pages/Index`，选中完整区间读取 Duration；再定位首页首次显示对应的完整 ReceiveVsync，读取 Duration。相同设备、数据与启动条件下分别比较两项，首次打开面板的更新耗时单独比较。不把整个页面的初始化次数当作面板次数，也不把首次打开成本后移视为成本全部消失。

## 依据

[减少首帧绘制时的冗余操作：条件渲染](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reduce-redundant-operations-when-render-first-frame.md#条件渲染)。
