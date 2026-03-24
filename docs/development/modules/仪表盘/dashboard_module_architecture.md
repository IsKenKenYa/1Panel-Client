# 仪表盘模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供直观的系统运行状态概览
- 支持实时资源监控和Top进程展示
- 提供应用启动器和快捷跳转功能
- 统一仪表盘数据展示与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 Dashboard 标签共 12 个端点：

### 1. 基础信息模块 (2端点)

| 端点 | 方法 | 功能 | 实现状态 |
|------|------|------|----------|
| `/dashboard/base/:ioOption/:netOption` | GET | 获取仪表盘基础信息 | ✅ 已实现 |
| `/dashboard/base/os` | GET | 获取操作系统信息 | ✅ 已实现 |

**返回数据包含**：
- 主机名、IP地址
- CPU核心数
- 网站/数据库/应用数量统计
- 操作系统版本信息

### 2. 实时监控模块 (4端点)

| 端点 | 方法 | 功能 | 实现状态 |
|------|------|------|----------|
| `/dashboard/current/:ioOption/:netOption` | GET | 获取当前实时指标 | ✅ 已实现 |
| `/dashboard/current/node` | GET | 获取节点信息 | ✅ 已实现 |
| `/dashboard/current/top/cpu` | GET | 获取CPU占用Top进程 | ✅ 已实现 |
| `/dashboard/current/top/mem` | GET | 获取内存占用Top进程 | ✅ 已实现 |

**ioOption/netOption 参数说明**：
- `ioOption`: IO监控选项 (default/custom)
- `netOption`: 网络监控选项 (default/custom)

### 3. 应用启动器模块 (3端点)

| 端点 | 方法 | 功能 | 实现状态 |
|------|------|------|----------|
| `/dashboard/app/launcher` | GET | 获取应用启动器列表 | ✅ 已实现 |
| `/dashboard/app/launcher/option` | POST | 获取应用启动器选项 | ✅ 已实现 |
| `/dashboard/app/launcher/show` | POST | 更新应用启动器展示 | ✅ 已实现 |

### 4. 快捷跳转模块 (2端点)

| 端点 | 方法 | 功能 | 实现状态 |
|------|------|------|----------|
| `/dashboard/quick/option` | GET | 获取快捷跳转选项 | ✅ 已实现 |
| `/dashboard/quick/change` | POST | 更新快捷跳转配置 | ✅ 已实现 |

### 5. 系统操作模块 (1端点)

| 端点 | 方法 | 功能 | 实现状态 |
|------|------|------|----------|
| `/dashboard/system/restart/:operation` | POST | 系统重启操作 | ✅ 已实现 |

**operation 参数值**：
- `restart`: 重启系统
- `shutdown`: 关闭系统

## 业务流程与交互验证

### 仪表盘加载流程
```
用户登录成功
    ↓
加载仪表盘页面
    ↓
并行请求:
├── GET /dashboard/base/:ioOption/:netOption  (基础信息)
├── GET /dashboard/base/os                    (OS信息)
└── GET /dashboard/current/:ioOption/:netOption (实时指标)
    ↓
渲染概览卡片
    ↓
启动定时刷新 (可选)
```

### 实时监控流程
```
定时器触发 (默认30秒)
    ↓
GET /dashboard/current/:ioOption/:netOption
    ↓
更新监控数据
    ↓
刷新UI展示
    ↓
检测异常阈值 (可选告警)
```

### Top进程查看流程
```
用户点击"查看详情"
    ↓
并行请求:
├── GET /dashboard/current/top/cpu
└── GET /dashboard/current/top/mem
    ↓
展示进程列表
    ↓
用户可终止进程 (跳转进程管理)
```

### 应用启动器流程
```
GET /dashboard/app/launcher
    ↓
展示可快速启动的应用列表
    ↓
用户选择应用
    ↓
POST /dashboard/app/launcher/show
    ↓
启动应用/跳转应用详情
```

### 快捷跳转配置流程
```
GET /dashboard/quick/option
    ↓
展示可配置的快捷项列表
    ↓
用户选择配置
    ↓
POST /dashboard/quick/change
    ↓
更新快捷跳转配置
```

### 系统操作流程
```
用户点击重启/关机
    ↓
弹出确认对话框
    ↓
用户确认
    ↓
POST /dashboard/system/restart/:operation
    ↓
显示操作结果
```

## 关键边界与异常

