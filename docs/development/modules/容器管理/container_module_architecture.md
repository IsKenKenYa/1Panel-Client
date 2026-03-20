# 容器管理模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的Docker容器管理能力
- 支持容器生命周期管理（创建、启动、停止、重启、删除）
- 提供镜像管理、网络管理、卷管理功能
- 支持容器日志查看、资源监控、终端访问
- 统一容器状态管理与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json 的 Container 相关标签共 50+ 个端点:

### 容器管理 (Container - 19个端点)
1. POST /containers - 创建容器
2. POST /containers/operate - 容器操作
3. POST /containers/search - 搜索容器
4. POST /containers/list - 容器列表
5. GET /containers/{id} - 容器详情
6. GET /containers/stats/{id} - 容器统计
7. GET /containers/list/stats - 容器列表统计
8. GET /containers/status - 容器状态统计
9. POST /containers/upgrade - 升级容器
10. POST /containers/rename - 重命名容器
11. POST /containers/commit - 提交容器为镜像
12. POST /containers/prune - 清理容器
13. POST /containers/clean/log - 清理日志
14. POST /containers/command - 通过命令创建容器
15. POST /containers/info - 获取容器信息
16. POST /containers/inspect - 检查容器
17. POST /containers/search/log - 搜索日志
18. POST /containers/update - 更新容器
19. GET /containers/download/log - 下载日志

### 镜像管理 (Container Image - 10个端点)
1. GET /containers/image - 获取镜像选项
2. GET /containers/image/all - 获取所有镜像
3. POST /containers/image/build - 构建镜像
4. POST /containers/image/load - 加载镜像
5. POST /containers/image/pull - 拉取镜像
6. POST /containers/image/push - 推送镜像
7. POST /containers/image/remove - 删除镜像
8. POST /containers/image/save - 保存镜像
9. POST /containers/image/search - 搜索镜像
10. POST /containers/image/tag - 标记镜像

### 网络管理 (Container Network - 4个端点)
1. GET /containers/network - 获取网络选项
2. POST /containers/network - 创建网络
3. POST /containers/network/del - 删除网络
4. POST /containers/network/search - 搜索网络

### 卷管理 (Container Volume - 4个端点)
1. GET /containers/volume - 获取卷选项
2. POST /containers/volume - 创建卷
3. POST /containers/volume/del - 删除卷
4. POST /containers/volume/search - 搜索卷

### Docker管理 (Container Docker - 8个端点)
1. GET /containers/docker/status - Docker状态
2. POST /containers/docker/operate - Docker操作
3. 其他Docker守护进程管理端点

### Compose管理 (Container Compose - 5个端点)
1. POST /containers/compose - 创建Compose
2. POST /containers/compose/search - 搜索Compose
3. POST /containers/compose/operate - Compose操作
4. POST /containers/compose/update - 更新Compose
5. POST /containers/compose/del - 删除Compose

## 业务流程与交互验证

### 容器列表浏览流程
- 进入容器管理页面
- 显示容器列表（名称、状态、镜像、资源使用）
- 支持按状态筛选（运行中/已停止/全部）
- 支持搜索容器名称
- 下拉刷新获取最新状态

### 容器详情查看流程
- 点击容器进入详情页
- 显示容器基本信息
- 显示资源使用图表
- 显示网络配置
- 显示挂载卷信息
- 显示环境变量

### 容器操作流程
- 长按容器显示操作菜单
- 选择操作（启动/停止/重启/删除）
- 确认操作
- 显示操作进度
- 操作完成后更新状态

### 镜像管理流程
- 进入镜像管理页面
- 显示本地镜像列表
- 支持拉取新镜像
- 支持删除无用镜像
- 支持镜像搜索

### 网络管理流程
- 进入网络管理页面
- 显示Docker网络列表
- 支持创建新网络
- 支持删除自定义网络

### 卷管理流程
- 进入卷管理页面
- 显示Docker卷列表
- 支持创建新卷
- 支持删除未使用的卷

## 关键边界与异常

### 容器操作异常
- 容器启动失败的诊断提示
- 容器停止超时的处理
- 容器删除时的依赖检查
- 资源不足的操作限制

### 镜像操作异常
- 镜像拉取失败的诊断
- 镜像删除时的容器依赖检查
- 镜像仓库连接失败的处理
- 磁盘空间不足的提示

### 网络与卷异常
- 网络删除时的容器依赖检查
- 卷删除时的容器依赖检查
- 网络配置错误的提示

### Docker守护进程异常
- Docker服务未运行的提示
- Docker版本兼容性检查
- 权限不足的提示

## 模块分层与职责

### 前端
- UI页面: 容器列表、容器详情、镜像管理、网络管理、卷管理、日志查看
- 状态管理: 容器列表缓存、操作状态、资源监控数据

### 服务层
- API适配: ContainerV2Api, DockerV2Api
- 数据模型: Container、ContainerStats、Image、Network、Volume等

## 数据流

1. UI触发 -> Provider/Service -> API客户端请求
2. API响应解析 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 实时监控 -> WebSocket/轮询 -> 数据更新

## 与现有实现的差距

- 容器详情页面不完整
- 镜像管理页面缺失
- 网络管理页面缺失
- 卷管理页面缺失
- 容器日志查看功能缺失
- 容器终端功能缺失
- 资源监控图表缺失

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |
