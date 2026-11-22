# 触发验证

验证 skill 是否在正确场景被触发。多条用例以 `---` 分隔。

**测试约束**：每个用例的输入自包含，无需追问；判定标准为"应触发 / 不应触发"的二值结论。测试时各进程命令应包含 `--skip-safe-check` 参数，跳过安全确认，防止等待超时（重要）。

---

### 测试用例：TRIGGER-001（显式要求接入隔空传送文件）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
帮我在当前 HarmonyOS 工程接入隔空传送文件分享，挂载页 pages/Detail。
```

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002（使用 gesturesShare 关键词）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
请接入 HarmonyOS Share Kit 的 gesturesShare 隔空传送能力，挂载页 pages/Detail。
```

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003（要求接入 App Linking 直达）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
接入隔空传送，既要分享文件，也要分享 App Linking 链接直达应用。
```

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-004（增量补类型）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
工程已有文件隔空传送，请再接入链接分享（App Linking）直达应用。
```

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-005（异构实现迁移）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
我们工程里有个自写的 ShareModel.ets，想把它迁移重构为 Share Kit 隔空传送的标准模板结构。
```

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-006（碰一碰 knockShare 场景——不应触发）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
我想用碰一碰（一碰传）实现两台手机靠近后自动弹出分享面板，让用户选择文件后碰触传输，怎么接入？
```

#### 预期输出

**应触发**：否（明确属于碰一碰 knockShare 场景，非隔空传送 gesturesShare）

---

### 测试用例：TRIGGER-007（碰一碰 knockShare 关键词——不应触发）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
我想实现两台设备靠近后弹出分享卡片让用户选择文件，再通过碰一碰（knockShare）传输的功能。
```

#### 预期输出

**应触发**：否（明确属于碰一碰 knockShare 场景，非隔空传送 gesturesShare）

---

### 测试用例：TRIGGER-008（SystemShare dataReceive 场景——不应触发）

**skill**：hmos-share-kit-gestures-share
**类型**：trigger（触发验证）

#### 输入

```
请接入 HarmonyOS 系统分享 dataReceive（SystemShare），让我的应用作为接收方能拉起选择其他应用分享过来的文件，不涉及隔空传送。
```

#### 预期输出

**应触发**：否（明确属于 SystemShare dataReceive 场景，且显式排除隔空传送）

---