# 测试用例与规格对应

本目录默认执行3个触发用例和46个功能用例。下表说明每个用例的测试内容，并链接到用例正文及对应规格；具体输入和验证标准以用例正文为准。

| 文件 | 测试内容 | 数量 |
|---|---|---|
| [trigger.md](trigger.md) | 判断请求是否属于本skill的分析范围 | 3 |
| [functional.md](functional.md) | 验证性能机制、修改方案、语义保持及验证方法 | 46 |

## 触发范围

| 用例 | 测试内容 | 对应规格 |
|---|---|---|
| [TRIGGER-001](trigger.md#测试用例trigger-001) | 首页冷启动首帧慢，应触发性能分析 | [分析范围](../SKILL.md#工作流程与边界) |
| [TRIGGER-002](trigger.md#测试用例trigger-002) | 新增设置开关和Preferences持久化，不触发性能分析 | [分析范围](../SKILL.md#工作流程与边界) |
| [TRIGGER-003](trigger.md#测试用例trigger-003) | Swiper翻页、页签切换卡顿和重复创建，应触发性能分析 | [场景与机制路由](../SKILL.md#机制路由) |

## 组件与状态

| 用例 | 测试内容 | 对应规格 |
|---|---|---|
| [FUNC-REUSE-001](functional.md#测试用例func-reuse-001) | 同父组件反复显示新记录，启用V1复用并同步字段、重置展开状态 | [同结构组件复用](../references/component/reuse-and-keys.md#性能示例实际启用相同子树结构组件复用) |
| [FUNC-WORK-001](functional.md#测试用例func-work-001) | 消除getData整表复制及key、文本回调中的重复序列化 | [高频路径重复工作](../references/component/frequent-work.md) |
| [FUNC-REUSE-003](functional.md#测试用例func-reuse-003) | 相同结构按唯一记录ID分组导致无法共享缓存，改为默认组或固定结构组 | [按记录ID过细分组](../references/component/reuse-and-keys.md#独立边界子树结构相同的新记录按唯一-id-拆池) |
| [FUNC-BUILDERNODE-001](functional.md#测试用例func-buildernode-001) | 相同BuilderNode子树更新文案时使用update，避免dispose/new/build | [BuilderNode更新与回收](../references/component/buildernode-and-global-reuse.md#buildernode-更新与回收) |
| [FUNC-GLOBAL-REUSE-001](functional.md#测试用例func-global-reuse-001) | API12跨父切换且旧父销毁时，用BuilderNode保存、转交和释放节点 | [BuilderNode跨父共享](../references/component/buildernode-and-global-reuse.md#使用-buildernode-保存和转交节点) |
| [FUNC-PROP-001](functional.md#测试用例func-prop-001) | 子组件只读caption时缩小大对象传参，保留父到子同步和父侧完整数据 | [传参成本与同步语义](../references/component/data-transfer.md) |
| [FUNC-AREA-001](functional.md#测试用例func-area-001) | onAreaChange回写自身宽度形成布局反馈，分离测量值与布局输入 | [区域变化与布局反馈](../references/component/frequent-work.md#onareachange区域变化与布局反馈) |
| [FUNC-REUSE-005](functional.md#测试用例func-reuse-005) | 图表和摘要子树不同，按结构设置reuseId以减少跨结构拆建 | [不同子树结构分组](../references/component/reuse-and-keys.md#不同子树结构组件的复用分组) |
| [FUNC-LOCAL-STATE-001](functional.md#测试用例func-local-state-001) | V2复用重置Local后，按联系人ID保存和恢复编辑内容 | [V2复用与本地状态](../references/component/reuse-and-keys.md#v2-复用的性能检查) |
| [FUNC-STATE-001](functional.md#测试用例func-state-001) | V1对象仅修改value却关联unit更新，用Track或等价状态拆分缩小范围 | [状态观测与更新范围](../references/component/state-observation.md) |
| [FUNC-BUILDER-001](functional.md#测试用例func-builder-001) | 保留if创建/移除流程，用Builder减少纯展示组件封装开销 | [纯展示组件与Builder](../references/component/display-builder.md) |

## 启动

| 用例 | 测试内容 | 对应规格 |
|---|---|---|
| [FUNC-START-001](functional.md#测试用例func-start-001) | 首屏只需少量条目时改为按需创建，保留完整数据源、key和滚动范围 | [首屏列表创建](../references/startup/list-creation.md) |
| [FUNC-LIFECYCLE-002](functional.md#测试用例func-lifecycle-002) | 识别async/await前后的UI线程计算，复用重复结果或后台执行并处理失效 | [生命周期同步工作](../references/startup/lifecycle-work.md#abouttoappear-与-asyncawait-的执行边界) |
| [FUNC-STARTUP-IMAGE-LAYOUT-001](functional.md#测试用例func-startup-image-layout-001) | 大图异步加载，首次按200×100vp及说明高度占位，避免onComplete二次改尺寸 | [图片加载与尺寸占位](../references/startup/image-loading.md) |
| [FUNC-STARTUP-PREBUILD-001](functional.md#测试用例func-startup-prebuild-001) | 在前置内容稳定显示期间提前构建首页，保留快速进入、回退和节点释放 | [首页提前构建](../references/startup/home-prebuild.md) |
| [FUNC-STARTUP-HIDDEN-001](functional.md#测试用例func-startup-hidden-001) | 初始隐藏且无需保留状态的复杂面板改为if按需创建 | [初始隐藏组件](../references/startup/initial-visibility.md) |
| [FUNC-STARTUP-LAYOUT-001](functional.md#测试用例func-startup-layout-001) | 删除没有独立职责的中间容器，保持显示、适配和点击行为 | [布局容器冗余](../references/startup/layout-redundancy.md) |

## 列表与滑动

| 用例 | 测试内容 | 对应规格 |
|---|---|---|
| [FUNC-REPEAT-001](functional.md#测试用例func-repeat-001) | Repeat使用稳定业务key，避免序列化整对象并保留当前项响应绑定 | [Repeat重复计算](../references/component/frequent-work.md#repeat检查实际调用路径)、[Repeat规则](../references/component/reuse-and-keys.md#repeat-性能检查) |
| [FUNC-SCROLL-REUSE-001](functional.md#测试用例func-scroll-reuse-001) | V1列表同时实现LazyForEach按需创建和Reusable复用，给出数据源及字段更新代码 | [滑动组件复用](../references/scroll/component-reuse.md)、[懒加载](../references/scroll/lazy-loading.md) |
| [FUNC-SCROLL-LAZY-001](functional.md#测试用例func-scroll-lazy-001) | 已懒加载的图片网格提前准备资源，减少白块并限制缓存、重复及过期请求 | [图片预取与按需创建](../references/scroll/lazy-loading.md) |
| [FUNC-SCROLL-CALLBACK-001](functional.md#测试用例func-scroll-callback-001) | 删除滚动日志和空监听、缓存重复计算，保留真正驱动UI的数据更新 | [高频回调精简](../references/scroll/high-freq-callback.md) |
| [FUNC-SCROLL-FLEX-001](functional.md#测试用例func-scroll-flex-001) | 核对Flex直接子项的伸缩测量，评估等价布局且保留空间分配 | [Flex二次布局](../references/scroll/flex-layout.md) |
| [FUNC-SCROLL-V2-001](functional.md#测试用例func-scroll-v2-001) | API12的V2长列表优先Repeat虚拟滚动，保留数据身份、响应绑定和交互 | [V2按需创建](../references/scroll/lazy-loading.md#v2最小列表)、[Repeat规则](../references/component/reuse-and-keys.md#repeat-性能检查) |
| [FUNC-SCROLL-REUSABLEV2-001](functional.md#测试用例func-scroll-reusablev2-001) | API18+非列表面板启用ReusableV2，正确更新Param并重置Local | [非列表面板复用](../references/scroll/component-reuse.md#滑动检查顺序)、[V2复用规则](../references/component/reuse-and-keys.md#v2-复用的性能检查) |
| [FUNC-SCROLL-LAYOUT-001](functional.md#测试用例func-scroll-layout-001) | 按实际职责精简条目容器，不把内层flexGrow误归因于外层Flex | [滑动布局层级](../references/scroll/layout-depth.md)、[Flex作用范围](../references/scroll/flex-layout.md) |

## 页面转场

| 用例 | 测试内容 | 对应规格 |
|---|---|---|
| [FUNC-TRANS-01](functional.md#测试用例func-trans-01) | Swiper的cachedCount为0时有限预建邻页，减少翻入时集中创建 | [邻页节点缓存](../references/transition/swiper-preload.md#邻页节点缓存) |
| [FUNC-TRANS-02](functional.md#测试用例func-trans-02) | 收敛过大的Swiper缓存，平衡复杂页面驻留内存与快速翻页体验 | [邻页缓存范围](../references/transition/swiper-preload.md#邻页节点缓存) |
| [FUNC-TRANS-03](functional.md#测试用例func-trans-03) | 在onAnimationStart提前准备目标页图片，正确使用缓存并保留加载回退 | [转场资源准备](../references/transition/swiper-preload.md#资源准备与-onanimationstart) |
| [FUNC-TRANS-04](functional.md#测试用例func-trans-04) | 将入场时集中创建的复杂子树分批提交，保持占位、顺序、交互和任务失效 | [重负载子树分帧提交](../references/component/frame-splitting.md) |
| [FUNC-TRANS-07](functional.md#测试用例func-trans-07) | API26页签切换时在持续存在的宿主配置共享池，处理记录更新、动画占用和释放 | [跨父共享实现](../references/component/buildernode-and-global-reuse.md#跨父组件共享的实现) |
| [FUNC-TRANS-09](functional.md#测试用例func-trans-09) | 内容高度变化向外传播布局时，为宿主设置业务允许的稳定边界 | [内容切换的布局边界](../references/component/layout-boundary.md) |
| [FUNC-TRANS-10](functional.md#测试用例func-trans-10) | 先显示可操作的详情框架和骨架，再更新正文，保留返回、重试和请求身份 | [分阶段展示与骨架](../references/startup/staged-display.md) |

## 动画

| 用例 | 测试内容 | 对应规格 |
|---|---|---|
| [FUNC-FRAME-001](functional.md#测试用例func-frame-001) | onFrame仅做位移插值时改为一次animateTo提交，保留往返、禁点、完成和销毁行为 | [手动逐帧与动画API选择](../references/animation/animateTo-patterns.md#检查方法) |
| [FUNC-ANIM-CLOSURE-001](functional.md#测试用例func-anim-closure-001) | 为点击展开补齐动画驱动，保持原触发和最终宽度 | [属性变化与动画驱动](../references/animation/animateTo-patterns.md#检查方法) |
| [FUNC-ANIM-CLOSURE-002](functional.md#测试用例func-anim-closure-002) | 业务允许延后时，将无关文本更新移出动画闭包，在onFinish追加并保持过渡和最终内容 | [闭包内无关状态更新](../references/animation/animateTo-patterns.md#检查方法) |
| [FUNC-ANIM-CUSTOM-001](functional.md#测试用例func-anim-custom-001) | 有限进度动画由定时器改为系统动画，保留再次开始、100%终态和清理 | [手动逐帧动画替换](../references/animation/animateTo-patterns.md) |
| [FUNC-ANIM-TAB-001](functional.md#测试用例func-anim-tab-001) | 连接实际Tab状态停止/恢复旋转，保证替换驱动有效启动及销毁清理 | [不可见组件控停](../references/animation/redundant-refresh.md) |
| [FUNC-ANIM-DURATION-001](functional.md#测试用例func-anim-duration-001) | 按既定慢速循环意图核对5000ms和无限循环，不擅自缩短时长或新增假设问题 | [业务时长与循环](../references/animation/param-config.md#业务明确要求的时长与循环) |
| [FUNC-ANIM-ITERATIONS-001](functional.md#测试用例func-anim-iterations-001) | 修正iterations为0导致不播放的问题，恢复要求的800ms过渡 | [无效iterations](../references/animation/param-config.md#无效iterations示例) |
| [FUNC-ANIM-RENDERGROUP-001](functional.md#测试用例func-anim-rendergroup-001) | 固定内容随容器整体缩放时评估绘制缓存，核对缓存层级和内存代价 | [renderGroup适用条件](../references/animation/render-group.md#检查方法) |
| [FUNC-ANIM-LAYOUT-001](functional.md#测试用例func-anim-layout-001) | 布局动画改变换动画前核对效果等价，字号需保持时避免整体缩放文字 | [布局与变换动画](../references/animation/animation-impl.md#三类检查) |
| [FUNC-ANIM-TRANSITION-001](functional.md#测试用例func-anim-transition-001) | 条件适用时用TransitionEffect精简显隐状态和回调，保持占位及销毁语义 | [显隐实现方式](../references/animation/animation-impl.md#三类检查) |
| [FUNC-ANIM-MERGE-001](functional.md#测试用例func-anim-merge-001) | 合并同触发、同参数的animateTo调用，同时保留旋转和透明度变化 | [相同参数动画合并](../references/animation/animation-impl.md#三类检查) |
| [FUNC-ANIM-REDUNDANT-001](functional.md#测试用例func-anim-redundant-001) | APNG缓存条目离屏时通过真实controller暂停解码绘制，回屏恢复并保留释放 | [第三方动效控停](../references/animation/redundant-refresh.md#检查方法) |
| [FUNC-ANIM-FLING-001](functional.md#测试用例func-anim-fling-001) | 正确解释fling负初速向底部的方向，按惯性滑动意图核对体验 | [fling方向与体验](../references/animation/param-config.md#fling-方向与体验) |
| [FUNC-ANIM-TRACE-001](functional.md#测试用例func-anim-trace-001) | 只有卡顿症状时先补代码、版本和复现动作，不直接归因或通读动画规则 | [输入条件与分析边界](../SKILL.md#工作流程与边界) |

## 公共判定要求

- 每例独立执行，只向被测模型传入输入；被测skill副本不包含test-cases目录。
- 按该例验证标准判断机制、适用条件、业务语义及最终方案；接受等价实现，只检查实际采用路线的条件。
- 需要代码整改且信息充分时，检查最小diff或可替换代码能否定位、采用，必要改动是否衔接完整；不强制同时给两种形式或复制整个ETS，无需修改时不要求凑代码。
- 报告内容遵循[七项报告要求](../references/report-contract.md)，验证遵循[常用性能验证](../references/verification.md)，具体指标见各用例和对应规格。
