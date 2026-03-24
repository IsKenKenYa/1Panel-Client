# 仪表盘模块FAQ

## 常见问题

### 1. 仪表盘数据多久刷新一次？

**默认配置**:
- 基础信息：页面加载时获取，手动刷新
- 实时指标：默认30秒自动刷新
- Top进程：按需加载

**自定义**: 可通过 `startAutoRefresh(interval)` 方法调整刷新间隔

### 2. 为什么CPU/内存使用率显示异常？

**可能原因**:
- 系统负载瞬时波动
- 数据采集延迟
- 多核CPU显示问题

**解决方案**:
1. 等待数据自动刷新
2. 手动刷新仪表盘
3. 检查API响应数据

### 3. 如何查看占用资源最多的进程？

**操作步骤**:
1. 在仪表盘页面找到资源监控卡片
2. 点击"查看详情"或Top进程卡片
3. 系统会调用 `/dashboard/current/top/cpu` 和 `/dashboard/current/top/mem` 获取数据
4. 展示CPU和内存占用最高的进程列表

### 4. 应用启动器是什么功能？

**功能说明**:
- 应用启动器提供快速访问已安装应用的入口
- 通过 `/dashboard/app/launcher` 获取可启动的应用列表
- 支持自定义展示的应用

**使用方式**:
1. 在仪表盘找到应用启动器卡片
2. 点击应用图标快速跳转或启动

### 5. 快捷跳转可以自定义吗？

**当前状态**: API已支持，UI待实现

**API端点**:
- `GET /dashboard/quick/option` - 获取可配置的快捷项
- `POST /dashboard/quick/change` - 更新快捷跳转配置

### 6. 系统重启/关机操作安全吗？

**安全措施**:
- 操作前弹出确认对话框
- 需要用户二次确认
- 显示操作结果反馈

**注意事项**:
- 重启前确保保存重要工作
- 关机操作不可逆

### 7. ioOption和netOption参数是什么？

**参数说明**:
- `ioOption`: IO监控选项
  - `default`: 使用默认配置
  - `custom`: 使用自定义配置
- `netOption`: 网络监控选项
  - `default`: 使用默认配置
  - `custom`: 使用自定义配置

**使用示例**:
```
GET /dashboard/base/default/default
GET /dashboard/current/default/default
```

### 8. 为什么仪表盘加载很慢？

**排查步骤**:
1. 检查网络连接状态
2. 检查服务器负载情况
3. 查看API响应时间
4. 减少刷新频率

**性能优化建议**:
- 使用合理的刷新间隔
- 启用数据缓存
- 并行请求多个API

### 9. 如何获取节点信息？

**API端点**: `GET /dashboard/current/node`

**返回数据**:
- 节点名称
- 节点状态
- 节点配置信息

### 10. API端点实现进度如何？

**当前状态** (基于docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json):

| 功能模块 | 端点数 | 已实现 | 进度 |
|----------|--------|--------|------|
| 基础信息 | 2 | 2 | 100% |
| 实时监控 | 4 | 4 | 100% |
| 应用启动器 | 3 | 3 | 100% |
| 快捷跳转 | 2 | 2 | 100% |
| 系统操作 | 1 | 1 | 100% |
| **总计** | **12** | **12** | **100%** ✅ |

## 故障排查指南

### 数据加载问题
```
错误: 仪表盘数据加载失败
排查:
1. 检查API连接状态 (GET /dashboard/base/os)
2. 验证用户权限
3. 查看服务端日志
4. 尝试重新登录
```

### Top进程显示问题
```
错误: Top进程数据为空
排查:
1. 确认API端点已实现 (GET /dashboard/current/top/cpu)
2. 检查返回数据格式
3. 验证进程数据是否存在
```

### 系统操作失败
```
错误: 系统重启失败
排查:
1. 检查用户权限
2. 确认operation参数正确 (restart/shutdown)
3. 查看系统日志
4. 检查服务端返回的错误信息
```

### 实时更新中断
```
错误: 数据不更新
排查:
1. 检查定时器是否运行
2. 验证网络连接
3. 检查API响应
4. 重启应用
```

## 最佳实践

### 监控建议
- 设置合理的刷新间隔 (建议30-60秒)
- 关注异常指标变化
- 定期查看Top进程
- 配置告警阈值 (未来功能)

### 性能建议
- 避免过高的刷新频率
- 合理使用数据缓存
- 并行请求独立数据
- 延迟加载非关键数据

### 运维建议
- 定期检查系统状态
- 及时处理异常进程
- 保持系统资源充足
- 记录异常情况

## API快速参考

| 端点 | 方法 | 功能 |
|------|------|------|
| `/dashboard/base/:ioOption/:netOption` | GET | 基础信息 |
| `/dashboard/base/os` | GET | OS信息 |
| `/dashboard/current/:ioOption/:netOption` | GET | 实时指标 |
| `/dashboard/current/node` | GET | 节点信息 |
| `/dashboard/current/top/cpu` | GET | Top CPU进程 |
| `/dashboard/current/top/mem` | GET | Top内存进程 |
| `/dashboard/app/launcher` | GET | 应用启动器 |
| `/dashboard/app/launcher/option` | POST | 启动器选项 |
| `/dashboard/app/launcher/show` | POST | 更新启动器 |
| `/dashboard/quick/option` | GET | 快捷跳转选项 |
| `/dashboard/quick/change` | POST | 更新快捷跳转 |
| `/dashboard/system/restart/:operation` | POST | 系统重启 |

---

**文档版本**: 2.0
**最后更新**: 2026-02-15
**数据来源**: docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json
