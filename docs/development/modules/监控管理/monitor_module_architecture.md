# 监控管理模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的服务器性能监控能力
- 支持CPU、内存、磁盘、网络等核心指标监控
- 提供告警配置和通知功能
- 统一监控数据展示与管理

## API端点规范

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 Monitor 标签：

### POST /hosts/monitor/search

**请求参数** (dto.MonitorSearch):
```json
{
  "endTime": "string",
  "info": "string",
  "param": "all",
  "startTime": "string"
}
```

**param 枚举值** (重要！):
| 值 | 说明 | 返回数据 |
|---|---|---|
| `cpu` | CPU监控 | `{cpu: number}` |
| `memory` | 内存监控 | `{memory: number}` |
| `load` | 负载监控 | `{load1: number, load5: number, load15: number}` |
| `io` | IO监控(磁盘) | `{disk: number, read: number, write: number}` |
| `network` | 网络监控 | `{networkIn: number, networkOut: number}` |
| `all` | 全部监控 | 返回所有指标 |
| `base` | 基础监控 | `{cpu, memory, load1, ...}` |

**注意**: 没有 `disk` 参数！磁盘数据从 `io` 参数获取。

**响应格式**:
```json
{
  "code": 200,
  "data": [
    {
      "param": "base",
      "date": ["2026-02-15T13:11:02.055103768+08:00", ...],
      "value": [
        {
          "id": 63972,
          "cpu": 0.58,
          "memory": 37.17,
          "load1": 0.12,
          "topCPU": "",
          "topMemory": ""
        },
        ...
      ]
    },
    {
      "param": "io",
      "date": [...],
      "value": [
        {
          "disk": 45.2,
          "read": 1024,
          "write": 512
        },
        ...
      ]
    }
  ]
}
```

### GET /hosts/monitor/setting

获取监控设置

### POST /hosts/monitor/clean

清理监控数据

## 数据字段映射

### API响应字段 (param='base')

```
[id, createdAt, updatedAt, cpu, topCPU, topCPUItems, memory, topMem, topMemItems, loadUsage, cpuLoad1, cpuLoad5, cpuLoad15]
```

### 服务器卡片监控数据

| 显示项 | API参数 | 字段路径 |
|---|---|---|
| CPU使用率 | `base` 或 `cpu` | `value[-1].cpu` |
| 内存使用率 | `base` 或 `memory` | `value[-1].memory` |
| 系统负载 | `base` 或 `load` | `value[-1].cpuLoad1` |
| 磁盘使用率 | `io` | `value[-1].disk` |

**注意**: 
- 负载字段是 `cpuLoad1`，不是 `load1`
- `base` 参数返回的数据中没有磁盘字段，磁盘数据需要从 `io` 参数获取
- **磁盘数据可能为空**：如果服务器端未配置IO监控，API返回 `{param: io, date: null, value: null}`

### API响应示例

**正常情况** (服务器配置了IO监控):
```json
{
  "data": [
    {"param": "base", "date": [...], "value": [{...}]},
    {"param": "io", "date": [...], "value": [{...}]}
  ]
}
```

**IO监控未配置**:
```json
{
  "data": [
    {"param": "base", "date": [...], "value": [{...}]},
    {"param": "io", "date": null, "value": null}
  ]
}
```

当 `io.value` 为 `null` 时，磁盘数据显示为 `--`

## 业务流程与交互验证

### 实时监控流程
- 进入监控页面
- 显示实时性能指标
- 支持时间范围选择
- 支持指标筛选
- 支持图表缩放和拖动

### 告警配置流程
- 进入告警配置页面
- 创建告警规则
- 配置告警阈值
- 设置通知方式
- 测试告警通知

### 历史数据分析流程
- 选择时间范围
- 选择监控指标
- 生成趋势图表
- 支持数据导出
- 支持对比分析

## 关键边界与异常

### 监控数据异常
- 数据获取失败的诊断
- 数据异常值的处理
- 监控服务不可用的提示

### 告警异常
- 告警通知失败的诊断
- 告警规则冲突的处理
- 告警风暴的防护

### 性能影响
- 监控数据采集影响性能
- 大量历史数据加载慢
- 图表渲染性能问题

## 模块分层与职责

### 前端
- UI页面: 监控仪表盘、告警配置、历史数据、通知设置
- 状态管理: 监控数据缓存、告警状态、通知状态

### 服务层
- API适配: MonitorV2Api
- 数据模型: MonitorData、MonitorAlert、MonitorNotification等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 图表渲染
4. 实时监控 -> WebSocket/轮询 -> 数据更新

## 常见问题

### Q: 为什么磁盘数据显示为空？
A: 磁盘数据需要从 `io` 参数获取，不是 `disk` 参数。OpenAPI规范中 `param` 枚举值是：`cpu`, `memory`, `load`, `io`, `network`，没有 `disk`。

### Q: 为什么负载数据显示为空？
A: 负载数据字段是 `load1`（1分钟负载），不是 `load`。完整字段包括 `load1`, `load5`, `load15`。

### Q: 时间格式要求？
A: 必须使用UTC时区的ISO8601格式，例如：`2026-02-15T13:05:02.340098Z`

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 2026-02-15 | 自动分析 | 已修正 | 修正param枚举值映射 |

---

**文档版本**: 2.0  
**最后更新**: 2026-02-15  
**维护者**: Open1Panel开发团队
