# 评测说明（hmos-arkui-kit-window-floatwindow）

供 `hmos-skill-test-runner` 使用。只认三个固定文件：

| 文件 | 作用 |
|------|------|
| `trigger.md` | 触发验证（必需） |
| `smoke.md` | 分流冒烟（可选） |
| `functional.md` | 功能问答（必需） |

用例标题必须是 `### 测试用例：XXX`。流水线会对**每条**用例另起 `claude -p` 子进程（超时 180s），以 `SKILL.md` 为 system prompt。

本套用例刻意极简：输入要求「不要读文件、只答一行/一句」，预期只卡关键词，避免超时与误杀。

本地自测：`python3 test-cases/selfcheck.py`
