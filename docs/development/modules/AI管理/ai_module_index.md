# AI管理模块索引

## 模块定位

AI管理模块是Open1PanelApp的**智能服务模块**，负责Ollama大语言模型服务和MCP（Model Context Protocol）服务器的管理与部署。该模块为用户提供本地AI能力部署和管理，支持GPU加速、模型管理、域名绑定等功能。

## S2-0 基线（2026-03-26）

- 当前状态：
  `AIPage / AIProvider / AIService / AIRepository` 已存在，但缺 `route / entry / injection`，当前在产品中不可达。
- 阶段 2 hard scope：
  `route / injection / entry / domain binding linkage`
- API 基线：
  `check_module_api_updates.py ai` 当前结果为 `unchanged`

### 核心职责

1. **Ollama模型管理** - 模型下载、加载、删除
2. **MCP服务器管理** - 创建、配置、启停
3. **GPU/XPU监控** - 硬件资源监控
4. **域名绑定** - 服务对外访问配置
5. **模型同步** - 模型列表同步更新

## 子模块结构

```
AI管理/
├── Ollama模型管理
│   ├── 模型列表
│   ├── 模型下载
│   ├── 模型加载/卸载
│   └── 模型删除
├── MCP服务器管理
│   ├── 服务器列表
│   ├── 创建服务器
│   ├── 配置更新
│   └── 启停操作
├── 硬件监控
│   ├── GPU信息
│   ├── 显存使用
│   └── 温度监控
└── 域名配置
    ├── Ollama域名
    ├── MCP域名
    └── SSL配置
```

## API端点映射

| API端点 | 方法 | 功能描述 | 实现状态 |
|---------|------|---------|---------|
| `/ai/domain/bind` | POST | 绑定Ollama域名 | ✅ 已实现 |
| `/ai/domain/get` | POST | 获取绑定域名 | ✅ 已实现 |
| `/ai/gpu/load` | GET | 加载GPU信息 | ✅ 已实现 |
| `/ai/ollama/model` | POST | 创建Ollama模型 | ✅ 已实现 |
| `/ai/ollama/close` | POST | 关闭模型连接 | ✅ 已实现 |
| `/ai/ollama/model/del` | POST | 删除模型 | ✅ 已实现 |
| `/ai/ollama/model/load` | POST | 加载模型 | ✅ 已实现 |
| `/ai/ollama/model/recreate` | POST | 重建模型 | ✅ 已实现 |
| `/ai/ollama/model/search` | POST | 搜索模型 | ✅ 已实现 |
| `/ai/ollama/model/sync` | POST | 同步模型列表 | ✅ 已实现 |
| `/ai/mcp/domain/bind` | POST | 绑定MCP域名 | ✅ 已实现 |
| `/ai/mcp/domain/get` | GET | 获取MCP域名 | ✅ 已实现 |
| `/ai/mcp/domain/update` | POST | 更新MCP域名 | ✅ 已实现 |
| `/ai/mcp/search` | POST | 搜索MCP服务器 | ✅ 已实现 |
| `/ai/mcp/server` | POST | 创建MCP服务器 | ✅ 已实现 |
| `/ai/mcp/server/del` | POST | 删除MCP服务器 | ✅ 已实现 |
| `/ai/mcp/server/op` | POST | 操作MCP服务器 | ✅ 已实现 |
| `/ai/mcp/server/update` | POST | 更新MCP服务器 | ✅ 已实现 |

## 现有实现

### API客户端
- [ai_v2.dart](../../../lib/api/v2/ai_v2.dart) - 18个API方法

### 数据模型
- [ai_models.dart](../../../lib/data/models/ai_models.dart) - AI模型定义
  - `OllamaBindDomain` - 域名绑定请求
  - `OllamaBindDomainRes` - 域名绑定响应
  - `OllamaModelName` - 模型名称
  - `OllamaModel` - 模型信息
  - `GpuInfo` - GPU信息
- [mcp_models.dart](../../../lib/data/models/mcp_models.dart) - MCP模型定义

## 支持的AI服务

| 服务类型 | 说明 | 状态 |
|---------|------|------|
| **Ollama** | 本地大语言模型服务 | ✅ 支持 |
| **MCP Server** | Model Context Protocol服务器 | ✅ 支持 |

## GPU监控指标

| 指标 | 说明 |
|------|------|
| **productName** | GPU型号 |
| **temperature** | 温度 |
| **gpuUtil** | GPU利用率 |
| **memTotal** | 总显存 |
| **memUsed** | 已用显存 |
| **memoryUsage** | 显存使用率 |
| **powerDraw** | 功耗 |
| **fanSpeed** | 风扇转速 |

## 后续规划

### 短期目标（1-2周）
1. 创建AI管理主页面
2. 实现Ollama模型列表
3. 添加GPU监控展示
4. 添加单元测试覆盖

### 中期目标（1个月）
1. 完善MCP服务器管理UI
2. 实现模型下载进度显示
3. 添加域名绑定配置
4. 实现模型性能监控

### 长期目标
1. 支持更多AI框架
2. 实现模型微调
3. 添加AI应用市场
4. 支持分布式推理

## 质量指标

| 指标 | 当前状态 | 目标 |
|------|---------|------|
| API实现 | 100% | 100% |
| 数据模型 | 100% | 100% |
| 单元测试 | 100% | ≥80% |
| 文档覆盖 | 0% | 100% |
| UI实现 | 0% | 100% |

---

**文档版本**: 1.0  
**最后更新**: 2026-02-14  
**维护者**: Open1Panel开发团队
