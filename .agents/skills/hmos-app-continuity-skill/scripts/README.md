# scripts/ — ArkTS 静态语法检查工具

本目录提供 Skill 自带的静态语法检查能力，供**步骤 5（自检）**使用。

## 何时使用

| 环境 | 检查手段（按优先级） |
|------|---------------------|
| devecocli 已安装 | `devecocli check lint <文件>` / `devecocli build` |
| **无 devecocli，但装有 DevEco Studio（≥ 26.0.0.610）** | **本目录脚本** |
| 均不可用 | 编译验证列入人工操作项 |

## 用法

```powershell
# 有 Node 的机器（任意 Node ≥ 16，Windows / macOS 通用）：
node scripts/arkts-check.js --project <工程根目录绝对路径> <文件1.ets> [文件2.ets ...] --json

# 没有 Node 的 Windows 机器 —— 用 ps1 启动器（自动改用 DevEco Studio 自带 node.exe）：
powershell -File scripts/arkts-check.ps1 --project <工程根目录> <文件.ets> --json
```

```sh
# 没有 Node 的 macOS 机器 —— 用 sh 启动器（自动改用 DevEco Studio 自带 node；未真机验证）：
./scripts/arkts-check.sh --project <工程根目录> <文件.ets> --json
```

- 文件路径支持绝对路径或相对工程根的相对路径；仅支持 `.ets`
- 脚本自动发现 DevEco Studio 安装（`--studio <路径>` 或环境变量
  `DEVECO_STUDIO_PATH` 可显式指定；默认按注册表 → 常见路径顺序探测）
- 工程**无需** hvigor 同步、无需在 IDE 打开过（ace-server 直接读
  `build-profile.json5` / `oh-package.json5`）

## 平台支持

| 平台 | 状态 |
|------|------|
| Windows | ✅ 完整实现并实测（注册表 + 常见路径自动发现；`arkts-check.ps1` 启动器） |
| macOS | ⚠️ 代码已就绪但**未真机验证**：自动扫描 `/Applications` 与 `~/Applications` 下名字含 "deveco" 的 `.app`；安装布局按 IntelliJ 平台惯例与 devecocli 的 mac 逻辑推测（`Contents/plugins/...`、`Contents/tools/node/bin/node`）。若发现/校验失败，用 `--studio "<路径>/DevEco Studio.app"` 或环境变量 `DEVECO_STUDIO_PATH` 显式指定 |
| Linux | ❌ 不支持 —— DevEco Studio 无 Linux 版本，标准 LSP 引擎在该平台不存在；Linux 环境请走 `devecocli build`（需 Command Line Tools）或列入人工操作 |

## 输出与判定

- 文本模式：`<文件> => no diagnostics` 或 `<文件> => Diagnostic: [{range, severity, message, code, source}, ...]`
- `--json` 模式：`{ ok, project, server, summary, results }`，适合 agent 解析
- 诊断来源：`tsCheck`（语法/类型错误、未使用、废弃 API）、`ArkTSCheck`
  （arkts-no-any-unknown、arkts-no-destruct-decls 等语言规则）、`etsLint`（规则建议+quickfix）

**判定口径：error 级（severity=1）诊断必须修复后重检；warning/deprecation 记入报告即可。**

| 退出码 | 含义 |
|--------|------|
| 0 | 运行成功，无 error 级诊断 |
| 1 | 运行成功，至少一个文件有 error 级诊断 |
| 2 | 运行失败（找不到 DevEco Studio、启动失败、超时等） |

## 性能

- 每工程首次运行约 15–30s（ace-server 冷启动 + 工程解析 + 索引；索引缓存建在工程内）
- 同一工程后续运行全程约 5–10s；每文件纯检查 < 1s
- 存量文件可能带出大量 warning/deprecation，agent 消费建议 `--json` 并过滤 `severity === 1`

## 已知限制

1. 仅支持 `.ets`（ArkTS）；C/C++ 不覆盖（NAPI 侧本就属人工操作项）
2. DevEco Studio < 26.0.0.610（只有 legacy LSP 入口）会明确报错退出（退出码 2）
3. DSH 等受限沙箱中运行会因子进程 stdio 管道限制报 `spawn EPERM`，需以完整权限执行；
   其他 agent / 终端环境不受影响
4. ace-server 运行时会向华为上报遥测（与 DevEco Studio IDE 同款行为）
