# ArkUI 通用无障碍快速接入 Skill — 评测集（B01~B20）

> 用例基准：需求方输入 `../proposal_full.md` 用例清单。
> 每条用例：开发者 Prompt（输入）→ 环境构造 → 可验证预期（判定标准）→ 映射（spec AC + 需求方判定点族）。
> 执行方式见 `README.md`；结果回填 `report-template.md`。

## 用例

### B01 泛化诉求走 D0 门（不直接生成代码）

| 项 | 内容 |
|----|------|
| 开发者 Prompt | "应用准备适配无障碍，但还不知道从哪里开始。" |
| 环境构造 | 普通 ArkTS 工程，未提供具体组件或高阶诉求 |
| 可验证预期 | ① 首先输出 D0 门要素：默认播报组件类型、文本内容、操作结果、当前状态；② 指出无文本图标/图片、自绘内容、需显式状态语义等边界；③ 说明可识别、功能及操作信息、状态与行为三个前提；④ 明确询问默认能力是否满足；⑤ **不直接生成属性代码** |
| 映射 | AC-1 / 判定点 AC-0A |

### B02 无文本图标加播报（A 类）

| 项 | 内容 |
|----|------|
| Prompt | "这个播放图标没有文字，读屏不知道它是干什么的，提供一个适配方案。" |
| 环境 | API 12+；`Image($r('app.media.play')).onClick(...)` |
| 预期 | ① 诉求明显超出默认能力，不重复询问 D0；② 判定 A 类并说明依据；③ 给 `.accessibilityText('播放')`；④ 说明改前/改后播报差异，系统仍补充组件类型和操作提示；⑤ 文案不混入操作引导或状态信息 |
| 映射 | AC-1 / AC-2 / 判定点 AC-0C、AC-1A、AC-2A/2C |

### B03 覆盖语义强制确认（就地修改既有文本）

| 项 | 内容 |
|----|------|
| Prompt | "这个按钮本来显示'提交订单'，需要把 accessibilityText 改成'支付 99 元'。" |
| 环境 | API 12+；目标文件和 Button 唯一，Button 已有可见文本；输入未确认（不含"直接修改"类指示），测未确认防护路径（已确认/直接修改路径由 FUNC-TEXT-002 覆盖） |
| 预期 | ① 改动前强制提示：设置 accessibilityText 后原文本"提交订单"不再播报；② 取得开发者确认，未确认前不修改；③ 讲清 text 表达"是什么"，操作后果应放 description |
| 映射 | AC-1 / AC-2 / 判定点 AC-2B/2C、AC-10B |

### B04 操作后果说明（B 类，方案模式）

| 项 | 内容 |
|----|------|
| Prompt | "全屏按钮聚焦时只说'单指双击即可执行'，怎样让用户知道点了会进入全屏？这个提示必须保证每个人都听到。" |
| 环境 | API 10+；可点击 Button |
| 预期 | ① 判定 B 类；② 按方案输出且不改文件；③ 给 `.accessibilityDescription('单指双击即可全屏')`；④ 说明其在文本后播报并替代默认新手提醒；⑤ 明确警示用户关闭新手提醒后 description 也不播报，不能承诺必达 |
| 映射 | AC-1 / AC-3 / 判定点 AC-3A~3C、AC-8A、AC-10B |

### B05 整组朗读（C 类）

| 项 | 内容 |
|----|------|
| Prompt | "日期由年、月、日三个 Text 组成，现在要聚焦三次，怎么让它一次读完？" |
| 环境 | API 12+；三个 Text 位于同一 Column |
| 预期 | ① 判定 C 类；② 在**容器**给 `.accessibilityGroup(true)`；③ 说明容器成为聚焦单元、子 Text 拼接播报不再分别聚焦；④ 不错误地给每个 Text 单独加 text |
| 映射 | AC-1 / 判定点 AC-4A |

### B06 可识别性控制（D 类，no vs no-hide-descendants）

| 项 | 内容 |
|----|------|
| Prompt | "页头有个纯装饰图标不要读，但它下面的返回按钮必须保留；另一个三方应用容器和所有子节点都不要读。" |
| 环境 | API 12+；一个装饰 Image、一个含子节点的三方应用容器 |
| 预期 | ① 判定 D 类；② 装饰图标 `accessibilityLevel('no')`；③ 三方容器 `'no-hide-descendants'`；④ 明确前者只隐藏当前节点、后者连同后代隐藏；⑤ 补充 auto 决策指引：`auto` 由无障碍服务与 ArkUI 综合判断、不保证聚焦或隐藏结果——本例"必须保留/必须不读"属确定性诉求，**不给 auto**、给显式取值建议，并传递"auto 结果不确定，确定性诉求须使用显式取值"；⑥ `yes` 强制可识别 |
| 映射 | AC-1 / AC-2 / 判定点 AC-5A~5C |

