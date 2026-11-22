# 用例：增量补另一种类型

## 目标

工程已有文件侧隔空传送时，再接入链接分享：升级为 both，不注册第二套监听。

## 前置

- `targetSdkVersion` ≥ `6.0.0(20)`
- 工程中已有管理类 / 业务类或 `gesturesShare` 监听（文件侧）
- 本 Skill `assets/both/` 可读

## 步骤

1. 用 [test-prompts.md](test-prompts.md) 场景 4 触发
2. 观察是否检测已有接入、如何升级
3. 检查监听是否仍只有一套

## 本场景重点标准

见 [acceptance-checklist.md](acceptance-checklist.md)：S5, S9

## 通过标准

- [ ] 检测到已有管理类 / 业务类 / 监听，并说明现状
- [ ] 用 `assets/both/` 覆盖或合并升级，补缺失的链接取数方法（S9）
- [ ] **未**新建第二套管理类或第二套 `gesturesShare` 监听（S5）
- [ ] `enable` 签名与 both 包一致（含 mode 时按 both）
- [ ] 增量时只问本次要补的链接侧必问项（或授权自决），不问无关文件细节
