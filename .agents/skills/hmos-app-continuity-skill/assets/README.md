# assets/ — 示例、模板与验收清单

## 目录结构

| 子目录 | 内容 | 使用方式 |
|--------|------|----------|
| `examples/` | 场景化可运行代码示例（.ets） | 步骤 4（改码）时复制到项目中按需修改 |
| `templates/` | 配置文件与 Ability 模板 | 配置接入时参考 |
| `checklists/` | 实施步骤与陷阱排查清单 | 步骤 5（自检）时逐项核对 |

## 代码示例（examples/）

| 文件 | 说明 | 适用场景 |
|------|------|----------|
| `UIProgress.ets` | 原生 UI 页面接续示例（PageState 模型 + 滚动/输入状态） | UI 浏览类 |
| `WebProgress.ets` | Web UI 页面接续示例（URL + 滚动偏移经 runJavaScript 采集/延时恢复） | UI 浏览类（Web） |
| `EditProgress.ets` | 内容编辑场景接续数据处理示例（编辑器三态） | 内容编辑类 |
| `PlaybackProgress.ets` | 媒体播放场景接续数据处理示例（播放进度） | 媒体播放类 |
| `NavigationContinuity.ets` | 接续中页面栈迁移示例（Navigation 手动重建） | 页面栈迁移 |
| `RouterContinuity.ets` | Router 路由页面栈接续示例（系统自动恢复） | 页面栈迁移 |
| `SourceProgress.ets` | 源端应用保留不退出示例 | 源端控制 |

## 配置模板（templates/）

| 文件 | 说明 |
|------|------|
| `module.md` | `module.json5` 中接续相关的配置片段的模板（continuable、launchType、权限等） |
| `EntryAbility.ets` | UIAbility 生命周期接续模板（源端 onContinue；目标端 onCreate / onNewWant + 同步调用 restoreWindowStage 触发页面恢复；onWindowStageRestore 按需镜像 onWindowStageCreate 初始化） |

## 实施与自检清单（checklists/）

各场景的实施步骤、双设备实测步骤与常见陷阱排查。步骤 2（确认）和步骤 5（自检）时参考。

| 文件 | 说明 | 使用时机 |
|------|------|----------|
| `confirm-scene-inventory.md` | 场景盘点模板：页面清单、状态清单、用户需求确认 | 步骤 2（确认）与用户交互时 |
| `checklist-ui-progress.md` | UI 浏览类接续自检清单：滚动位置、Tab 状态、Web 组件、懒加载保护 | 步骤 4+5（改码+自检）UI 浏览场景 |
| `checklist-edit-progress.md` | 内容编辑类接续自检清单：编辑器三态、表单状态、并发写冲突 | 步骤 4+5（改码+自检）编辑场景 |
| `checklist-playback-progress.md` | 媒体播放类接续自检清单：播放进度、实时流、进度反馈 | 步骤 4+5（改码+自检）播放场景 |
| `checklist-navigation.md` | 页面栈迁移自检清单：Navigation 手动重建、Router 自动恢复 | 步骤 4+5（改码+自检）页面栈迁移场景 |
