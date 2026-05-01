# Tasks
- [x] Task 1: 编写 UI 层扫描脚本与初步修复策略
  - [x] SubTask 1.1: 编写 Python 脚本扫描 `lib/features/*/views/` 下的页面构建函数（如 `build`、`ListView.builder`），排查直接对 `null` 值使用强解包（`!`）、或在异步上下文中未判断 `mounted` 就调用 `setState` / `context` 的情况。
  - [x] SubTask 1.2: 对上述发现的低级错误（如果有的话）进行批量替换和优化。
- [x] Task 2: 深入重构与检查大盘（Dashboard）和主机（Host）模块
  - [x] SubTask 2.1: 检查 Dashboard 数据实时展示页面（CPU/Mem/Net 图表、进程列表）的绑定，修复任何因 API 修改而产生的数据脱节。
  - [x] SubTask 2.2: 检查 Host 模块的工具配置展示、组件状态反馈页面，确保无渲染异常。
- [x] Task 3: 深入重构应用（App）与容器（Container）模块
  - [x] SubTask 3.1: 确保已安装应用列表、应用商店搜索及详情页，能正确显示图标、状态及安装按钮。
  - [x] SubTask 3.2: 确保容器的列表展示、日志查看、操作（启动/停止/重启）弹窗均能平滑运行，并且操作后列表能正确刷新。
- [x] Task 4: 深入重构文件（Files）、网站（Websites）、数据库（Databases）等模块
  - [x] SubTask 4.1: 确保文件列表解析（夹杂权限/大小/修改时间等元数据）展示正常，并测试下拉刷新及基础操作框。
  - [x] SubTask 4.2: 确保网站（CA、代理、静态资源）配置和数据库（PostgreSQL 等）信息的获取能够在详情卡片或列表中稳定展现。
- [x] Task 5: 最终链路闭环验证
  - [x] SubTask 5.1: 启动应用至模拟器或 macOS 桌面端，模拟一个空白服务器配置，确保出现正确的未登录引导；模拟一个无效连接，确保各页面友好提示。
  - [x] SubTask 5.2: 清理根目录下可能遗留的临时产物（如 `issues.txt` 等临时日志）。

# Task Dependencies
- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 3]
- [Task 5] depends on [Task 4]