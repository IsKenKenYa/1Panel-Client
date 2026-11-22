# L6 跨平台 / 回归测试用例

> 层对象：Windows/Linux 差异、变更回归
> 质量属性：跨平台/回归稳定性
> 编号规则：TC-L6-<序号>

---

## TC-L6-01 CRLF shell 脚本修复（P0）

- 前置：Linux 执行 Windows 产物
- 步骤：构造含 CRLF 的 `bin/codescanner`，运行报 `required file not found`；执行 `sed -i 's/\r$//'` 后重跑
- 预期：修复前报错、修复后正常；error-troubleshooting.md §2.5 描述一致
- 对应 run-eval.js：C8（文档断言，可升级为真实执行）

---

## TC-L6-02 Windows 权限路径差异（P0）

- 前置：Windows
- 步骤：对目录 deny 写权限（icacls），运行 CLI
- 预期：预检阶段 `is not writable: <p> (<errno>)`，退出码 2（写探测生效，accessSync(W_OK) 未误判通过）

---

## TC-L6-03 Linux SDK include 注入（P1）

- 前置：Linux + 部署 26.0.1.272
- 步骤：静态断言 cpp-rules.md / error-troubleshooting.md 含"toolchain file 不会自动注入 SDK include 到 compile_commands.json -I"；有条件的 Linux 机可复现
- 预期：文档描述与实际行为一致

---

## TC-L6-04 多套安装 PATH 抢占（P1）

- 前置：部署两套 codescanner
- 步骤：`codescanner -v` 与绝对路径调用对比
- 预期：文档建议用绝对路径；`codescanner -v` 显示版本可用于确认 PATH 指向

---

## TC-L6-05 知识库/脚本变更回归（P0）

- 步骤：任何 references/*.md、scripts/*.js、fixtures 变更后全量 `node scripts/run-eval.js`
- 预期：0 failed；新增断言全部纳入；CI（.cloudbuild）可挂接
- 说明：本用例即 L4 全部用例的聚合回归
