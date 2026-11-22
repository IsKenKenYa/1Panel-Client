# references/ — 参考资料索引

按需加载的详细参考内容，由 SKILL.md 各步骤和场景指南引用。

## 文件清单

| 文件 | 内容概要 | 何时加载 |
|------|----------|----------|
| `api-reference.md` | 接续 API 完整签名、参数/返回值、错误码、API 版本矩阵 | 步骤 4（改码）需要 API 细节时 |
| `constraints-and-prereqs.md` | 设备/组网/权限前提条件与约束清单 | 步骤 2（确认）评估前提条件时 |
| `data-migration-strategies.md` | Want 参数 / DDO / 文件资产 / 数据标识四种迁移方式的决策矩阵与代码示例 | 步骤 3（设计）数据通道选型时 |
| `state-decorator-migration.md` | V1 装饰器（@State/@Prop/@Link）→ @StorageLink 改造规则、@ComponentV2 手动 AppStorage 绑定模式、V1/V2 识别指南 | 步骤 3 识别装饰器版本时；步骤 4 改造状态变量时 |
| `ui-progress-continuity.md` | UI 浏览类页面接续方案（滚动位置、Tab 状态、Web 组件） | 处理 UI 浏览类场景时 |
| `edit-progress-continuity.md` | 内容编辑类页面接续方案（编辑器三态、表单草稿） | 处理编辑类场景时 |
| `playback-progress-continuity.md` | 媒体播放类页面接续方案（播放进度、实时流） | 处理播放类场景时 |
| `navigation-continuity.md` | 页面栈迁移方案（Navigation / Router 差异处理） | 处理页面栈迁移场景时 |

## 数据来源

全部内容基于华为开发者官方文档（2026-09 同步）：

- [应用接续概述](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-continue-cast)
- [应用接续数据迁移](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-continue-data)
- [常见接续最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-application-continue-progess)
- [UIAbility API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability)
- [分布式数据对象 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-distributedobject)

> 注意：华为文档持续更新，若 API 签名或版本要求与官方最新文档不一致，以官方文档为准。
