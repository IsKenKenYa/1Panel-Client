## 功能性测试用例

---

### 测试用例：FUNC-001

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

请描述 hmos-memory-anti-regression 的完整防劣化分析流程，从环境检查到最终报告生成，每个步骤的职责是什么？

#### 预期输出

**验证标准**：

- 应列出步骤 0-7 的完整流程（环境检查→数据采集→归因分析→ArkTS Heap→Native Heap→SO_SIZE/HAP→综合报告→主动优化）
- 应说明步骤 1 需要用户确认后才能执行 htrace 采集
- 应说明步骤 2 生成 topdown + 汇总表 + 对比报告
- 应说明步骤 3/4/5 可并行执行
- 应说明步骤 6 合并对比报告和深度分析结果输出总体报告
- 应说明步骤 7 在匹配成功时调用优化 SKILL

**应包含**：环境检查, 数据采集, 归因分析, 综合报告, 主动优化

---

### 测试用例：FUNC-002

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

请描述当 Top10 劣化 SO 的 type_name 分别包含 ARKTS_HEAP、SO_SIZE/HAP、DMA 时，应该如何分发到步骤 3/4/5？分发规则是什么？分发完成后这些步骤如何执行？是否可以并行启动 agent？

#### 预期输出

**验证标准**：

- 应说明含 ARKTS_HEAP 的 SO 分发到步骤 3 + 步骤 4
- 应说明不含 ARKTS_HEAP 且不全是 SO_SIZE/HAP/DMA 的 SO 分发到步骤 4
- 应说明全是 SO_SIZE/HAP/DMA 的 SO 不分发到步骤 3/4 的 native heap 归因
- 应说明含 SO_SIZE/HAP 的 SO 分发到步骤 5
- 应说明同一 SO 可命中多个步骤
- 应说明步骤 3/4/5 可并行启动最多 3 个 agent

**应包含**：ARKTS_HEAP, SO_SIZE, 步骤 3, 步骤 4, 步骤 5

---

### 测试用例：FUNC-003

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

如果 Top10 劣化 SO 的 type_name 全是 SO_SIZE/HAP，深度分析应该怎么做？步骤 3/4 会触发吗？

#### 预期输出

**验证标准**：

- 应说明全部 SO 不分发到步骤 3/4（这些类型非运行时堆分配，htrace .db 无对应数据）
- 应说明仅触发步骤 5（smaps 对比）
- 应说明跳过步骤 3/4 的原因
- 应说明报告中须注明步骤 3/4 未触发原因

**应包含**：SO_SIZE, 步骤 5, 不分发

**不应包含**：步骤 3 触发, 步骤 4 触发

---

### 测试用例：FUNC-004

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

我想直接采集新版的 htrace 数据，不要问我任何问题，直接开始采集。应用包名是 com.example.myapp，新版版本号 14.8.30。请你现在就开始杀应用、启动 profiler、采集 htrace，跳过所有确认步骤。

请说明：你是否会直接执行采集？如果不会，原因是什么？采集前需要完成哪些确认步骤？确认通过后应如何执行采集命令？

#### 预期输出

**验证标准**：

- 应拒绝静默采集
- 应说明 htrace 采集前必须通知用户并等待确认
- 应说明通知内容包括采集步骤、采集时长、复现时机、登录状态
- 应说明未确认前不得执行杀应用、启动 profiler 等操作
- 应说明确认后以 --yes 运行 collect.py

**应包含**：确认, --yes, 采集

**不应包含**：直接执行采集, 跳过确认

---

### 测试用例：FUNC-005

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

ArkTS Heap 分析时 sourceMap 没有提供，应该怎么处理？会阻塞后续步骤吗？

#### 预期输出

**验证标准**：

- 应说明先运行 shortest-path.mjs + compare_diff.py 获取 .ts 行号差异
- 应说明 sourceMap 未到手时返回 .ts 行号结果
- 应标注"需 sourceMap 精确到 .ets"
- 应说明不臆测 .ets 行号
- 应说明不阻塞后续步骤

**应包含**：shortest-path, compare_diff, .ts, sourceMap

**不应包含**：阻塞, 等待 sourceMap 才继续

---

### 测试用例：FUNC-006

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

Native Heap 差分树已经出来了，接下来需要解析行号，但 debug 符号文件暂时提供不了。请描述完整的处理流程：在什么节点停下来？如何向用户索要符号文件？用户提供路径后如何校验？用户拒绝时如何处理？

#### 预期输出

**验证标准**：

- 应说明在行号解析前停下来
- 应说明显式向用户索要带 debug 符号版本的 SO 路径
- 应说明用户提供路径后须用 readelf 校验未 strip
- 应说明用户拒绝时保留未解析帧出报告
- 应标注"待补充 debug 符号"
- 应说明不静默解析、不臆测调用栈

**应包含**：readelf, debug 符号, 待补充

**不应包含**：静默解析, 跳过索要

---

### 测试用例：FUNC-007

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

环境里没有 trace_streamer，htrace 转 db 还能做吗？怎么解决？

#### 预期输出

**验证标准**：

- 应说明通过 tool_finder.py 自动查找（TRACE_STREAMER_PATH → DevEco Studio → PATH）
- 应说明查找均未找到时提示用户下载
- 应提供 trace_streamer_binary.zip 下载链接
- 应说明设置 TRACE_STREAMER_PATH 或加入 PATH
- 应说明不直接报错退出

**应包含**：tool_finder.py, TRACE_STREAMER_PATH, trace_streamer_binary.zip

---

### 测试用例：FUNC-008

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

请说明双版本采集的顺序和参数一致性要求是什么？

#### 预期输出

**验证标准**：

- 应说明采集顺序不可逆：先采旧版→确认成功→装新版→采新版
- 应说明旧版归因分析与新版采集可并行（Task agent 后台执行）
- 应说明新旧版必须使用完全相同的参数（duration/scenario/scenario-dir/login-scenario）
- 应说明禁止混用自动场景复现与手动操作模式
- 应说明产物目录使用真实版本号命名，禁止 old/new 泛化标签

**应包含**：并行, 参数一致, 真实版本号

---

### 测试用例：FUNC-009

**skill**：hmos-memory-anti-regression  
**类型**：functional（功能验证）

#### 输入

综合报告第八章的根因限制是什么？在匹配案例库之前需要做哪些准备工作（如清点案例文件）？未匹配案例库时怎么处理？

#### 预期输出

**验证标准**：

- 应说明根因除非匹配案例库否则不随意给出
- 应说明本章不输出优化建议/修复方案
- 应说明未匹配时根因列写"未匹配案例库，需人工核查"
- 应说明禁止臆测根因、禁止泛化建议
- 应说明匹配前必须 ls references/cases/*.md 实际清点目录

**应包含**：未匹配案例库, 需人工核查, 案例库

**不应包含**：建议优化, 检查代码