### B07 选中状态组合（E 类，checked vs selected）

| 项 | 内容 |
|----|------|
| Prompt | "当前页面的 checked 组件读不出当前状态，应该都加 accessibilityChecked 吗？" |
| 环境 | build-profile 三个 SDK 字段均为 13+ |
| 预期 | ① 判定 E 类组合场景；② 开关使用 checked，互斥标签页使用 selected，不混用；③ 先完成版本检查（三字段 ≥13）；④ 输出 checked/selected 对比表，至少覆盖常见场景、语义目标、状态持久性、典型组件；⑤ 说明 checked 为 undefined 时可由系统依据组件状态判断 |
| 映射 | AC-1 / AC-2 / 判定点 AC-1D、AC-6A~6D |

### B08 版本门禁阻断（compatibleSdkVersion < 13）

| 项 | 内容 |
|----|------|
| Prompt | "给工程的复选框加上选中状态播报。" |
| 环境 | `compileSdkVersion: 13`、`compatibleSdkVersion: 12`、`targetSdkVersion: 13` |
| 预期 | ① 读取三个字段并因 compatibleSdkVersion < 13 **阻断** E 路径；② 说明属性需 API 13+；③ 给出将相关字段提升到 13+ 的具体修改建议；④ 不生成 `accessibilityChecked` 代码 |
| 映射 | AC-1 / AC-2 / 判定点 AC-1D/1E、AC-6D |

### B09 A+E 组合（正交配合）

| 项 | 内容 |
|----|------|
| Prompt | "这个无文字收藏图标还要让读屏知道收藏是否勾选，一起适配。" |
| 环境 | build-profile 三字段均为 13+；唯一 Image 目标 |
| 预期 | ① 判定 A+E 组合并说明两个能力正交：text 传用途、checked 传状态；② 先检查 E 版本门；③ 给组合代码及 checked/selected 对比；④ 不把状态塞进 accessibilityText |
| 映射 | AC-1 / AC-2 / 判定点 AC-1A/1B/1D、AC-2C、AC-6A~6D |

### B10 虚拟节点（F 类，Canvas 折线图）

| 项 | 内容 |
|----|------|
| Prompt | "Canvas 画的折线图完全读不到，请让读屏读出当前数据趋势。" |
| 环境 | build-profile 三字段均为 11+；自绘组件目标明确 |
| 预期 | ① 判定 F 类；② 先检查三字段（≥11）；③ 给 `@Builder` 虚拟节点及 `.accessibilityVirtualNode(this.customAccessibilityNode)` 方案（builder 以方法引用直传，禁用 lambda/对象包裹）；④ **builder 内单个 Text 直述**（默认播报即可，不套容器 group(true)+子 accessibilityText——合并文本只拼子组件通用文本，vod-5）；⑤ 说明辅助工具读取虚拟节点语义而非实际绘制内容 |
| 映射 | AC-1 / 判定点 AC-1D、AC-7A~7C |

### B11 版本门禁阻断（F 类，< 11）

| 项 | 内容 |
|----|------|
| Prompt | "自绘仪表盘加一个 accessibilityVirtualNode" |
| 环境 | 三个 SDK 字段中至少一个为 10 |
| 预期 | ① 阻断 F 路径；② 明确需 API 11+ 并给提升字段的具体方法；③ 不输出 virtualNode 任何代码（含"方案示意"形式）；④ 若 build-profile 缺失或字段缺失，改为请求补充版本，不臆测放行 |
| 映射 | AC-1 / 判定点 AC-1D~1F、AC-7C |

### B12 就地修改（保留原属性链）

| 项 | 内容 |
|----|------|
| Prompt | "把 pages/Player.ets 里唯一的 playIcon 图片按钮改成读屏播报'播放'。" |
| 环境 | API 12+；文件存在且目标实例唯一；组件已有尺寸、颜色、点击事件等属性链 |
| 预期 | ① 就地追加 `.accessibilityText('播放')`；② 保留原属性、样式和事件链；③ 改后展示改动说明、路由依据及版本/覆盖语义提示；④ 不改无关文件 |
| 映射 | AC-1 / AC-2 / 判定点 AC-2A、AC-9A、AC-10B |

### B13 事件回调组合（hover+focus，版本差异软提示）

