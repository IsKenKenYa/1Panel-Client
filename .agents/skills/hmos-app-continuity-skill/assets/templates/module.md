# module.json5 接续配置片段模板

> 将以下配置合并到项目的 `module.json5` 对应位置。
> 完整前提条件与约束见 `references/constraints-and-prereqs.md`。

---

## 1. 最小可接续配置

`continuable: true` 是接续的**唯一必选项**，声明所属 UIAbility 可被跨端接续。

```json5
{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        // 关键声明：默认 false，必须设为 true
        "continuable": true,
        "launchType": "singleton"
      }
    ]
  }
}
```

### launchType 说明

| 取值 | 行为 | 生命周期回调 |
|------|------|-------------|
| `singleton`（默认） | 目标端已运行时复用实例，未运行时新建 | 已运行 → `onNewWant`（热启动）；未运行 → `onCreate`（冷启动） |
| `multiton` | 始终新建实例 | 始终走 `onCreate` |
| `specified` | 按 Key 复用实例 | 按Key查找，已运行 → `onNewWant`（热启动）；未运行 → `onCreate`（冷启动） |

> ⚠️ `singleton` 和 `specified` 模式下**必须同时测试冷启动和热启动**，避免漏掉 `onNewWant` 的处理逻辑。

---

## 2. 权限配置（仅 API 11 及以下需要）

API 12+ **无需任何权限**。API 11 及以前需要声明分布式数据同步权限，并在首次启动或进入接续页面时弹窗向用户申请授权。

```json5
{
  "module": {
    "requestPermissions": [
      { "name": "ohos.permission.DISTRIBUTED_DATASYNC" }
    ]
  }
}
```

---

## 3. 可选配置（按需启用）

### 3.1 `continueType` — 同应用不同 Ability 接续

```json5
"continueType": ["EditorAbility"]
```

- 两端 `continueType` 取值**必须一致**
- 本应用内唯一
- 用于指定不同 Ability 之间跨端迁移（如 `EntryAbility` → `EditorAbility`）
- 字符串数组仅首个生效，≤127 字节

### 3.2 `continueBundleName` — 跨 BundleName 接续

```json5
"continueBundleName": ["com.example.target"]
```

- 同开发者不同 BundleName 的应用迁移
- 需先向华为申请接续服务能力，审批通过后下载对应 Profile 文件配置到项目中
- 本 Skill 边界为同一 BundleName 内迁移，跨 BundleName 不在支持范围，此处仅作官方配置参考

### 3.3 `_ContinueQuickStart` — 快速启动

```json5
"continueType": ["EntryAbility_ContinueQuickStart"]
```

- 配置后目标端会先收到 `PREPARE_CONTINUATION`（预拉起），再收到 `CONTINUATION`
- 可在目标端将部分初始化前移到`PREPARE_CONTINUATION`（预拉起），加速目标端启动
