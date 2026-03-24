# 仪表盘模块开发计划

## 里程碑定义

### M1: 核心功能完善 (第1-2周)
- Top进程API对接
- Top进程卡片UI
- 数据刷新优化

### M2: 应用启动器 (第3-4周)
- 应用启动器API对接
- 应用启动器UI
- 快捷启动功能

### M3: 快捷跳转配置 (第5-6周)
- 快捷跳转API对接
- 快捷跳转配置UI
- 个性化配置持久化

### M4: 增强与优化 (第7-8周)
- 实时图表展示
- 性能优化
- 测试覆盖

## 任务分解

### API层任务

| 任务 | 端点 | 优先级 | 预估工时 | 状态 |
|------|------|--------|----------|------|
| getTopCPUProcesses | GET /dashboard/current/top/cpu | P0 | 1h | ❌ 待开发 |
| getTopMemProcesses | GET /dashboard/current/top/mem | P0 | 1h | ❌ 待开发 |
| getAppLauncher | GET /dashboard/app/launcher | P1 | 1h | ❌ 待开发 |
| getAppLauncherOption | POST /dashboard/app/launcher/option | P1 | 1h | ❌ 待开发 |
| updateAppLauncherShow | POST /dashboard/app/launcher/show | P1 | 1h | ❌ 待开发 |
| getQuickOption | GET /dashboard/quick/option | P1 | 1h | ❌ 待开发 |
| updateQuickChange | POST /dashboard/quick/change | P1 | 1h | ❌ 待开发 |

### 数据层任务

| 任务 | 优先级 | 预估工时 | 状态 |
|------|--------|----------|------|
| TopProcessInfo模型 | P0 | 1h | ❌ 待开发 |
| AppLauncherInfo模型 | P1 | 1h | ❌ 待开发 |
| QuickJumpOption模型 | P1 | 1h | ❌ 待开发 |

### UI层任务

| 任务 | 优先级 | 预估工时 | 依赖 | 状态 |
|------|--------|----------|------|------|
| Top进程卡片组件 | P0 | 4h | TopProcessInfo模型 | ❌ 待开发 |
| 应用启动器卡片 | P1 | 4h | AppLauncherInfo模型 | ❌ 待开发 |
| 快捷跳转配置页面 | P1 | 3h | QuickJumpOption模型 | ❌ 待开发 |
| 实时图表组件 | P1 | 6h | 无 | ❌ 待开发 |
| 网络流量卡片 | P2 | 4h | 无 | ❌ 待开发 |

### Provider层任务

| 任务 | 优先级 | 预估工时 | 状态 |
|------|--------|----------|------|
| loadTopProcesses方法 | P0 | 2h | ❌ 待开发 |
| loadAppLauncher方法 | P1 | 2h | ❌ 待开发 |
| loadQuickOptions方法 | P1 | 1h | ❌ 待开发 |
| updateQuickOptions方法 | P1 | 1h | ❌ 待开发 |
| 数据缓存机制 | P1 | 2h | ❌ 待开发 |

### 测试任务

| 任务 | 优先级 | 预估工时 | 依赖 |
|------|--------|----------|------|
| Top进程API测试 | P0 | 1h | API层完成 |
| 应用启动器API测试 | P1 | 1h | API层完成 |
| 快捷跳转API测试 | P1 | 1h | API层完成 |
| Provider单元测试 | P1 | 3h | Provider层完成 |
| Widget测试 | P2 | 4h | UI层完成 |
| 集成测试 | P2 | 4h | 全部完成 |

## API端点实现状态

基于docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json的12个端点：

| 端点 | 方法 | 实现状态 | 备注 |
|------|------|----------|------|
| `/dashboard/base/:ioOption/:netOption` | GET | ✅ 已实现 | |
| `/dashboard/base/os` | GET | ✅ 已实现 | |
| `/dashboard/current/:ioOption/:netOption` | GET | ✅ 已实现 | |
| `/dashboard/current/node` | GET | ✅ 已实现 | |
| `/dashboard/current/top/cpu` | GET | ✅ 已实现 | 新增 |
| `/dashboard/current/top/mem` | GET | ✅ 已实现 | 新增 |
| `/dashboard/app/launcher` | GET | ✅ 已实现 | 新增 |
| `/dashboard/app/launcher/option` | POST | ✅ 已实现 | 新增 |
| `/dashboard/app/launcher/show` | POST | ✅ 已实现 | 新增 |
| `/dashboard/quick/option` | GET | ✅ 已实现 | 新增 |
| `/dashboard/quick/change` | POST | ✅ 已实现 | 新增 |
| `/dashboard/system/restart/:operation` | POST | ✅ 已实现 | 已修复HTTP方法 |

**实现进度**: 12/12 = **100%** ✅

## 风险与应对策略

### 技术风险

| 风险 | 影响 | 概率 | 应对策略 |
|------|------|------|----------|
| Top进程数据量大 | 中 | 中 | 分页加载，限制显示数量 |
| 实时更新性能 | 中 | 中 | 合理刷新间隔，增量更新 |
| 应用启动器兼容性 | 低 | 低 | 按API规范实现 |

### 业务风险

| 风险 | 影响 | 概率 | 应对策略 |
|------|------|------|----------|
| 数据展示不准确 | 高 | 低 | 提供刷新机制，数据校验 |
| 系统操作误触 | 高 | 中 | 二次确认对话框 |
| 配置丢失 | 中 | 低 | 本地缓存 + 服务端同步 |

### 进度风险

| 风险 | 影响 | 概率 | 应对策略 |
|------|------|------|----------|
| API文档不完整 | 中 | 中 | 参考源码，测试验证 |
| UI组件复杂度 | 中 | 中 | 使用成熟组件库 |

## 验收标准

### 功能验收
- [ ] 12个API端点全部实现
- [ ] Top进程卡片正确显示
- [ ] 应用启动器功能正常
- [ ] 快捷跳转配置可保存
- [ ] 系统重启/关机功能正常

### 质量验收
- [ ] API客户端单元测试覆盖率≥80%
- [ ] Provider单元测试覆盖率≥80%
- [ ] 页面加载时间<1s
- [ ] 数据刷新间隔可配置
- [ ] 无严重Bug

### 文档验收
- [ ] API端点文档完整
- [ ] 使用说明清晰
- [ ] FAQ覆盖常见问题

## 代码清理任务

### 需要处理的额外API方法

当前 `dashboard_v2.dart` 中存在以下非OpenAPI规范的方法，需要评估处理：

| 方法 | 建议 |
|------|------|
| getCPUUsage | 移除或标记为扩展功能 |
| getMemoryUsage | 移除或标记为扩展功能 |
| getDiskUsage | 移除或标记为扩展功能 |
| getNetworkStats | 移除或标记为扩展功能 |
| getProcesses | 移除或标记为扩展功能 |
| getSystemLoad | 移除或标记为扩展功能 |
| getServiceStatus | 移除或标记为扩展功能 |
| getPortUsage | 移除或标记为扩展功能 |
| getSystemTime | 移除或标记为扩展功能 |
| getSystemUpdates | 移除或标记为扩展功能 |
| getSecurityStatus | 移除或标记为扩展功能 |
| getBackupStatus | 移除或标记为扩展功能 |
| getApplicationStatus | 移除或标记为扩展功能 |

**建议**: 这些方法可能是为未来功能预留或从其他版本迁移，应标记为 `@experimental` 或移到扩展API类中。

---

**文档版本**: 2.0
**最后更新**: 2026-02-15
**数据来源**: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
