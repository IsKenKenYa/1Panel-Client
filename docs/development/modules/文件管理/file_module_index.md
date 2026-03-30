# 文件管理模块索引

## 模块定位
Open1PanelApp 的文件管理模块负责服务器文件系统的浏览、操作、权限管理与回收站功能，提供移动端友好的文件管理体验。

## S2-0 基线（2026-03-26）

- 当前状态：
  文件功能覆盖较强，但 `FilesProvider` 仍是超大状态对象，且回收站等子流存在越层调用，不能以“架构改造完成”判定阶段 2 已完成。
- 阶段 2 hard scope：
  `browser / recycle / transfer / preview` 分层收口
- API 基线：
  `check_module_api_updates.py file` 当前结果为 `unchanged`

## 架构改造完成状态

### ✅ 已完成
| 组件 | 文件路径 | 状态 |
|------|----------|------|
| API客户端 | lib/api/v2/file_v2.dart | ✅ 完成 (40+ API方法) |
| 数据模型 | lib/data/models/file_models.dart | ✅ 完成 (50+ 模型类) |
| 服务层 | lib/features/files/files_service.dart | ✅ 完成 |
| 状态管理 | lib/features/files/files_provider.dart | ✅ 完成 |
| UI页面 | lib/features/files/files_page.dart | ✅ 完成 |
| 文件预览 | lib/features/files/preview/ | ✅ 完成 |
| 文件编辑器 | lib/features/files/editor/ | ✅ 完成 |
| 回收站管理 | lib/features/files/recycle_bin/ | ✅ 完成 |
| 收藏夹功能 | lib/features/files/favorites/ | ✅ 完成 |
| 权限管理 | lib/features/files/permission/ | ✅ 完成 |
| 文件下载 | lib/features/files/download/ | ✅ 完成 |
| wget远程下载 | lib/features/files/wget/ | ✅ 完成 |
| 缓存管理 | lib/core/services/cache/ | ✅ 完成 |
| API测试 | test/api_client/file_api_test.dart | ✅ 完成 |

### 📋 待优化
- 文件分享功能
- 大文件分块传输优化

## 子模块结构
- 架构设计: docs/development/modules/文件管理/file_module_architecture.md
- 开发计划: docs/development/modules/文件管理/file_plan.md
- FAQ: docs/development/modules/文件管理/file_faq.md

## 功能覆盖

### 文件操作
- [x] 文件列表浏览
- [x] 目录导航（面包屑）
- [x] 创建文件夹
- [x] 创建文件
- [x] 重命名
- [x] 复制
- [x] 移动
- [x] 删除
- [x] 压缩
- [x] 解压
- [x] 搜索
- [x] 排序
- [x] 多选操作

### 文件预览
- [x] 文本文件预览
- [x] 图片预览（支持缩放、手势操作）
- [x] 代码高亮预览（支持多种语言）
- [x] 文件编码自动检测
- [x] PDF预览
- [x] 视频预览
- [x] 音频预览
- [x] Markdown预览
- [x] SVG预览

### 文件编辑器
- [x] 文本文件编辑
- [x] 文件保存
- [x] 编码选择与转换
- [x] 语法高亮显示
- [x] 行号显示

### 文件下载
- [x] 下载文件到本地
- [x] 下载进度显示
- [x] 支持分块下载大文件
- [x] 权限引导

### 文件缓存
- [x] 内存缓存（2分钟过期）
- [x] 硬盘缓存（支持离线）
- [x] 混合缓存模式
- [x] 缓存策略设置
- [x] 缓存大小限制
- [x] 主动清除缓存
- [x] 文件哈希验证

### 权限管理
- [x] 查看文件权限
- [x] chmod 权限修改
- [x] chown 所有者修改
- [x] 批量权限修改
- [x] 递归权限修改

### 回收站管理
- [x] 查看回收站文件列表
- [x] 恢复已删除文件
- [x] 彻底删除文件
- [x] 清空回收站

### 收藏夹功能
- [x] 收藏常用文件/文件夹
- [x] 取消收藏
- [x] 收藏列表浏览
- [x] 快速访问收藏项

### wget 远程下载
- [x] 从 URL 下载文件到服务器
- [x] 下载进度显示
- [x] 下载状态管理

### API端点覆盖
| 端点 | 功能 | 状态 |
|------|------|------|
| POST /files/search | 搜索文件 | ✅ |
| POST /files/check | 检查文件 | ✅ |
| POST /files/batch/check | 批量检查文件 | ✅ |
| POST /files/tree | 获取文件树 | ✅ |
| POST /files/size | 获取文件大小 | ✅ |
| POST /files/depth/size | 多文件大小 | ✅ |
| GET /files/recycle/status | 回收站状态 | ✅ |
| POST /files | 创建文件/目录 | ✅ |
| POST /files/del | 删除文件 | ✅ |
| POST /files/batch/del | 批量删除 | ✅ |
| POST /files/rename | 重命名 | ✅ |
| POST /files/move | 移动文件 | ✅ |
| POST /files/compress | 压缩文件 | ✅ |
| POST /files/decompress | 解压文件 | ✅ |
| POST /files/content | 获取文件内容 | ✅ |
| POST /files/save | 保存文件内容 | ✅ |
| POST /files/upload | 上传文件 | ✅ |
| GET /files/download | 下载文件 | ✅ |
| POST /files/chunkupload | 分块上传 | ✅ |
| POST /files/chunkdownload | 分块下载 | ✅ |
| POST /files/wget | wget远程下载 | ✅ |
| POST /files/mode | 修改文件模式 | ✅ |
| POST /files/owner | 修改所有者 | ✅ |
| POST /files/batch/role | 批量修改角色 | ✅ |
| POST /files/favorite | 收藏文件 | ✅ |
| POST /files/favorite/del | 取消收藏 | ✅ |
| POST /files/favorite/search | 搜索收藏 | ✅ |
| POST /files/recycle/clear | 清空回收站 | ✅ |
| POST /files/recycle/reduce | 减少回收站 | ✅ |
| POST /files/recycle/search | 搜索回收站 | ✅ |
| POST /files/convert | 转换文件编码 | ✅ |
| POST /files/convert/log | 转换日志 | ✅ |
| POST /files/remarks | 批量获取文件备注 | ✅ |
| POST /files/remark | 设置文件备注 | ✅ |
| POST /files/preview | 预览文件 | ✅ |
| POST /files/read | 读取文件 | ✅ |
| POST /files/user/group | 获取用户组 | ✅ |
| POST /files/mount | 获取挂载信息 | ✅ |
| POST /files/encoding/convert | 编码转换 | ✅ |
| POST /files/search/in | 内容搜索 | ✅ |
| POST /files/properties | 文件属性 | ✅ |
| POST /files/link/create | 创建链接 | ✅ |
| POST /files/upload/search | 上传历史 | ✅ |

## 后续规划
- 文件分享功能实现
- 大文件分块传输性能优化
- 文件搜索性能优化
