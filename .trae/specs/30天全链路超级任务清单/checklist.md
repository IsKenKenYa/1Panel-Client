# 30天执行验收 Checklist

使用说明：
- 每周至少完整过一遍本清单。
- 任一阻断项为未完成时，不允许进入下一阶段。
- 每项验收都应附带可追溯证据（命令输出、截图、日志或文档链接）。

## A. 流程与边界验收
- [ ] A01 已确认 docs/OpenSource/1Panel 只读策略
- [ ] A02 已确认不适配 Web 的边界
- [ ] A03 已确认平台策略矩阵
- [ ] A04 已确认链路同步规则
- [ ] A05 已确认失败阻断规则
- [ ] A06 已确认文档同步门禁规则
- [ ] A07 已确认任务状态每日更新机制
- [ ] A08 已确认阶段复盘机制

## B. API 覆盖验收
- [ ] B01 每日两次运行覆盖检查
- [ ] B02 每周运行一次全量 JSON 覆盖快照
- [ ] B03 app 模块为 aligned
- [ ] B04 backup 模块为 aligned
- [ ] B05 command 模块已完成边界分类
- [ ] B06 host 模块已完成迁移残留分类
- [ ] B07 database 模块 extra 已分类
- [ ] B08 setting 模块 extra 已分类
- [ ] B09 ai 模块 extra 已分类
- [ ] B10 auth 模块 extra 已分类
- [ ] B11 missing_in_client 总数为 0
- [ ] B12 extra_in_client 全部有保留说明或清理计划
- [ ] B13 no_client_mapping 总数为 0
- [ ] B14 missing_client_file 总数为 0
- [ ] B15 覆盖报告已归档

## C. 契约偏差与兼容策略验收
- [ ] C01 已记录所有 method mismatch
- [ ] C02 已记录所有 required body mismatch
- [ ] C03 偏差已区分真实服务端行为与文档偏差
- [ ] C04 已补充对应 API 测试样例
- [ ] C05 已补充对应 provider/widget 回归用例
- [ ] C06 已在模块文档补充兼容策略
- [ ] C07 已在 FAQ 记录高频偏差
- [ ] C08 已建立偏差关闭标准

## D. 测试矩阵验收
- [ ] D01 flutter analyze 可通过
- [ ] D02 unit 测试可通过
- [x] D03 ui 测试可通过
- [ ] D04 integration 测试可执行（环境满足时）
- [ ] D05 失败用例有归因与修复计划
- [ ] D06 关键模块（app、backup、host、command）有回归用例
- [ ] D07 测试报告可追溯
- [ ] D08 回归门禁已纳入日常节奏

## E. Windows 原生轨道验收
- [ ] E01 WinUI3 壳可正常启动
- [ ] E02 NavigationView 路由分发表可用
- [ ] E03 内容区不再使用纯 Text 占位
- [ ] E04 首批模块页（Servers）可渲染真实数据
- [ ] E05 首批模块页（Settings）可渲染真实数据
- [ ] E06 首批模块页（Files）可渲染真实数据
- [ ] E07 错误态组件可用
- [ ] E08 空态组件可用
- [ ] E09 加载态组件可用
- [ ] E10 桥接调用超时保护可用
- [ ] E11 桥接调用日志脱敏可用
- [ ] E12 windows_bridge_validation 可通过
- [ ] E13 dotnet build Debug 可通过
- [ ] E14 关键交互（刷新/重试/确认）可用
- [ ] E15 原生层未出现直连 API 客户端

## F. Apple 原生轨道验收
- [ ] F01 iOS 大文件拆分方案已落地
- [ ] F02 Channel 层已独立
- [ ] F03 ViewModel 层已独立
- [ ] F04 模块 View 层已独立
- [ ] F05 render mode 切换仍可用
- [ ] F06 iOS 构建可通过（2026-04-27：Pods 已同步，但仍受 CoreSimulator/ibtool `Cannot allocate memory` 环境阻断）
- [x] F07 macOS 构建可通过
- [ ] F08 iOS 与 macOS 导航语义一致
- [ ] F09 iOS 与 macOS 错误反馈语义一致
- [ ] F10 iOS 与 macOS 加载空态语义一致
- [ ] F11 iOS 与 macOS 国际化来源一致
- [ ] F12 原生层未出现直连 API 客户端

