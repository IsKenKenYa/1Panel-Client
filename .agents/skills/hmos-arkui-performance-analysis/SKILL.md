---
name: hmos-arkui-performance-analysis
description: 基于真实 ArkTS 代码，只读分析 ArkUI 组件刷新与复用、列表滑动、页面转场、首页启动和动画性能问题。适用于刷新范围过大、重复创建、Swiper 翻页卡顿、页签或路由进入慢、转场集中构建、滑动或动画掉帧、首页首帧及内容显示慢，输出问题位置、原因、修改建议和验证方法。
license: MIT
metadata:
  author: liwenzhen
  version: "1.0.0"
---


# ArkUI 性能分析

基于授权的真实 ArkTS 代码，只读分析组件、启动、滑动、转场与动效性能；同一位置和根因跨场景只报告一次。

## 工作流程与边界

1. 明确目标动作和观察阶段。输入只有症状、没有应用代码或授权文件路径时，先索取相关代码、版本与复现条件，不扫描其他目录，也不为补材料先通读整场景规则。已有代码时读取必要页面、子组件和调用函数；未知函数不能凭名称定性，条件足够直接给建议，不要求先交 Trace。
2. 工程路径输入先读取同工程根/模块的 build-profile.json5，结合产品与模块确认 compatibleSdkVersion、targetSdkVersion；多产品无法确定时只补问相关选择。编译SDK、设备版本、应用版本不能互相替代。纯片段才说明影响建议的版本缺口。
3. 按实际代码线索选择下表中的机制；代码已能明确排除的机制跳过，拟报告或边界不明时先读详细规则，核对成立条件、状态管理 V1/V2、数据流和语义代价。不能只凭路由摘要诊断，也不因同属一个场景通读所有规则。已确定需要且互不依赖的文件同批读取。
4. 将[性能分析报告与交付](references/report-contract.md)、[验证方法](references/verification.md)随需要的机制规则同批读取，按七项要求组织成立的问题。需要补查采集工具或事件含义时再读[Trace指南](references/trace-guidance.md)；现有验证口径足够时不额外加载工具长文。

只读代码并给建议，不修改应用、不执行应用/设备采集、不上传材料。不能编造代码、行号、接口、耗时、帧率或收益。运行知识不包含 test-cases/ 的预期答案。未实现的专项如实说明；不扩展成运行时、网络或ArkWeb全链路归因。

## 机制路由

| 场景与线索 | 读取规则 |
|---|---|
| 对象字段观测、UI依赖或无关属性刷新 | [状态观测](references/component/state-observation.md) |
| @Prop对象复制、过大传参载荷或父子同步/编辑隔离；仅基本值初始化@State且无复制线索时跳过 | [数据传递](references/component/data-transfer.md) |
| 展示封装 | [展示与Builder](references/component/display-builder.md) |
| 同父实例回收/再加入、key、V2本地编辑值 | [复用与key](references/component/reuse-and-keys.md) |
| 跨父共享、父实例销毁 | [跨父共享方案](references/component/buildernode-and-global-reuse.md#跨父组件共享的实现)：API26.0.0起优先在持续存在的上层配置reusePool/poolAccepts；API12由应用保存并转交BuilderNode节点 |
| BuilderNode参数更新、同结构重复构建 | [节点更新与回收](references/component/buildernode-and-global-reuse.md#buildernode-更新与回收) |
| 回调/参数重复计算、集中提交UI、布局反馈或边界 | [高频工作](references/component/frequent-work.md)、[分帧提交](references/component/frame-splitting.md)、[布局边界](references/component/layout-boundary.md) |
| 首页首屏全量创建、隐藏子树 | [列表创建](references/startup/list-creation.md)、[初始可见性](references/startup/initial-visibility.md) |
| 生命周期/进入路径中的同步重工作、资源准备或生命周期监听；仅注册轻量定时任务不触发 | [生命周期](references/startup/lifecycle-work.md) |
| 无明确职责的重复容器、冗余布局（不限启动） | [冗余布局](references/startup/layout-redundancy.md) |
| 图片加载与占位 | [图片加载](references/startup/image-loading.md) |
| 关键内容等待、非关键内容阻塞展示 | [分阶段展示](references/startup/staged-display.md) |
| 前置页准备首页、首页重复构建 | [首页提前构建](references/startup/home-prebuild.md) |
| 长列表全量创建、图片预取 | [懒加载](references/scroll/lazy-loading.md) |
| 滚动条目复用、非列表面板回收 | [滑动复用入口](references/scroll/component-reuse.md)及[共享复用规则](references/component/reuse-and-keys.md) |
| 滚动回调、层级或Flex | [滑动回调](references/scroll/high-freq-callback.md)、[滑动布局](references/scroll/layout-depth.md)、[Flex](references/scroll/flex-layout.md) |
| 动画缺失、手动逐帧（含onFrame插值）、闭包内无关状态更新 | [动画API](references/animation/animateTo-patterns.md) |
| 原代码的动画参数、明确的时长/循环体验问题 | [参数配置](references/animation/param-config.md) |
| Scroller.fling惯性滚动（正值向顶部、负值向底部） | [fling方向与体验](references/animation/param-config.md#fling-方向与体验) |
| 已知不可见期间仍在执行刷新 | [不可见刷新](references/animation/redundant-refresh.md) |
| 固定复杂子树的整体变换、已有renderGroup缓存的收益或失效 | [renderGroup](references/animation/render-group.md) |
| 布局属性动画、布局/变换替代或相同参数多次animateTo | [实现方式](references/animation/animation-impl.md) |
| Swiper翻页、相邻页缓存与资源准备 | [Swiper](references/transition/swiper-preload.md)；页签共享、集中创建、进入计算、骨架和提前构建分别复用上面的共享规则 |

先分清按需创建与实例复用：V2长列表优先Repeat，LazyForEach并非V1独占；同父非列表API18+评估@ReusableV2，真实复用时@Param按新参数初始化、@Local按初值重置，跨记录编辑值按ID外置；跨父共享另核对池的寿命与版本。

启动区分首帧、首次有效内容和完整内容就绪；转场区分首次反馈、入场动画和完整内容。旧页隐藏不等于销毁，业务动画时长不等于卡顿。CPU工作与分批UI提交分别处理；可见性控停须有不可见期间仍持续工作的代码或业务依据。

## 输出检查

- [ ] 报告围绕成立的问题和当前适用方案；同一事实不在多个栏目重复展开，正常写法、未命中项及无关覆盖信息留在内部；只在需要方案比较时展开其他V1/V2路线
- [ ] 每个发现包含可核验的代码证据和成立条件；不把代码审查发现写成实测耗时、帧率或收益
- [ ] 需要代码整改且信息充分时，给出可定位的最小diff或可替换代码；必要的字段、回调和调用处衔接完整
- [ ] 建议保持输入声明的动效、时序、交互与数据身份；验证对应当前目标，按[验证方法](references/verification.md)选择适用口径
- [ ] 用户要求的专项未实现时才说明覆盖缺口；不罗列无关模块状态，未分析不等于未实现
- [ ] 不读取 test-cases/ 中的预期答案；测试用例不属于运行知识
