# 系统设置模块索引

## 模块定位

系统设置模块是Open1PanelApp的P0核心模块，提供系统级别的配置管理能力，包括面板设置、安全配置、通知设置、快照管理等，是整个应用运行的基础配置中心。

## 增量收口记录（2026-03-30）

- Core Settings 通用端点补齐：`/core/settings/search/available`、`/core/settings/update` 已纳入客户端主链路。
- 实现策略：优先走 core 路径；当服务端返回 `404/405` 时回退到 legacy 路径（`/settings/search/available`、`/settings/update`）以兼容历史环境。
- 链路确认：`SettingV2Api -> SettingRepository -> SettingsService -> SettingsProvider -> SecuritySettingsPage/SystemSettingsPage`。
- 测试补齐：
	- `test/api_client/setting_v2_alignment_test.dart`：覆盖 core 路由与 fallback 行为。
	- `test/features/settings/settings_provider_test.dart`：覆盖 provider 更新前可用性检查。

## 子模块结构

| 子模块 | 端点数 | API客户端 | 说明 |
|--------|--------|-----------|------|
| **面板设置** | 12 | setting_v2.dart | 面板基础配置管理 |
| **安全设置** | 10 | setting_v2.dart | 安全策略和访问控制 |
| **通知设置** | 8 | setting_v2.dart | 通知渠道和规则配置 |
| **快照管理** | 8 | setting_v2.dart | 系统快照创建和恢复 |
| **备份设置** | 5 | setting_v2.dart | 系统备份策略配置 |

## 后续规划方向

### 短期目标
- 完善面板基础设置页面
- 实现安全配置管理
- 添加通知渠道配置

### 中期目标
- 完整的快照管理功能
- 系统备份策略配置
- 配置导入导出功能

### 长期目标
- 多节点配置同步
- 配置版本管理
- 自动化配置备份

## 与其他模块的关系

- **认证管理**: 安全设置联动
- **备份账户管理**: 备份策略联动
- **监控管理**: 通知设置联动
- **日志管理**: 操作日志记录

---

**文档版本**: 1.0
**最后更新**: 2026-03-30