## G. 双轨语义对齐验收
- [ ] G01 Servers: Native 与 MDUI3 入口语义一致
- [ ] G02 Servers: 主流程语义一致
- [ ] G03 Servers: 错误反馈语义一致
- [ ] G04 Files: Native 与 MDUI3 入口语义一致
- [ ] G05 Files: 主流程语义一致
- [ ] G06 Files: 错误反馈语义一致
- [ ] G07 Containers: Native 与 MDUI3 入口语义一致
- [ ] G08 Containers: 主流程语义一致
- [ ] G09 Containers: 错误反馈语义一致
- [ ] G10 Apps: Native 与 MDUI3 入口语义一致
- [ ] G11 Apps: 主流程语义一致
- [ ] G12 Apps: 错误反馈语义一致
- [ ] G13 Websites: Native 与 MDUI3 入口语义一致
- [ ] G14 Websites: 主流程语义一致
- [ ] G15 Websites: 错误反馈语义一致
- [ ] G16 Monitoring: Native 与 MDUI3 入口语义一致
- [ ] G17 Monitoring: 主流程语义一致
- [ ] G18 Monitoring: 错误反馈语义一致
- [ ] G19 Settings: Native 与 MDUI3 入口语义一致
- [ ] G20 Settings: 主流程语义一致
- [ ] G21 Settings: 错误反馈语义一致

## H. CI 硬门禁验收
- [ ] H01 flutter analyze 工作流已接入
- [ ] H02 unit 工作流已接入
- [ ] H03 ui 工作流已接入
- [ ] H04 integration 工作流已接入
- [ ] H05 Windows 原生构建工作流已接入
- [ ] H06 iOS 构建工作流已接入
- [ ] H07 macOS 构建工作流已接入
- [ ] H08 Required checks 已启用
- [ ] H09 门禁失败可阻断合并
- [ ] H10 门禁日志可追溯
- [ ] H11 门禁异常告警可追溯
- [ ] H12 工作流执行耗时可接受

## I. 文档同步门禁验收
- [ ] I01 AGENTS 已同步
- [ ] I02 CLAUDE 已同步
- [ ] I03 cross_platform_ui_governance 已同步
- [ ] I04 模块适配专属工作流 已同步
- [ ] I05 原生UI适配专属工作流 已同步
- [ ] I06 文档一致性脚本已接入 CI
- [ ] I07 本地 pre-commit 已启用（如适用）
- [ ] I08 文档门禁失败提示可读
- [ ] I09 文档变更记录可追溯
- [ ] I10 文档版本号与更新时间已更新

## J. 安全与日志验收
- [ ] J01 无硬编码密钥
- [ ] J02 无硬编码服务器地址
- [ ] J03 日志无敏感信息泄露
- [ ] J04 日志使用统一 appLogger
- [ ] J05 请求失败日志包含必要上下文
- [ ] J06 错误堆栈在错误级别可追踪
- [ ] J07 脱敏策略在关键路径生效
- [ ] J08 调试日志不影响发布行为

## K. 性能与稳定性验收
- [ ] K01 核心页面首屏加载可接受
- [ ] K02 列表滚动性能无明显卡顿
- [ ] K03 大数据列表渲染策略合理
- [ ] K04 重试策略不造成风暴请求
- [ ] K05 超时策略合理
- [ ] K06 异常后页面可恢复
- [ ] K07 无明显内存泄漏迹象
- [ ] K08 长链路操作有取消/超时机制

## L. 发布候选验收
- [ ] L01 代码变更摘要已准备
- [ ] L02 测试结果摘要已准备
- [ ] L03 门禁结果摘要已准备
- [ ] L04 平台矩阵结果已准备
- [ ] L05 风险清单已准备
- [ ] L06 回退预案已准备
- [ ] L07 文档同步证明已准备
- [ ] L08 评审结论已签署

## M. 每周里程碑验收
- [ ] M01 Week1: P0 API 缺口与误判收口完成
- [ ] M02 Week1: missing_in_client 归零
- [ ] M03 Week2: extra 分类治理完成第一轮
- [ ] M04 Week2: 阻断项测试问题显著下降
- [ ] M05 Week3: Windows 首批原生模块可演示
- [ ] M06 Week3: Apple 拆分第一轮落地
- [ ] M07 Week4: CI 硬门禁全部启用
- [ ] M08 Week4: 文档同步门禁启用
- [ ] M09 Week4: 双轨语义对齐清单完成
- [ ] M10 Week4: 发布候选评审完成

## N. 收官验收
- [ ] N01 30天复盘文档已完成
- [ ] N02 完成度统计已完成
- [ ] N03 未完成项清单已输出
- [ ] N04 下周期任务入口已建立
- [ ] N05 关键经验已写入仓库记忆
- [ ] N06 执行证据已归档
- [ ] N07 可复用模板已整理
- [ ] N08 项目状态已更新
