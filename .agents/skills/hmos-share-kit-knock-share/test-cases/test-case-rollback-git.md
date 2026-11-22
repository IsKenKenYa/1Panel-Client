# 用例：git 环境失败回滚

## 目标

变更写入后失败时，依据阶段 0 的回滚能力预判与基线快照，用 git checkout 还原本次会话改动的文件。

## 前置

- 工程在 git 版控下，已 commit，工作区干净
- 本 Skill `assets/file/` 可读
- 验收时模拟：写入过程中触发失败（如 `sdk-profile-snippet.json5` 临时不可读、或编译失败且无法修复）
- 用户提出接入请求（见 [test-prompts.md](test-prompts.md) 场景 15）

## 步骤

1. 用场景 15 触发
2. 确认阶段 0 记录了 git 版控状态与基线快照（git status / HEAD commit）
3. 确认变更预览后 agent 开始写文件
4. 模拟写入中途失败（临时破坏模板文件 / 编译报错且不可修复）
5. 观察回滚行为

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S22, S23

## 通过标准

- [ ] 阶段 0 记录了工程在 git 版控下（S22）
- [ ] 阶段 0 记录了基线快照（git status / HEAD commit 或等价信息）（S22）
- [ ] 失败后执行 `git checkout` 还原本次会话改动的文件（先 `git status` 比对基线快照确认范围）（S23）
- [ ] 已拷入的资产文件（Manager/Provider/KnockRectUtil）若属于本次新增 → 一并还原
- [ ] 回滚后输出回滚原因 + 已还原文件清单 + 人工下一步建议（S23）
- [ ] **未**凭记忆重写或跳过回滚直接重试
