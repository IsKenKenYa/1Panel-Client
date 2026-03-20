# 容器编排模块架构设计

## 模块目标

- 适配 Open1PanelApp 作为 1Panel Linux 运维面板社区版的定位
- 提供完整的Docker编排能力
- 支持Compose项目管理和模板
- 提供网络、卷、镜像仓库管理
- 统一编排管理与错误反馈

## 功能完整性清单

基于 docs/OpenSource/1Panel/core/cmd/server/docs/swagger.json，容器编排模块共包含 33 个端点:

### Docker管理 (8端点)
1. GET /docker/info - 获取Docker信息
2. GET /docker/version - 获取Docker版本
3. POST /docker/config - 更新Docker配置
4. POST /docker/restart - 重启Docker服务
5. GET /docker/logs - 获取Docker日志
6. GET /docker/status - 获取Docker状态
7. POST /docker/prune - 清理无用资源
8. GET /docker/stats - 获取资源统计

### Compose编排 (11端点)
1. GET /compose/projects - 获取Compose项目列表
2. POST /compose/project - 创建Compose项目
3. POST /compose/project/update - 更新Compose项目
4. POST /compose/project/del - 删除Compose项目
5. POST /compose/project/up - 启动Compose项目
6. POST /compose/project/down - 停止Compose项目
7. GET /compose/project/{id} - 获取项目详情
8. GET /compose/templates - 获取Compose模板列表
9. POST /compose/template - 创建Compose模板
10. POST /compose/template/update - 更新Compose模板
11. POST /compose/template/del - 删除Compose模板

### 网络管理 (4端点)
1. GET /containers/networks - 获取网络列表
2. POST /containers/network - 创建网络
3. POST /containers/network/update - 更新网络
4. POST /containers/network/del - 删除网络

### 卷管理 (4端点)
1. GET /containers/volumes - 获取卷列表
2. POST /containers/volume - 创建卷
3. POST /containers/volume/update - 更新卷
4. POST /containers/volume/del - 删除卷

### 镜像仓库 (6端点)
1. GET /docker/registries - 获取镜像仓库列表
2. POST /docker/registry - 添加镜像仓库
3. POST /docker/registry/update - 更新镜像仓库
4. POST /docker/registry/del - 删除镜像仓库
5. POST /docker/registry/login - 登录镜像仓库
6. POST /docker/registry/logout - 登出镜像仓库

## 业务流程与交互验证

### Compose项目部署流程
- 进入Compose管理页面
- 选择或创建Compose模板
- 配置项目参数
- 部署项目
- 监控项目状态

### 网络创建流程
- 进入网络管理页面
- 点击"创建网络"
- 配置网络参数
- 选择网络驱动
- 创建网络

### 卷管理流程
- 进入卷管理页面
- 创建数据卷
- 配置卷参数
- 关联到容器

## 关键边界与异常

### Compose操作异常
- Compose文件格式错误
- 项目启动失败
- 资源不足

### 网络操作异常
- 网络名称冲突
- 网络驱动不支持
- 网络被容器使用

### 卷操作异常
- 卷名称冲突
- 卷被容器使用
- 存储空间不足

## 模块分层与职责

### 前端
- UI页面: Compose项目、模板、网络、卷、仓库管理
- 状态管理: 项目列表、网络列表、卷列表

### 服务层
- API适配: DockerV2Api, ContainerComposeV2Api, ContainerV2Api
- 数据模型: ComposeProject, Network, Volume, Registry等

## 数据流

1. 用户操作 -> 参数验证 -> API请求
2. API响应 -> 模型映射 -> 状态更新
3. 状态更新 -> UI刷新 -> 用户反馈
4. 资源变更 -> 状态轮询 -> 列表更新

## 与现有实现的差距

- Compose项目管理页面缺失
- 网络管理页面缺失
- 卷管理页面缺失
- 镜像仓库管理页面缺失

## 评审记录

| 日期 | 评审人 | 结论 | 备注 |
| --- | --- | --- | --- |
| 待定 | 评审人A | 待评审 | |
| 待定 | 评审人B | 待评审 | |

---

**文档版本**: 1.0
**最后更新**: 2026-02-14
