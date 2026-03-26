# 主机管理模块 FAQ

## Q1: Week 2 的主机管理做的是哪一段？

- 只做主机资产管理与连接测试。
- SSH、进程和监控图表不在本周范围内。

## Q2: 新增/编辑主机需要填哪些关键字段？

- 基础信息：`name / group / addr / port`
- 认证信息：`user / authMode / password` 或 `user / authMode / privateKey + passPhrase`
- 可选信息：`rememberPassword / description`

## Q3: 为什么保存按钮默认是禁用的？

- Week 2 规则要求连接相关字段修改后必须重新测试。
- 只有当前表单状态通过 `test/byinfo` 验证后，`HostAssetFormProvider.canSave` 才会变为可保存。

## Q4: 主机认证支持哪些模式？

- `password`
- `key`

切换规则：
- `authMode=password` 时会清空 `privateKey/passPhrase`
- `authMode=key` 时会清空 `password`

## Q5: App 侧为什么要对密码和私钥做 Base64？

- 这是上游 Web 端已经采用的提交口径。
- 编码逻辑放在 `HostAssetRepository`，而不是页面或 Provider。

## Q6: 列表里的 `last test status` 是服务端持久状态吗？

- 不是。
- 这是 `HostAssetsProvider` 的会话内内存状态，用来反馈当前用户刚执行过的测试结果。

## Q7: Week 2 是否使用 `/core/hosts/tree` 来渲染列表？

- 不使用。
- 当前列表主链路依赖 `POST /core/hosts/search`。
- `/core/hosts/tree` 仅保留给后续 host 选择联动或树形选择器能力。

## Q8: 删除主机会删除真实服务器吗？

- 不会。
- `POST /core/hosts/del` 只删除 1Panel 内的主机资产记录。

## Q9: 主机分组是怎么做的？

- 列表页移动分组复用共享 `GroupSelectorSheetWidget`。
- 确认后通过 `POST /core/hosts/update/group` 写回新的 `groupID`。

## Q10: Host 模块为什么仍是“部分集成”？

- 因为主机资产虽然已在 Week 2 落地，但 SSH 与 Process 仍在后续周推进。
- 所以模块级状态按 Phase 1 视角仍是分阶段完成，而不是一次性全量完成。

---
**文档版本**: 2.0
**最后更新**: 2026-03-26
