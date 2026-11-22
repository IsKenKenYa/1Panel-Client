# 应用接续前提条件与约束清单

> 数据来源：HarmonyOS 官方文档（应用接续概述）
> 最后同步：2026-09

---

## 1. 设备与系统要求

### 1.1 系统版本

| 项目 | 要求 |
|------|------|
| 系统版本 | HarmonyOS NEXT Developer Preview0 及以上（API 9+） |
| 推荐版本 | HarmonyOS NEXT（API 12+），无需申请数据同步权限 |

### 1.2 模拟器限制

| 项目 | 说明 |
|------|------|
| 模拟器支持 | **暂不支持**应用接续 |
| 实测要求 | 至少 **2 台真机** |

---

## 2. 双端组网前提（用户侧检查清单）

要使用应用接续功能，双端设备**必须同时满足**以下条件：

| 序号 | 条件 | 排查方式 |
|------|------|---------|
| 1 | 双端登录**同一华为账号** | 设置 → 账号中心 |
| 2 | 双端打开 **WLAN 和蓝牙**开关或启用"**多设备协同增强服务**" | 快捷开关面板/设置 → 多设备协同 → 高级 |
| 3 | 开启"**多设备协同 → 接续**"功能 | 设置 → 多设备协同 → 接续 |
| 4 | 双端均安装**同一应用（推荐同版本）** | 应用市场检查 |
| 5 | 目标端有可用的接续入口（接续图标） | 源端操作时目标端 Dock/多任务栏显示图标 |


## 3. 应用配置要求

> 完整的配置模板（含代码片段和详细说明）见 `assets/templates/module.md`。本节仅列出约束性要求。

### 3.1 最小配置

- `abilities[].continuable` 必须设为 `true`（默认 `false`）

### 3.2 启动模式（launchType）

| 启动模式 | 迁移目标端行为 | 建议 |
|---------|--------------|------|
| `singleton`（默认） | 已运行实例热启动 → 走 `onNewWant` | 单任务应用推荐 |
| `multiton` | 新建实例 → 走 `onCreate` | 需多实例场景 |
| `specified` | 按 Key 复用实例 | 文档类应用 |

### 3.3 可选配置

| 配置 | 用途 | 注意事项 |
|------|------|---------|
| `continueType: ['typeName']` | 同应用**不同 Ability** 跨端迁移关联 | 两端取值必须一致；本应用内唯一；字符串数组仅首个生效；≤127 字节 |
| `continueBundleName: ['com.xx.yy']` | 同开发者**不同 BundleName** 应用迁移 | 需先向华为申请接续服务能力，审批通过后下载 Profile；**本 Skill 能力边界为同一 BundleName**，跨 BundleName 不在支持范围 |
| `continueType: ['EntryAbility_ContinueQuickStart']` | 快速启动目标应用 | 开启后，目标端会先收到 `PREPARE_CONTINUATION` 再收到 `CONTINUATION` |

### 3.4 权限要求

| API 版本 | 权限要求 |
|---------|---------|
| **API 12+** | 无需申请任何权限 |
| **API 11 及以前** | 需声明并申请 `ohos.permission.DISTRIBUTED_DATASYNC`，且首次启动或进入接续页面时**弹窗向用户申请授权** |

> 权限配置代码片段见 `assets/templates/module.md` §2。

---

## 4. 数据与传输约束

| 约束项 | 限制 | 说明 |
|--------|------|------|
| `wantParam` 数据量（建议） | **< 100KB** | 官方建议，保证体验；Want 硬上限（API 22- 100KB / API 23+ 200KB） |
| DDO sessionId | ≤ 128 字节，字母/数字/下划线 | - |
| 大数据/文件 | 使用 DDO / 文件资产迁移 | 参见 data-migration-strategies.md |
| 敏感数据 | **不建议传个人敏感数据** | DDO 不解析内容，存储路径安全性较低 |

---

## 5. 运行时行为约束

### 5.1 接续图标显示

- 仅当应用 `continuable: true` 且处于**获焦且可接续状态**时，目标端才显示接续图标
- 源端**1 分钟无操作**，图标自动消失；再次操作重新出现
- **锁屏 10 秒**后图标自动消失

### 5.2 迁移后源端行为

| 行为 | 默认 | 配置方式 |
|------|------|---------|
| 源端应用退出 | **默认退出** | `wantConstant.Params.SUPPORT_CONTINUE_SOURCE_EXIT_KEY` |

### 5.3 页面栈恢复

| 路由类型 | 自动恢复 | 说明 |
|---------|---------|------|
| **Router 路由** | ✅ 支持（仅 Router） | 系统自动恢复页面栈；**必须在 `onCreate()`/`onNewWant()` 执行完成前同步调用 `restoreWindowStage()`** 触发（禁止放进异步回调），否则迁移后页面空白 |
| **Navigation 路由** | ❌ 不支持 | 需设置不迁移页面栈，自行在 `onWindowStageRestore()` 手动加载页面 |

> `onWindowStageRestore()` 按镜像原则使用：仅当 `onWindowStageCreate()` 中有启动必要的初始化时，才在 `onWindowStageRestore()` 中执行同样的初始化，避免迁移后异常；无初始化时不添加该回调（最小侵入）。迁移启动（冷/热）都会在 `onCreate()`/`onNewWant()` 后触发 `onWindowStageRestore()`，不执行 `onWindowStageCreate()`。

### 5.4 动态开关时机

| 场景 | 建议做法 |
|------|---------|
| 特定页面才可迁移 | 页面 `aboutToAppear()` 设 `ACTIVE`，离开设 `INACTIVE` |
| UI 开关控制 | `Toggle` 的 `onChange` 中调用 `setMissionContinueState` |
| 迁移连续性 | `onCreate`/`onNewWant` 迁移分支内强制设 `ACTIVE`（防止对端已 INACTIVE） |

---

## 6. 常见问题排查清单

| 症状 | 排查顺序 |
|------|---------|
| 目标端**不显示接续图标** | ① 蓝牙是否开启 ② 接续开关是否开启（设置→多设备协同→接续）③ 是否登录同一华为账号 ⑤ 是否设置`continuable: true` ① 源端是否处于获焦且可接续状态 |
| 迁移后页面空白 | ① Router 默认场景未在 `onCreate`/`onNewWant` 执行完成前同步调用 `restoreWindowStage()`（或误放进异步回调）② 页面栈迁移被禁用（Navigation/按需）但未在 `onWindowStageRestore` 中 `loadContent` |
| 数据丢失 | ① DDO 是否 `save()` 持久化 ② 对端 DDO 属性是否被覆盖（未设 undefined） ④ 目标端数据恢复逻辑是否正确 |
| 目标端未启动应用 | ① 确认两端已安装应用 ① 检查 `module.json5` 配置 ① 部分特殊机型不支持华为共享能力 |

---

> **参考链接**
> - [应用接续概述](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-continue-cast)
> - [UIAbility 组件启动模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-launch-type)
> - [Want API（数据大小限制）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want)