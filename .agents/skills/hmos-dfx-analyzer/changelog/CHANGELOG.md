# 更新日志

## [1.0.0] - 2026-10-29

### 新增
- 首次上架：DFX 故障分析主技能，融合并替换原 hmos-runtime-fix-skill 的能力。
- 确定性故障分诊（identify_fault_log.py）：AppFreeze / CppCrash / JSCrash 三类故障日志 + 采样栈配套证据归并。
- 非崩溃型白屏 source-first 分析：五大高信号模式（loadContent 错页、hideNavBar 藏首页、builder 缺 NavDestination 根、多 navDestination 注册竞争、路由名不匹配）与三档验证契约。
- 交付形态：会话内简洁摘要 + 自包含 HTML 分析报告落盘（export_report.py → dfx-reports/，含代码高亮、diff 配色、目录导航）。
- 设备侧证据采集（devecocli）：症状口述无日志场景的采集流程，含 hilog 兜底与降级路径。
- 批量合并分析：多日志逐份分节合并报告，分诊摘要表逐份携带类型/输入完整度/置信度。
- 修复执行约束（js_crash 报告）：报告驱动、主 Agent 执行，最小修复行为约束。

### 变更
- 检视修正（意见 2、3）：SKILL.md 采样栈步骤引用（Step 9→8）与「交付形态」表格分隔行；report.py 小节-步骤映射同步修正。
- 检视修正（FUNC-002）：功能用例片段输入补全分诊正向特征（Reason 独立成行 + 标准形 JS 栈帧）。
- 配套文件清单并入 SKILL.md「配套文件清单」节，移除根目录 FILES.md（检视意见 4 第三方案）。
