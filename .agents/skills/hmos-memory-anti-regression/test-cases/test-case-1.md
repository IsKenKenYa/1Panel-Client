# 测试用例 1：双版本内存防劣化全闭环

## 场景描述
用户希望对 HarmonyOS 应用的新旧版本做内存防劣化对比：采集旧版 htrace + 瞬时快照 → 覆盖安装新版 → 再采新版 → 归因分析 + 对比报告 → Top10 劣化 SO 分发深度分析 → 综合报告。

## 用户输入
请使用 hmos-memory-anti-regression skill，对应用 com.example.myapp 的旧版 <旧版本号> 与新版 <新版本号> 分别采集 htrace + 瞬时快照，执行内存防劣化对比分析并生成总体报告。设备已连接，旧版 HAP 在 /data/hap/myapp_<旧版本号>.hap，新版 HAP 在 /data/hap/myapp_<新版本号>.hap。

## 执行步骤
1. 步骤 0：运行 `scripts/0_prerequisites/check_env.py` 检查 hdc/设备连接/trace_streamer/应用包名
2. 步骤 1（旧版）：安装旧版 → 采集通知确认（步骤/时长/复现时机/登录状态）→ 用户确认后运行 `scripts/1_collection/collect.py --yes` → 产物归置到 `output/myapp_<旧版本号>/`
3. 步骤 1（新版）：确认旧版产物齐全 → 覆盖安装新版 → 采集通知确认 → 用户确认后采集 → 产物归置到 `output/myapp_<新版本号>/`
4. 步骤 2：对两版本分别执行 meminfo 生成（`harmonyos_pipeline.py`）+ 归因分析（`main_analysis_all_mem.py`），再运行 `generate_comparison_report.py` 生成对比报告 `output/对比报告_<旧版本号>_vs_<新版本号>.md`
5. 步骤 2 后：从对比报告提取 Top10 劣化 SO 及其 type_name 明细，按分发规则判定触发步骤 3/4/5
6. 步骤 3/4/5：单条消息并行启动最多 3 个 general agent（ArkTS Heap / Native Heap / SO_SIZE-HAP smaps），各自返回深度分析结果
7. 步骤 6：合并步骤 2 对比报告 + 步骤 3/4/5 深度分析，输出总体报告

## 预期结果
- 产出双版本产物目录：`output/myapp_<旧版本号>/`、`output/myapp_<新版本号>/`（含 htrace/.db/smaps/showmap/heapsnapshot）
- 产出对比报告：`output/对比报告_<旧版本号>_vs_<新版本号>.md` + 同级 `.html`（由 `report_md_to_html.py` 生成）
- 若步骤 4 触发，火焰图输出到 `output/flame_compare/<so>_compare_flame.html`，报告中以 iframe 相对路径引用
- 验证门槛达标：htrace > 100MB、.db > 50MB、汇总.xlsx 行数 > 50、topdown 覆盖率 > 75%、总内存差值合理（同版本两次采集波动约 ±40 MB）
- 综合报告第八章根因/建议仅在匹配案例库时给出，未匹配时标注"未匹配案例库，需人工核查"，无臆测建议
