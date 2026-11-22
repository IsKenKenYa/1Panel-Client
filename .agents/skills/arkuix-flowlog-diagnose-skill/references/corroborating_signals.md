# DFX 旁证信号（Corroborating Signals）

> 这些信号非 ArkUI-X 流程锚点，但已 LOGE/LOGW fire（release 可见），作为维度①②之外的旁证。
> skill 在 4 维度主分析后，grep 这些信号作为补充证据，辅助定位根因。

## 旁证信号表

| 信号 | grep 模式 | 含义 | 关联症状 | 处置方向 |
|------|----------|------|---------|---------|
| Vulkan RenderContext null | `RenderContext::Create() return nullptr` | Vulkan 渲染上下文创建失败 | 白屏（首帧未上屏） | 查 Vulkan 设备支持 / GPU 驱动 / surface 有效性 |
| **Delegator is null（非致命）** | `UIContent::AddUIContent Delegator is null` | **出现在所有 ArkUI-X release 应用中，app 继续正常加载**。框架通过 RSUIDirector 路径绕过。 | **非白屏根因** | **无需处置**。检查后续 `Succeeded in loading content` + 首帧锚点是否齐全，若齐全则 app 正常 |
| RSSimpleDrawCmdList unmarshal fail | `RSSimpleDrawCmdList unmarshal fail` | 渲染指令序列化反序列化失败 | 白屏 / 渲染异常 | 查 RS 进程状态 / 跨进程 IPC |
| ArkCompiler Throw error | `ArkCompiler: [default] Throw error:` | ArkTS 运行时异常 | 白屏（aboutToAppear/页面异常） | 看 Throw 后的堆栈，定位 .ets 文件:行，加异常保护 |
| nativeWindow is null | `nativeWindow is null` | native 窗口为空 | 白屏（surface 未就绪） | 查 surface 创建时序 / WindowView 是否 attach |
| Time decreases | `pipeline_context.cpp(7795) Time decreases` | 时钟回退 | 时间戳分析异常（维度④） | 标"时钟异常"，不计 stall，建议重新抓日志 |
| 节点重复注册 | `node already registered` / `duplicate node id` | 节点重复注册 | 渲染异常 / 内存增长 | 查 FrameNode id 生成逻辑 / 树结构 |

## 使用方法

1. 4 维度主分析后，逐个 grep 上表信号。
2. 命中 → 作为"旁证"加入证据区（区分于流程链/FAQ/首帧/时间戳 4 维度）。
3. 输出格式：`旁证：<信号> → <含义>，建议 <处置方向>`。

## 与主维度的关系

- 旁证信号**不替代** 4 维度主分析，是补充。
- 旁证命中可强化根因判断（如维度③判"首帧请求未上屏" + 旁证"Vulkan RenderContext null" → 强化 Vulkan 渲染失败根因）。
- 旁证未命中不影响主维度结论。

## release 可见性

这些信号均为 LOGE/LOGW（非 LOGD），release 包可见，无需特殊处理。
