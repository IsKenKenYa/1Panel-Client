# hmos-module-dependency-visualizer 使用指南

> 本文件面向人类读者；Agent 运行时请以 SKILL.md 为准。

## 简介

本 skill 内嵌 modtree.exe（Windows x64 单文件，前端模板已内置，零外部依赖），用于采集并可视化 HarmonyOS/OpenHarmony 应用 ArkTS 模块的依赖关系：

- 文件级依赖自动聚合为模块级，输出交互式 HTML 依赖图（DAG 拓扑布局）
- Markdown 分析报告：扇入/扇出排行、循环依赖检测（Tarjan 强连通分量）、依赖邻接表、边权重 Top50

## 环境要求

| 场景 | 要求 |
|---|---|
| 本地日志解析 | 仅需 Windows x64 |
| 真机自动采集 | 另需：USB 连接 HarmonyOS/OpenHarmony 设备（开启开发者模式 + USB 调试）、`hdc` 命令在 PATH |

## 快速开始

### 模式 A：真机一键采集（推荐）

在专用输出目录执行（产物写入当前目录）：

```powershell
& "<skill目录>\scripts\modtree.exe" -bundle com.ss.hm.ugc.aweme

# 可选参数：
#   -ability <Ability名>   手动指定主 Ability（缺省自动 bm dump 探测）
#   -duration <毫秒>       采集延时（默认 3000，大型应用建议 5000~10000）
#   -o <输出.html>         指定输出路径（MD 报告同名替换扩展名）
```

工具自动完成全流程：配置 DFX 参数（`persist.ark.properties=0x400000105c` 与采集延时）→ 强杀目标应用实现冷启动 → 清理设备侧旧日志 → 智能探测并拉起主 Ability → 轮询拉取并校验日志完整性 → 恢复 DFX 参数原值 → 解析分析 → 生成报告并自动打开浏览器。

### 模式 B：本地日志解析

适用于已从设备取得 `*_dependency_graph.txt` 日志的离线分析：

```powershell
& "<skill目录>\scripts\modtree.exe" -o report.html app_dependency_graph.txt
```

## 产物说明

| 产物 | 内容 |
|---|---|
| `<输出>.html` | 交互式依赖图：左侧统计卡片与 Top15 排行、中间 DAG 画布（双击节点切换根节点、滚轮缩放、拖拽平移）、右侧节点依赖详情（支持模糊过滤） |
| `<输出>.md` | 概览 / 域分布 / 域级依赖总览 / 核心模块图 / 扇入扇出排行 / 循环依赖 / 依赖邻接表 / 边权重排行 |

视觉约定：**实线 = 静态导入（编译期 import），虚线 = 动态依赖（运行时 import()，悬浮可见 specifier 原始导入语句）**。

## 常见问题

| 现象 | 处理 |
|---|---|
| 自动拉取超时，停在 `[r]/[m]/[q]` 菜单 | 应用未成功拉起或日志未落盘；在手机上手动打开应用到首页后选 `r` 重试，或手动执行 `hdc file recv` 拉取日志后转模式 B |
| 报告缺模块 / 图不完整 | 采集延时不足，模块未加载完即落盘；用 `-duration 5000~10000` 重新采集 |
| 提示未检测到设备 | 检查 USB 连接、开发者模式与 USB 调试开关、hdc 环境变量 |
| 应用拉起失败 | 加 `-ability` 显式指定主 Ability 名称（部分三方应用非标准名且自动探测失败） |

## 注意事项

- 真机采集会 `kill -9` 目标应用进程，并在采集期间临时修改设备 DFX 系统参数（结束后自动恢复原值），**确认包名后再执行**
- 依赖日志仅在**冷启动**后生成与更新，热启动不会刷新设备侧文件
- 以 stdout 标记判定成败：`[OK] 完成` 成功（退出码 0）、`[ERROR]` 失败（退出码非 0）、`[WARN]` 非致命告警

## 更多参考

- 依赖图日志格式与模块名提取规则：`references/log-format.md`
- HTML / Markdown 报告解读指南：`references/report-guide.md`
- modtree 工具源码仓库：https://gitcode.com/wanghaha1204/module_tree