### 数据加载异常
| 场景 | 处理方式 |
|------|----------|
| 数据请求超时 | 显示超时提示，提供重试按钮 |
| 部分数据加载失败 | 显示已加载数据，标记失败部分 |
| 网络断开 | 显示离线提示，缓存最后数据 |

### 监控异常
| 场景 | 处理方式 |
|------|----------|
| 监控数据异常值 | 显示"--"，记录日志 |
| 实时更新中断 | 停止定时器，提示用户手动刷新 |
| 数据波动过大 | 平滑处理，避免UI闪烁 |

### 操作异常
| 场景 | 处理方式 |
|------|----------|
| 系统重启失败 | 显示错误信息，建议检查权限 |
| 权限不足 | 提示联系管理员 |
| 操作被取消 | 恢复原状态，不做变更 |

## 模块分层与职责

### 前端层 (Flutter)
```
lib/features/dashboard/
├── dashboard_page.dart          # 主页面
├── dashboard_provider.dart      # 状态管理
├── widgets/
│   ├── server_info_card.dart    # 服务器信息卡片
│   ├── resource_card.dart       # 资源监控卡片
│   ├── top_processes_card.dart  # Top进程卡片 (待实现)
│   ├── app_launcher_card.dart   # 应用启动器卡片 (待实现)
│   └── quick_actions_card.dart  # 快捷操作卡片
```

### API层
```
lib/api/v2/dashboard_v2.dart     # DashboardV2Api 客户端
```

### 数据模型层
```
lib/data/models/
├── common_models.dart           # SystemInfo等通用模型
└── monitoring_models.dart       # SystemMetrics, CPUMetrics等
```

## 数据流

```
┌─────────────────────────────────────────────────────────────┐
│                      DashboardPage                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ServerInfoCard│  │ResourceCard │  │TopProcessesCard(待实现)│  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼───────────────────┼──────────────┘
          │                │                   │
          └────────────────┼───────────────────┘
                           ▼
                  ┌────────────────┐
                  │DashboardProvider│
                  │  (ChangeNotifier)│
                  └────────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
    ┌───────────┐   ┌───────────┐   ┌───────────────┐
    │getDashboard│   │getCurrent │   │getTopProcesses│
    │Base()      │   │Metrics()  │   │(待实现)        │
    └─────┬─────┘   └─────┬─────┘   └───────┬───────┘
          │               │                 │
          └───────────────┼─────────────────┘
                          ▼
                 ┌─────────────────┐
                 │ DashboardV2Api  │
                 │   (DioClient)   │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │  1Panel Server  │
                 │   /api/v2/*     │
                 └─────────────────┘
```

## 与现有实现的差距分析

### 已实现功能
| 功能 | 实现位置 | 覆盖度 |
|------|----------|--------|
| 基础信息获取 | dashboard_v2.dart | ✅ 100% |
| OS信息获取 | dashboard_v2.dart | ✅ 100% |
| 当前指标获取 | dashboard_v2.dart | ✅ 100% |
| 节点信息获取 | dashboard_v2.dart | ✅ 100% |
| Top CPU进程获取 | dashboard_v2.dart | ✅ 100% |
| Top内存进程获取 | dashboard_v2.dart | ✅ 100% |
| 应用启动器API | dashboard_v2.dart | ✅ 100% |
| 快捷跳转API | dashboard_v2.dart | ✅ 100% |
| 系统重启 | dashboard_v2.dart | ✅ 100% |
| 服务器信息卡片 | dashboard_page.dart | ✅ 基础实现 |
| 资源监控卡片 | dashboard_page.dart | ✅ 基础实现 |
| 快捷操作卡片 | dashboard_page.dart | ✅ 基础实现 |

### 待完善UI功能
| 功能 | 优先级 | 预估工时 |
|------|--------|----------|
| Top进程卡片UI | P0 | 4h |
| 应用启动器卡片UI | P1 | 4h |
| 快捷跳转配置UI | P1 | 3h |
| 实时图表展示 | P1 | 6h |
| 网络流量卡片 | P2 | 4h |

### 已修复的问题
| 问题 | 位置 | 修复内容 |
|------|------|----------|
| HTTP方法错误 | dashboard_v2.dart | systemRestart从GET改为POST |
| 自创端点 | dashboard_v2.dart | 移除13个非OpenAPI规范的方法 |
| 缺少API方法 | dashboard_v2.dart | 新增7个OpenAPI规范端点 |

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
|------|--------|------|------|
| 2026-02-15 | 自动分析 | 需优化 | API端点与OpenAPI规范对齐 |

---

**文档版本**: 2.0
**最后更新**: 2026-02-15
**数据来源**: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