| 项 | 内容 |
|----|------|
| Prompt | "读屏用户单指摸到这个可聚焦卡片时预览详情，焦点进入时展开、离开时收起。工程 targetSdkVersion 是 17，给方案。" |
| 环境 | 三字段至少一个为 17；只要方案，不改文件 |
| 预期 | ① 判定 G 类组合；② 给 `onAccessibilityHover`（AccessibilityHoverEvent，开启无障碍后单指触摸触发）和 `onAccessibilityFocus`（移入/移出，undefined 可取消注册）；③ 逐方法提示 hover 需 12+、focus 需 18+，对 focus 做软提示但不阻断；④ 说明属性与方法可叠加；⑤ 不修改文件 |
| 映射 | AC-1 / AC-3 / 判定点 AC-1B/1G、AC-8A、AC-11A/11C/11F |

### B14 C+D+A 组合（反 group）

| 项 | 内容 |
|----|------|
| Prompt | "把生日的三个 Text 合成一次播报，但其中唯一的年份 Text 仍要能单独聚焦并播报'出生年份'。" |
| 环境 | API 12+；目标容器和年份 Text 唯一 |
| 预期 | ① 判定 C+D+A 组合；② 一次落齐：容器 group、年份节点 level 'yes' 和 text，不留半成品；③ 保留既有链；④ 说明分组后的默认行为及为何对年份做例外；⑤ 展示改动说明 |
| 映射 | AC-1 / 判定点 AC-1B、AC-4A/4B、AC-5A、AC-9A/9C |

### B15 覆盖语义答疑（为什么没有默认读文本/操作行为能力）

| 项 | 内容 |
|----|------|
| Prompt | "这个组件为什么没有系统默认的读文本和操作行为的能力" |
| 环境 | API 12+；组件同时设置了 accessibilityDescription 和 accessibilityText |
| 预期 | 开发者未意识到覆盖语义；Skill 解释：text 覆盖原文本播报、description 替代新手提醒，给出恢复默认或调整的建议 |
| 映射 | AC-2 / 判定点 AC-2 族 |

### B16 首焦点（G 类）

| 项 | 内容 |
|----|------|
| Prompt | "xx页面里，xx组件是核心的，希望其首个获焦，无障碍也首个朗读，怎么做" |
| 环境 | API 18+；accessibilityDefaultFocus |
| 预期 | 开发者不知道用哪个自定义获焦接口；Skill 给 `accessibilityDefaultFocus(true)` 并说明与 nextFocusId 的语义差异（版本软提示） |
| 映射 | AC-2 / AC-3 / 判定点 AC-2 族 |

### B17 下一焦点（G 类）

| 项 | 内容 |
|----|------|
| Prompt | "xx组件获焦后，也希望下一个获焦的焦点是xx组件，而不是默认的下一个，要怎么做" |
| 环境 | API 18+；accessibilityNextFocusId |
| 预期 | Skill 给 `.accessibilityNextFocusId('target_id')`（目标组件需有 id），说明走焦语义与版本软提示；**仅目标组件加 .id()**，源组件不加（简约性，vod-6） |
| 映射 | AC-2 / AC-3 / 判定点 AC-2 族 |

### B18 下一焦点进入子节点（G+，API 26）

| 项 | 内容 |
|----|------|
| Prompt | "xx组件获焦后，希望其下一个获焦的节点是其子节点要怎么做" |
| 环境 | API 26+；accessibilityNextFocusId + isConsiderDescendants |
| 预期 | Skill 给 nextFocusId 并显式传 `{ isConsiderDescendants: true }`（非默认值，默认 false）；仅目标容器加 .id() |
| 映射 | AC-2 / AC-3 / 判定点 AC-2 族 |

### B19 下一焦点跳过子节点（G+，API 26）

| 项 | 内容 |
|----|------|
| Prompt | "xx组件获焦后，希望其下一个获焦的节点跳过其子节点，要怎么做" |
| 环境 | API 26+ |
| 预期 | 跳过目标子节点为**默认行为**（isConsiderDescendants 默认 false）：**不传第二参数**，显式传 false 属默认值冗余（vod-6）；仅目标组件加 .id()，源组件不加 id |
| 映射 | AC-2 / AC-3 / 判定点 AC-2 族 |

### B20 触摸改文案（onAccessibilityHover）

| 项 | 内容 |
|----|------|
| Prompt | "xx组件被触摸了，希望其文字改成'已检查完成'怎么做" |
| 环境 | API 12+；`onAccessibilityHover` |
| 预期 | 开发者不知道无障碍触摸回调；Skill 给 `.onAccessibilityHover((event: AccessibilityHoverEvent) => {...})` 内更新 @State 文案（并提示该回调在开启无障碍后触发，API 12+） |
| 映射 | AC-2 / AC-3 / 判定点 AC-2 族 |

## 判定口径

- **编译成功**：Skill 输出代码放入环境构造的工程后 hvigor 构建通过（无编译错误）；
- **功能正确**：逐条核对"可验证预期"编号项全部满足；
- 指标 = 通过用例数 / 总用例数（编译口径、正确率口径分别统计）。
