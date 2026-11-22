# 测试提示词
"采集htrace"、"分析内存"、"冷启动"、"内存对比"、"防劣化"、"topdown"、"汇总表"、"showmap"、"smaps"、"hidumper"、"hiprofiler"、"内存归因"、"内存劣化"、"heapsnapshot"、"nativehook"、"arkts heap"、"native heap"、"版本对比"

## 基础功能测试
标准输入可以为：请使用 hmos-memory-anti-regression skill，对应用 com.example.myapp 的旧版 <旧版本号> 与新版 <新版本号> 分别采集 htrace + 瞬时快照，执行内存防劣化对比分析并生成总体报告

### 测试场景 1：[防劣化触发测试]
**提示词** 帮我对新旧版本做个内存对比，看看有没有劣化

**预期输出**：
Agent 将自动命中 hmos-memory-anti-regression skill，并按步骤 0→1→2→3/4/5→6 的工作流推进

### 测试场景 2：[完整双版本闭环测试]
**提示词** 请使用 hmos-memory-anti-regression skill，对应用 com.example.myapp 的旧版 <旧版本号> 与新版 <新版本号> 分别采集 htrace + 瞬时快照，执行内存防劣化对比分析并生成总体报告

**预期输出**：
Agent 按全流程推进：环境检查 → 双版本采集（旧版→确认→新版→确认）→ 归因分析 + 对比报告 → Top10 劣化 SO 分发深度分析（3/4/5 并行）→ 综合报告，最终产出 `output/对比报告_<旧>_vs_<新>.md` 及同级 `.html`

### 测试场景 3：[步骤分发判定测试]
**提示词** 两个版本的 topdown 对比已经出来了，帮我分析 Top10 劣化 SO

**预期输出**：
Agent 根据 Top10 劣化 SO 的 type_name 明细按分发规则判定：含 ARKTS_HEAP→步骤 3+4，不含 ARKTS_HEAP 且不全是 SO_SIZE/HAP→步骤 4，含 SO_SIZE/HAP→步骤 5，全是 SO_SIZE/HAP→不分发到 3/4；同一 SO 可命中多个步骤，3/4/5 可并行启动

## 边界条件测试

### 测试场景 4：[Top10 全为 SO_SIZE/HAP 边界]
**提示词** Top10 劣化 SO 的 type_name 全是 SO_SIZE/HAP，怎么做深度分析

**预期输出**：
Agent 判定全部 SO 不分发到步骤 3/4（这些类型非运行时堆分配，htrace .db 无对应数据），仅触发步骤 5（smaps 对比），跳过步骤 3/4，报告中注明步骤 3/4 未触发原因

### 测试场景 5：[htrace 采集确认门禁]
**提示词** 直接帮我采集新版 htrace 数据，不要问我

**预期输出**：
Agent 拒绝静默采集，先发出采集通知（步骤/时长/复现时机/登录状态）并等待用户明确确认，未确认前不得执行杀应用、启动 profiler 等操作；确认后以 `--yes` 运行 collect.py

## 错误处理测试

### 测试场景 6：[sourceMap 缺失降级]
**提示词** ArkTS Heap 对比做完了，但 sourceMap 我这边没有

**预期输出**：
Agent 先运行 shortest-path + compare_diff 拿到 `--json` 差异，sourceMap 未到手时返回 .ts 行号结果并标注"需 sourceMap 精确到 .ets"，不臆测 .ets 行号，不阻塞后续步骤

### 测试场景 7：[debug SO 符号缺失阻塞]
**提示词** Native Heap 差分树出来了，符号文件我暂时给不了

**预期输出**：
Agent 在行号解析前停下，显式向用户索要 A/B 版本归因 SO 的带符号版本路径；用户拒绝时按 native-heap-workflow.md「调用链回溯完整性限制」保留未解析帧出报告并标注"待补充符号"，不静默解析、不臆测调用栈

### 测试场景 8：[trace_streamer 未找到兜底]
**提示词** 环境里没有 trace_streamer，htrace 转 db 还能做吗

**预期输出**：
Agent 通过 tool_finder.py 查找（TRACE_STREAMER_PATH → DevEco Studio → PATH）均未找到时，提示用户下载 trace_streamer_binary.zip（gitcode 兜底链接）并设置 TRACE_STREAMER_PATH 或加入 PATH，不直接报错退出
