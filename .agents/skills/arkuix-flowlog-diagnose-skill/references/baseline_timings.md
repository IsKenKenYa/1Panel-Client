# 冷启动时间戳基线（Baseline Timings）

> 实测 HelloWorld 冷启动 logcat 各段 gap 基线。
> skill 维度④对照此基线判 stall（大间隔）。
> 基线为参考值，不同设备/应用会有差异；阈值用于粗粒度嫌疑，不做精确帧率。

## 冷启动各段 gap 基线

| 段 | 起止锚点 | 基线 gap | 阈值（stall 嫌疑） | 说明 |
|----|---------|---------|---------------------|------|
| pre-S1: lib 加载 | 进程启动 → #1 AceEnv init | ~102ms | > 300ms 嫌疑 | lib 加载慢：查 .so 缺失/大 |
| pre-S1: App launch | #3 → #4 Launch application success | ~39ms | > 150ms 嫌疑 | 框架初始化慢 |
| pre-S1: Activity→UIContent | #5 StageActivity → #8 Create UIContentImpl | ~54ms | > 200ms 嫌疑 | Ability 创建慢 |
| S1→S6（容器装配→RunPage） | #9 → #14 | ~16ms | > 100ms 嫌疑 | 容器装配 + frontend 初始化 |
| RunPage→首帧 vsync | #14 RunPage → #20 vsync | ~2ms | > 50ms 嫌疑 | 首帧构建 + 上屏 |
| S5 SetupRootElement | #13 :967 → :973 | < 25ms | > 100ms 嫌疑 | 根节点树建立（measure/节点数/资源） |

## warm 重启基线

| 段 | 基线 | 阈值 | 说明 |
|----|------|------|------|
| 后台→前台 fgbg 四态切换 | < 100ms | > 300ms 嫌疑 | ON_SHOW/ON_ACTIVE 切换 |
| delay notify 暂存→回放 | < 50ms | > 200ms 嫌疑 | UIContent 创建 + 回放 |

## 阈值使用规则

1. 取相邻 Ace 日志时间戳差值。
2. 对照上表阈值：gap > 阈值 → 标 stall 嫌疑段。
3. 输出格式：`<段名> gap <实际>ms 超基线 <基线>ms（阈值 <阈值>ms）→ stall 嫌疑`。

## 时钟异常处理（ER-1.2）

- 若日志出现 `pipeline_context.cpp(7795) Time decreases` → 时钟回退。
- 负 dur / 异常 gap（如后一条 ts < 前一条）→ 标"时钟异常"，**不计 stall**。
- 时钟回退期间的所有 gap 判定不可靠，提示"需重新抓日志"。

## 卡顿边界声明（ER-1.1）

- 每帧 FlushLayout/FlushRender 耗时信号**不在 logcat 通道**，需 trace 工具（SmartPerf / Profiler）。
- 本基线仅做**粗粒度 stall 嫌疑**（阶段间大间隔），**不做帧率定位**。
- 开发者要帧率 → 明确告知"需 trace 工具，logcat 无法提供"。

## 重复行判定

- 同 ts（同 ms）重复同一日志行 ≥ 10 次 → 循环嫌疑（如 ProcessPointerEvent 重复 30+）。
- 输出格式：`<文案> 同 ts 重复 <N> 次 → 循环嫌疑，查事件分发未退出/重入`。
