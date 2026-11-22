# 测试用例 2：Top10 劣化 SO 分发深度分析

## 场景描述
步骤 2 对比报告已生成，Top10 劣化 SO 的 type_name 明细混合了 ARKTS_HEAP / SO_SIZE / HAP 等多种类型，需验证分发判定与步骤 3/4/5 并行执行的正确性。

## 用户输入
两个版本的 topdown 对比已经出来了，Top10 劣化 SO 里有一个挂了 ARKTS_HEAP，有一个没挂 ARKTS_HEAP 也不全是 SO_SIZE/HAP，有一个全是 HAP，还有一个同时挂了 ARKTS_HEAP 和 SO_SIZE。帮我分发深度分析。

## 执行步骤
1. 提取 Top10 劣化 SO 及其在汇总表中挂载的 type_name 明细（一个 SO 可挂多个 type_name）
2. 逐 SO 按分发规则判定（以 4 个代表性 SO 为例，用占位名标识）：
   - `<SO_A>`（含 ARKTS_HEAP）→ 步骤 3 + 步骤 4
   - `<SO_B>`（不含 ARKTS_HEAP 且不全是 SO_SIZE/HAP）→ 步骤 4
   - `<SO_C>`（全是 HAP）→ 不分发到步骤 3/4，仅步骤 5
   - `<SO_D>`（含 ARKTS_HEAP + 含 SO_SIZE）→ 步骤 3 + 步骤 4 + 步骤 5
3. 在单条消息中并行启动触发的步骤 agent：
   - Agent 1（步骤 3 ArkTS Heap）：输入两版本 .heapsnapshot，运行 `shortest-path.mjs` → `compare_diff.py`，sourceMap 缺失时降级返回 .ts 行号并标注
   - Agent 2（步骤 4 Native Heap）：输入两版本 .db + 分发 SO 列表，运行 `cluster_calltree.py` → `diff_cluster_tree.py` → `build_flame_summary.py`，行号解析前停下索要符号
   - Agent 3（步骤 5 SO_SIZE/HAP smaps）：输入两版本 smaps，运行 `diff_smaps.py`，输出 smaps_diff.json + 根因推测
4. 所有 agent 返回后，主 agent 汇总结果写入对比报告第一章（深度分析），再执行步骤 6 综合报告

## 预期结果
- 分发判定符合规则表：ARKTS_HEAP 命中 3+4，非全 SO_SIZE/HAP 命中 4，SO_SIZE/HAP 命中 5，全 SO_SIZE/HAP 不进 3/4
- 步骤 3/4/5 并行执行（单条消息发起，未触发的步骤不启动 agent）
- 步骤 4 报告注明针对的 SO 列表（`<SO_A>` + `<SO_B>` + `<SO_D>`，不含 `<SO_C>`）
- 步骤 5 报告注明针对的 SO 列表（`<SO_C>` + `<SO_D>`）
- 步骤 4 火焰图固定输出到 `output/flame_compare/<so>_compare_flame.html`，与报告 .html 同级可被 iframe 相对路径解析
- 步骤 3 未提供 sourceMap 时返回 .ts 行号结果并标注"需 sourceMap 精确到 .ets"，不阻塞
- 步骤 4 未提供符号文件时阻塞索要，用户拒绝后保留未解析帧出报告并标注"待补充符号"
- 报告中注明每个步骤针对的 SO 列表
