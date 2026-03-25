# 提交信息规范（供生成器/机器人参考）

目标：提交信息需同时包含中文和英文两份，中文/英文顺序可互换，但两份内容必须完全相同，且遵循 Conventional Commits 规范。

要求：
- Header 使用 Conventional Commits：`<type>(<scope>): <subject>`，其中 `type` 必须使用英文关键字（例如 `feat`, `fix`, `docs`, `chore` 等）。
- `scope` 可选，仅在必要时使用（如影响模块/子系统）。
- `subject` 以中文编写（或中文/英文同时出现）；要求简洁、准确、具体（不使用空泛表述）。
- 必须在消息中包含 `CN:` / `CN-BODY:` 和 `EN:` / `EN-BODY:` 段（顺序可换）；如果工具只生成了一份，请把该份复制到另一个段，保证两份完全相同。
- 详细说明（body）可选，若有请先写中文，再在 `EN-BODY:` 段重复相同内容（或反过来，按首选语言复制）。
- 对于 API、命令、路径、库名、产品名等专有名词，请保留官方写法，不要生硬翻译。

示例（中文优先）：

feat(auth): 添加用户登录

添加基于 OAuth2 的用户登录流程，并完善错误处理。

CN: feat(auth): 添加用户登录

CN-BODY:
添加基于 OAuth2 的用户登录流程，并完善错误处理。

EN: feat(auth): 添加用户登录

EN-BODY:
添加基于 OAuth2 的用户登录流程，并完善错误处理。

示例（英文优先）：

feat(auth): Add user login

Adds OAuth2-based login flow and improves error handling.

EN: feat(auth): Add user login

EN-BODY:
Adds OAuth2-based login flow and improves error handling.

CN: feat(auth): Add user login

CN-BODY:
Adds OAuth2-based login flow and improves error handling.

说明：本文件用于辅助自动化工具（如 Copilot/Codegeex）生成符合项目约定的 commit message。工具可能会读取此文件中的指导文本来决定输出风格。若你使用的工具没有读取此文件，请确保手动遵守以上规范。
