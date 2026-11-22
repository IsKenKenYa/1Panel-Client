# 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-module-dependency-visualizer
**类型**：functional（功能验证）

#### 输入

我有一份依赖图日志 app_dependency_graph.txt，帮我生成模块依赖可视化报告，输出到 dep_report.html

#### 预期输出

**验证标准**：

- 定位 skill 内嵌工具 `scripts/modtree.exe`，不引导用户另行下载或编译
- 先确认日志文件存在且非空，再在专用输出目录执行 `modtree -o dep_report.html app_dependency_graph.txt`
- 依据 stdout 的 `[OK] 完成！耗时` 与 `HTML:` / `Markdown:` 路径判定成功，不以猜测为准
- 汇报的统计数字（模块数、依赖边数、循环依赖组数）来自工具实际输出
- 说明浏览器自动打开 HTML 属预期行为

**应包含**：modtree, dependency_graph, HTML

---

### 测试用例：FUNC-002

**skill**：hmos-module-dependency-visualizer
**类型**：functional（功能验证）

#### 输入

帮我采集抖音的模块依赖结果

#### 预期输出

**验证标准**：

- 将"抖音"推断为包名 `com.ss.hm.ugc.aweme` 后，先向用户反述确认再执行采集
- 确认设备已 USB 连接（如 `hdc list targets`），无设备时引导连接而非直接失败
- 在专用输出目录执行 `modtree -bundle com.ss.hm.ugc.aweme`（或带 `-o` 指定输出名），exec 设置 ≥120 秒超时
- 不无参数执行 modtree（会进入 TUI 向导阻塞）
- 成功后汇报概览统计与产物路径，存在循环依赖时主动提示

**应包含**：com.ss.hm.ugc.aweme, -bundle

---

### 测试用例：FUNC-003

**skill**：hmos-module-dependency-visualizer
**类型**：functional（功能验证）

#### 输入

把依赖报告输出到 report.html，我目录里已经有一个同名的 report.html 了

#### 预期输出

**验证标准**：

- 检测到输出路径已存在同名文件，先向用户确认是否覆盖
- 用户未确认前不执行覆盖性输出（或建议更换输出文件名）

**应包含**：覆盖, 确认

---

### 测试用例：FUNC-004

**skill**：hmos-module-dependency-visualizer
**类型**：functional（功能验证）

#### 输入

采集一下快手鸿蒙版的依赖

#### 预期输出

**验证标准**：

- 不确定的应用名→包名映射（如非抖音/头条等已知映射）必须向用户询问确认包名，禁止对猜测的包名直接执行 `-bundle` 采集
- 说明原因：真机采集会强杀目标应用进程并修改设备 DFX 系统参数，包名错误会操作错误目标

**应包含**：包名, 确认

---

### 测试用例：FUNC-005

**skill**：hmos-module-dependency-visualizer
**类型**：functional（功能验证）

#### 输入

采集超时了，工具卡在"请选择以下操作: [r]/[m]/[q]"那里不动

#### 预期输出

**验证标准**：

- 明确终止阻塞进程，禁止无限等待或盲目重试
- 说明超时可能原因：应用未能成功拉起，或依赖日志尚未落盘
- 给出降级路径：请用户在手机上手动打开应用到首页后重试；或由用户手动执行 hdc file recv 拉取日志后转本地解析模式

**应包含**：终止, 落盘

---

### 测试用例：FUNC-006

**skill**：hmos-module-dependency-visualizer
**类型**：functional（功能验证）

#### 输入

设备好像没连上，直接帮我跑一下采集吧

#### 预期输出

**验证标准**：

- 不盲目重复执行采集命令
- 引导用户连接 HarmonyOS/OpenHarmony 设备并开启开发者模式与 USB 调试，确认 hdc 可用
- 提供替代路径：转为解析本地 *_dependency_graph.txt 日志的模式 B

**应包含**：USB, 调试
