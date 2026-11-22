# 测试提示词

本文档包含验证 deveco-studio-codescanner skill 功能的测试提示词，每个测试场景包含提示词和预期输出。
门禁自动执行用例见同目录 trigger.md / smoke.md / functional.md；本文件提供人工验证指引。

---

## 基础功能测试

### 测试场景 1：询问 CLI 用法

**提示词**：
```
codescanner 怎么用？有哪些参数，默认输出到哪里？
```

**预期输出**：
- 依据 references/cli-spec.md 给出参数表（位置参数 projectPath、-s/--sdkPath、-o/--output、-f/--format、-l/--logPath、-c/--config、--compileCommandsDir、--no-cpp、--no-arkts）
- 说明默认值：输出 `output`/merged.sarif、日志 `scanner/logs/codescanner.log`、格式 sarif
- 不向用户过度强调 SDK 解析顺序，说明"不传 -s 也能扫"

### 测试场景 2：构造扫描命令

**提示词**：
```
帮我用 codescanner 扫 D:\workspace\demo\MyApp，ArkTS 和 C++ 都要扫
```

**预期输出**：
- 先确认工具可用（codescanner -v，版本 ≥ 26.0.1）
- 给出完整命令，含 --compileCommandsDir（指向含 compile_commands.json 的目录）
- 逐项校验路径存在性；说明不传 -c 即全量检测

### 测试场景 3：解读扫描结果

**提示词**：
```
扫描结果 merged.sarif 里有很多 error，帮我解读
```

**预期输出**：
- 按 ruleId 聚合、按严重级别分组汇总
- 规则含义查 references/rules/index.md → cpp-rules.md / arkts-rules.md
- 附规则文档链接与修复方向

## 边界条件测试

### 测试场景 4：规则配置白名单语义

**提示词**：
```
我只想检测 WindowListenerNotOff 这一条规则，-c 配置怎么写？
```

**预期输出**：
- 说明 -c 是白名单：仅 skip: false 被检测，未列出自动补 skip: true（收窄范围）
- 给出 rules.arkts / rules.cpp 的 JSON 配置样例
- 提醒想全量检测则不传 -c

### 测试场景 5：版本门槛

**提示词**：
```
我本机是 25.x 的 command line tools，能跑 codescanner 吗？
```

**预期输出**：
- 明确仅 26.0.1 及以上版本支持 codescanner 扫描
- 引导升级/下载官方 command line tools，安装后 codescanner -v 核版本

### 测试场景 6：不传 -s 的 SDK 兜底

**提示词**：
```
没有配 DEVECO_SDK_HOME，也没有显式传 -s，扫描会失败吗？
```

**预期输出**：
- 说明解析顺序：部署目录上级 sdk/ → DEVECO_SDK_HOME → DEVECO_PATH/sdk → 全部未命中返回 undefined
- 未命中时跳过 ArkTS 分析但不报错（整体不因 SDK 缺失失败）

## 错误处理测试

### 测试场景 7：工具缺失

**提示词**：
```
执行 codescanner 提示不是内部或外部命令
```

**预期输出**：
- 判定为 tool-availability：二选一引导（给出工具位置 → 绝对路径调用；或官方下载页下载）
- 不直接给扫描命令；给出配 PATH 指引（可选）

### 测试场景 8：compile_commands.json 错误

**提示词**：
```
codescanner 报 compile_commands.json is not valid JSON
```

**预期输出**：
- 按三态分类解释（not found / not readable / not valid JSON），不可读优先级高于格式错误
- 该错误跳过 C++ 检查但不中断扫描；修复方向为重新生成 compile_commands.json

### 测试场景 9：退出码排查

**提示词**：
```
codescanner 退出码是 2，什么情况？
```

**预期输出**：
- 退出码 2 = 启动失败（参数校验失败 / Logger 初始化失败），无 SARIF 输出
- 此时日志文件可能不存在，先看 stderr 的 [codescanner] 错误
- 与退出码 1（有引擎失败）区分
