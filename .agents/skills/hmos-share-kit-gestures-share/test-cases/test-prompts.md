# 测试提示词

人验收时按场景加载 Skill，使用下列提示词，对照 [acceptance-checklist.md](acceptance-checklist.md) 与对应 `test-case-*.md` 勾选。

## 场景 1：仅文件分享接入

**提示词**：

```
请使用 hmos-share-kit-gestures-share，帮我在当前工程接入隔空传送文件分享。
（可选：挂载页面是 pages/Detail，分享当前页已选中的本地文件 URI 列表）
```

**预期输出**：

- 先做前置检测（`targetSdkVersion` ≥ `6.0.0(20)`；`compatibleSdkVersion` 可更低）
- 已指定「文件分享」→ 不要再问分享类型；引导确认挂载页（若需）、文件数量、可分享范围、文件 `uri` 获取方式
- 提问中不得出现 App Linking、域名、落地页、`applinking.json`、签名/AGC、`module.json5` skills
- `uri` / `utd` 无法落实且未授权自决时追问或中止，不用空值/裸 path 占位
- 注入来自 `assets/file/` 的管理类与业务类；无链接分支、无 HYPERLINK / `example.com`、无 App Linking 改码；业务类对照模板返回 `SharedData | undefined`
- 挂载页 `enable(ctx, provider)` 两参数；show 注册 / hide 注销
- 多文件时用 collect + 循环 `addRecord`（或等价）；禁止臆造无业务依据的 `selected*`
- 确认可能多文件时才实现 `addRecord`；未确认可选字段则不写
- 无内容时 `reject(NO_CONTENT_ERROR)`；回调内不做下载/重 IO
- 静态检查与编译（环境具备时）；完成报告与人工清单
- 用例：[test-case-file-share.md](test-case-file-share.md)

## 场景 2：文件 + 链接（配置未就绪）

**提示词**：

```
请接入隔空传送，既要分享文件，也要分享 App Linking 链接直达应用。
域名是 share.myapp.com，参数 contentId，落地页是 pages/Content。
签名和 applinking.json 我还没配好。
```

**预期输出**：

- 已指定「两者都要」→ 不要再问分享类型；引导须同时含文件侧与链接侧必问项（可分组）
- 未就绪的签名/域名明确列入人工清单；不声称域名关联或联调已完成
- 注入来源为 `assets/both/`（或先 file 再增量升级为 both）
- 业务类同时具备文件与链接取数能力
- 云侧配置不写入工程
- 编译验证发送侧改动（环境具备时）
- 用例：[test-case-link-both-not-ready.md](test-case-link-both-not-ready.md)

## 场景 3：targetSdk 过低应中止

**提示词**：

```
帮我接入隔空传送 gesturesShare。
```

（测试时将工程 `targetSdkVersion` 视为低于 `6.0.0(20)`，或在提示中说明当前工程 target 是 `5.0.0(12)`）

**预期输出**：

- 警告 `targetSdkVersion` 不满足
- **停止自动改码**
- 说明需将 `targetSdkVersion` 升级到 `6.0.0(20)+`
- 不以「HarmonyOS 5.0 即可用 gesturesShare」放行
- 用例：[test-case-unsupported-sdk.md](test-case-unsupported-sdk.md)

补充（可选对照）：若仅 `compatibleSdkVersion` &lt; 20 且 `targetSdkVersion` ≥ 20 → **不中止**；提醒低版本设备运行时降级，并写入完成报告。

## 场景 4：增量补另一种类型

**提示词**：

```
工程已有文件隔空传送，请再接入链接分享。
```

或：

```
再帮我接入一遍隔空传送。
```

（工程中已有管理类 / `gesturesShare` 监听，或验收人说明已有文件侧接入）

**预期输出**：

- 检测到已有管理类/业务类
- 确认为增量：用 `assets/both/` 升级，补缺失方法，**避免**第二套监听 / 第二套管理类
- 若并不存在则按首次只拷本次类型目录
- 用例：[test-case-incremental-both.md](test-case-incremental-both.md)

## 场景 5：未指定类型 / 挂载页

**提示词**：

```
接入隔空传送。
```

（用户不提供页面，工程也无明显可分享页）

**预期输出**：

- 未说明类型 → **本轮只先问分享类型**（文件 / 链接 / 两者），不要附带文件 uri / App Linking 配置
- 类型确定后再问对应项与挂载页；未答清不修改代码
- 用例：[test-case-guide-unspecified.md](test-case-guide-unspecified.md)

## 场景 6：未要求接入，不改码

**主提示词**：

```
我们 App 详情页要做隔空传送，和系统自带的分享有什么区别？适合分享文件还是分享链接？
```

**备用提示词**：

```
看一下我们工程 pages/Detail，这块适不适合做隔空传送？大概要改哪些地方？（先不要改代码）
```

**预期输出**（主、备各跑一遍，均需满足）：

- 可简要说明差异 / 适用场景 / 大概改哪些地方
- **不**改工程代码
- **不**注入管理类、业务类，不接监听
- 用例：[test-case-no-integration-request.md](test-case-no-integration-request.md)

## 场景 7：仅链接分享

**提示词**：

```
请接入隔空传送链接分享（App Linking）。挂载页是 pages/Content。
```

**预期输出**：

- 已指定仅链接 → 不要再问分享类型；引导只问链接侧必问项及未指定的挂载/落盘目录
- 提问中不得出现文件数量、可分享文件范围、文件 `uri` / `file://`、`getUriFromPath`、按后缀算文件 `utd`
- 拷贝 `assets/link/`，无文件分享实现
- 用例：[test-case-link-only.md](test-case-link-only.md)

## 场景 8：读不到 assets 中止

**提示词**：

```
请接入隔空传送文件分享，挂载页 pages/Detail。
```

（验收时模拟：只能看到 `SKILL.md`，或对应 `assets/file/` 打不开 / 读失败）

**预期输出**：

- **停止改码**
- 说明需完整安装本 Skill 目录（含 `assets/`）
- **禁止**凭记忆重写管理类 / 业务类
- 用例：[test-case-assets-unreadable.md](test-case-assets-unreadable.md)

## 场景 9：无构建环境

**提示词**：

```
请使用 hmos-share-kit-gestures-share，帮我在当前工程接入隔空传送文件分享。
挂载页面是 pages/Detail，分享当前页已选中的本地文件 URI 列表。
```

（验收时明确：当前环境无 HarmonyOS / DevEco 静态检查与工程构建能力；或 Agent 无法调用编译）

**预期输出**：

- 可按规范完成引导与改码（在可读模板前提下）
- 完成报告「验证结果」写明**未自动编译**
- 人工清单含「请在 DevEco Studio 编译通过」
- **不得**宣称编译已通过
- 用例：[test-case-no-build-env.md](test-case-no-build-env.md)
