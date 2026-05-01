# Tasks
- [x] Task 1: API 载荷 (Payload) 与返回模型 (Response) 严谨性扫描与重构
  - [x] SubTask 1.1: 编写/更新 Python 脚本 (`check_payloads.py`) 针对 614 个 API，校验 Swagger 定义的具体 Schema 是否在 `lib/api/v2/*.dart` 返回了泛型 `Future<Response<T>>`。
  - [x] SubTask 1.2: 排查并修复所有的 `Future<Response>`、`Future<Response<dynamic>>` 误用，补齐缺失的 `Model.fromJson` 解析逻辑（如 Host、Container、Files、Dashboard 等）。
  - [x] SubTask 1.3: 确认所有 POST/PUT 请求体传入参数正确转换为 JSON，并且未混淆 `data` 和 `queryParameters`。
- [x] Task 2: 状态管理层与后端轮询逻辑深度检查
  - [x] SubTask 2.1: 检查各业务 `Repository` 层（如 DashboardRepository、FilesRepository、ContainersRepository）获取 API 返回数据的解包逻辑（`ApiResponseParser` 的提取过程）。
  - [x] SubTask 2.2: 拦截和优化底层异常：确保诸如“无配置”、“超时”、“网络拒绝连接”等边界情况在 UI 层能得到温和提示，而不是导致无限后台报错。
- [x] Task 3: 各核心模块可用性闭环校验
  - [x] SubTask 3.1: 验证应用商店、已安装应用（App）和容器配置模块（Containers）的 API 对接。
  - [x] SubTask 3.2: 验证系统设置、备份账户管理（Backup Account）模块的 API 对接。
  - [x] SubTask 3.3: 验证文件模块（File）的上传、下载、收藏等带特殊类型的端点。
  - [x] SubTask 3.4: 验证网络层日志 `appLogger.i/e/w` 输出格式正常。
- [x] Task 4: UI/原生侧交互验收
  - [x] SubTask 4.1: 在本地模拟器/macOS 客户端中跑通 `flutter run`，验证应用启动至大盘/设置等模块时不再抛出隐式异常。
  - [x] SubTask 4.2: 确认核心功能界面的刷新、操作绑定正确。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]