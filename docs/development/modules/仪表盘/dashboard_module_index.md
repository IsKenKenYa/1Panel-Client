# 仪表盘模块索引

## 模块定位

仪表盘模块是Open1PanelApp的P0核心模块，作为用户登录后的首页，提供系统运行状态概览、资源监控、应用启动器、快捷跳转等核心功能，是用户了解系统状态的主要入口。

## 子模块结构

基于docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json，Dashboard标签共12个端点：

| 子模块 | 端点数 | API方法 | 说明 |
|--------|--------|---------|------|
| **基础信息** | 2 | GET | 系统基本信息和OS信息 |
| **实时监控** | 4 | GET | 当前指标、节点信息、Top进程 |
| **应用启动器** | 3 | GET/POST | 应用启动器配置和展示 |
| **快捷跳转** | 2 | GET/POST | 快捷操作配置 |
| **系统操作** | 1 | POST | 系统重启操作 |

### 端点详情

#### 基础信息 (2端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/dashboard/base/:ioOption/:netOption` | GET | 获取仪表盘基础信息 |
| `/dashboard/base/os` | GET | 获取操作系统信息 |

#### 实时监控 (4端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/dashboard/current/:ioOption/:netOption` | GET | 获取当前实时指标 |
| `/dashboard/current/node` | GET | 获取节点信息 |
| `/dashboard/current/top/cpu` | GET | 获取CPU占用Top进程 |
| `/dashboard/current/top/mem` | GET | 获取内存占用Top进程 |

#### 应用启动器 (3端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/dashboard/app/launcher` | GET | 获取应用启动器列表 |
| `/dashboard/app/launcher/option` | POST | 获取应用启动器选项 |
| `/dashboard/app/launcher/show` | POST | 更新应用启动器展示 |

#### 快捷跳转 (2端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/dashboard/quick/option` | GET | 获取快捷跳转选项 |
| `/dashboard/quick/change` | POST | 更新快捷跳转配置 |

#### 系统操作 (1端点)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/dashboard/system/restart/:operation` | POST | 系统重启操作 |

## 后续规划方向

### 短期目标
- 完善基础信息卡片展示
- 实现实时监控数据获取
- 添加Top进程展示

### 中期目标
- 实现应用启动器功能
- 完善快捷跳转配置
- 添加实时图表展示

### 长期目标
- 自定义仪表盘布局
- 多节点仪表盘支持
- 智能运维建议

## 与其他模块的关系

- **监控管理**: 共享监控数据源
- **主机管理**: 获取主机信息
- **应用管理**: 应用启动器关联
- **进程管理**: Top进程数据关联
- **系统设置**: 系统操作关联

## 相关文档

- [API端点详细分析](dashboard_api_analysis.md)
- [架构设计](dashboard_module_architecture.md)
- [开发计划](dashboard_plan.md)
- [FAQ](dashboard_faq.md)

---

**文档版本**: 2.0
**最后更新**: 2026-02-15
**数据来源**: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
