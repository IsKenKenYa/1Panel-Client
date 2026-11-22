# 测试用例 1：低端机内存分档优化全闭环

## 场景描述
用户希望对 HarmonyOS 应用做低端机内存分档优化，采集 before 数据、分析瓶颈、给出分档方案、修改代码后构建验证、采集 after 数据并生成对比报告。

## 用户输入
请使用 hmos-memory-tier-optimizer skill，采集应用 com.example.myapp 在首页长列表场景的内存数据，分析低端机内存瓶颈并给出分档优化方案。项目代码在 D:\Project\MyApp，设备已连接。

## 执行步骤
1. 步骤一：调用 `scripts/windows/collect_memory.bat com.example.myapp ../AppCode/TestData/before` 采集 before 数据（meminfo/uiTree/screenshot）
2. 步骤二：读取 `references/detection_rules.md` 和 `references/device_level_tiering.md`，按 meminfo 占比选择检测规则，定位代码，输出候选方案（如 cachedCount 分档、图片分档等，对应 `references/scheme_*.md`）
3. 步骤三：向用户说明影响文件和验证方式，等待确认
4. 步骤四：按确认方案修改代码，读取 `references/arkts_rules.md` 执行代码审查
5. 步骤五：调用 `scripts/windows/build_template.bat D:\Project\MyApp` 构建 HAP 并安装启动
6. 步骤六：进入相同场景采集 after 数据
7. 步骤七：生成 patch 和优化报告

## 预期结果
- 优化报告生成，格式如下：
================================================================================
                    HarmonyOS 内存分档优化报告
================================================================================

【应用基本信息】
应用名称     : com.example.myapp
目标场景     : EntryAbility - 首页长列表
设备信息     : <机型> / 是否低端机: 是
分档目标     : 低端机 PSS ≤ 400 MB

【优化前内存基线】
Total PSS    : <before Total PSS>
ArkTS Heap   : <ArkTS 堆内存>
Native Heap  : <Native 堆内存>
GL/Graph     : <图形内存>
主要瓶颈     : <如：长列表 cachedCount 过大、图片未分档>

【根因分析】
诊断结果     : <一句话概括根因>
故障类别     : <列表缓存 / 图片资源 / ...>
可信度       : HIGH / MEDIUM / LOW

【候选方案与选择】
┌──────────┬──────────────────────────┬──────────────────┬──────────┐
│  方案    │         说明             │     预计收益      │  风险等级  │
├──────────┼──────────────────────────┼──────────────────┼──────────┤
│ 方案A    │ <如：cachedCount 50→20>  │ <如：-45MB>      │ LOW       │
│ 方案B    │ <如：图片按设备档位降级>  │ <如：-30MB>      │ MEDIUM    │
└──────────┴──────────────────────────┴──────────────────┴──────────┘
已选方案     : <用户确认的方案>
依据         : <引用 references/scheme_*.md 对应方案库>

【代码修改】
修改文件     : <file:line 列表>
核心变更     : <每处改动的简要说明>
审查结果     : <PASS / PASS_WITH_WARNINGS + 审查依据 references/arkts_rules.md>

【优化后对比】
指标         |  Before        |  After         |  变化
-------------|----------------|----------------|--------
Total PSS    |  <XXX MB>      |  <YYY MB>      |  <Δ MB, ↓XX%>
ArkTS Heap   |  ...           |  ...           |  ...
Native Heap  |  ...           |  ...           |  ...
结论         : <改善 / 无变化 / 退化>

【验证结果】
构建状态     : <PASS/FAIL>
安装启动     : <成功/失败>
功能回归     : <目标场景功能正常/异常>

【残余风险与后续建议】
1. <如：高配机未验证，建议后续覆盖>
2. <如：某方案未采用，可在下个版本继续>

================================================================================
