# 用例：仅文件不混链接

## 目标

仅文件接入时，提问与实现均不含链接侧 stub。

## 前置

- 提示词已指定仅文件（可用场景 1）
- 本 Skill `assets/file/` 与 `wiring-snippet-file.ets` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 6（或场景 1）触发
2. 检查提问与工程改动

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S8, S9, S21

## 通过标准

- [ ] 提问中无 App Linking、域名、HYPERLINK、落地页等链接项（S8）
- [ ] 拷贝来源 `assets/file/`；无 `getLinkShareData` / HYPERLINK / `example.com`（S9）
- [ ] 接线只打开 `wiring-snippet-file.ets`，不打开 link/both（S21）
- [ ] 无 App Linking 端侧改码
