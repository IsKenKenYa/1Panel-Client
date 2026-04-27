# Tasks

说明：
- 本文件是 30 天执行主清单。
- 每日任务均需在当天结束前更新状态。
- 涉及 API 契约变化时，必须执行链路同步：API -> Repository/Service -> State -> UI -> Test -> Docs。

## Day 01 基线冻结与上下游边界确认
- [x] Task D01: 完成首日基线冻结
  - [x] SubTask D01.1: 拉取模块覆盖现状（check_module_client_coverage）
  - [x] SubTask D01.2: 拉取模块增删变更现状（check_module_api_updates）
  - [x] SubTask D01.3: 明确 docs/OpenSource/1Panel 只读边界
  - [x] SubTask D01.4: 记录当前 missing_in_client 模块名单
  - [x] SubTask D01.5: 记录当前 extra_in_client 模块名单
  - [x] SubTask D01.6: 对齐平台策略（Android/Linux MDUI3、Apple/Windows 原生）
  - [x] SubTask D01.7: 输出首日审计快照
  - [x] SubTask D01.8: 写入仓库记忆，固定阶段起点

## Day 02 阻断项清理与可执行环境恢复
- [ ] Task D02: 清理阻断门禁执行的问题
  - [ ] SubTask D02.1: 梳理 flutter analyze 当前错误清单
  - [ ] SubTask D02.2: 梳理 unit/integration/ui 当前错误清单
  - [ ] SubTask D02.3: 修复 command 相关历史编译问题
  - [ ] SubTask D02.4: 修复 monitoring 测试签名漂移问题
  - [ ] SubTask D02.5: 处理明显 dead code 与无效导入
  - [ ] SubTask D02.6: 验证 test_runner unit 可稳定执行
  - [ ] SubTask D02.7: 验证 test_runner ui 可稳定执行
  - [ ] SubTask D02.8: 输出阻断项闭环报告

## Day 03 API基线自动巡检脚本固化
- [ ] Task D03: 固化 API 巡检节奏
  - [ ] SubTask D03.1: 约定每日巡检命令模板
  - [ ] SubTask D03.2: 输出 all 模块 JSON 报告留档
  - [ ] SubTask D03.3: 约定 aligned 与 extra 的判定口径
  - [ ] SubTask D03.4: 约定 missing 的阻断处理口径
  - [ ] SubTask D03.5: 复核模块映射字典完整性
  - [ ] SubTask D03.6: 复核路径过滤规则是否误判
  - [ ] SubTask D03.7: 将巡检结论回写模块索引
  - [ ] SubTask D03.8: 沉淀巡检 FAQ

## Day 04 P0 应用模块缺口收口
- [x] Task D04: 补齐 app 缺口端点
  - [x] SubTask D04.1: 实现 GET /dashboard/app/launcher
  - [x] SubTask D04.2: 实现 POST /dashboard/app/launcher/option
  - [x] SubTask D04.3: 实现 POST /dashboard/app/launcher/show
  - [x] SubTask D04.4: 增加兼容解析逻辑
  - [x] SubTask D04.5: 增加 app_api_test 覆盖用例
  - [x] SubTask D04.6: 本地检查 app 模块覆盖状态
  - [x] SubTask D04.7: 确认 app 模块状态 aligned
  - [x] SubTask D04.8: 记录实现证据与结论

## Day 05 P0 备份模块缺口收口
- [x] Task D05: 消除 backup 误判并对齐覆盖
  - [x] SubTask D05.1: 复核 backup 客户端现有实现
  - [x] SubTask D05.2: 识别 /core/backups 路径被过滤问题
  - [x] SubTask D05.3: 修正覆盖脚本路径过滤规则
  - [x] SubTask D05.4: 重新执行 backup 覆盖检查
  - [x] SubTask D05.5: 确认 backup 模块状态 aligned
  - [x] SubTask D05.6: 回归 app 与 backup 双模块
  - [x] SubTask D05.7: 更新阶段说明文档
  - [x] SubTask D05.8: 回写阶段记忆

## Day 06 全量覆盖复核与快照更新
- [x] Task D06: 全量覆盖复核
  - [x] SubTask D06.1: 执行 --all 覆盖检查
  - [x] SubTask D06.2: 统计 aligned/extra/missing
  - [x] SubTask D06.3: 确认 missing_in_client 为 0
  - [x] SubTask D06.4: 输出最新覆盖快照
  - [x] SubTask D06.5: 标注 extra_in_client 的治理优先级
  - [x] SubTask D06.6: 记录本轮风险变化
  - [x] SubTask D06.7: 形成阶段进度摘要
  - [x] SubTask D06.8: 提交下一阶段执行入口

## Day 07 command 模块漂移深挖
- [ ] Task D07: 收口 command 与脚本库边界
  - [ ] SubTask D07.1: 盘点 command_v2 端点集合
  - [ ] SubTask D07.2: 盘点 script_library_v2 端点集合
  - [ ] SubTask D07.3: 标注混入端点来源与原因
  - [ ] SubTask D07.4: 调整覆盖脚本过滤逻辑（必要时）
  - [ ] SubTask D07.5: 补充 command 侧对齐测试
  - [ ] SubTask D07.6: 补充脚本库侧对齐测试
  - [ ] SubTask D07.7: 清理可去除的兼容路由
  - [ ] SubTask D07.8: 输出 command 边界决议

## Day 08 host 模块漂移与回退策略核对
- [ ] Task D08: 收口 host 路由迁移残留
  - [ ] SubTask D08.1: 复核 /hosts 与 /core/hosts 双路由行为
  - [ ] SubTask D08.2: 明确 fallback 保留条件
  - [ ] SubTask D08.3: 评估 fallback 退出窗口
  - [ ] SubTask D08.4: 增补 host API 对齐测试
  - [ ] SubTask D08.5: 增补 host provider 单测
  - [ ] SubTask D08.6: 复核 host 文档说明完整性
  - [ ] SubTask D08.7: 更新覆盖报告注释
  - [ ] SubTask D08.8: 输出 host 收口建议

## Day 09 database 与 setting 增强端点治理
- [ ] Task D09: extra_in_client 分类治理（第一批）
  - [ ] SubTask D09.1: database extra 端点分类（保留/清理）
  - [ ] SubTask D09.2: setting extra 端点分类（保留/清理）
  - [ ] SubTask D09.3: 写入兼容原因文档
  - [ ] SubTask D09.4: 清理无价值历史端点
  - [ ] SubTask D09.5: 补充对齐测试断言
  - [ ] SubTask D09.6: 回归 database 模块 API 用例
  - [ ] SubTask D09.7: 回归 setting 模块 API 用例
  - [ ] SubTask D09.8: 形成 extra 治理批次报告

## Day 10 ai 与 auth 增强端点治理
- [ ] Task D10: extra_in_client 分类治理（第二批）
  - [ ] SubTask D10.1: ai 白名单复核
  - [ ] SubTask D10.2: auth 非标准路由复核
  - [ ] SubTask D10.3: 确认浏览器/审批相关端点必要性
  - [ ] SubTask D10.4: 标注未来迁移计划
  - [ ] SubTask D10.5: 补齐 ai/auth 对齐测试
  - [ ] SubTask D10.6: 更新 API 映射文档
  - [ ] SubTask D10.7: 更新模块 FAQ
  - [ ] SubTask D10.8: 输出第二批治理结果

## Day 11 Week2 回归门禁与文档同步
- [ ] Task D11: 周中门禁检查
  - [ ] SubTask D11.1: 执行 flutter analyze
  - [ ] SubTask D11.2: 执行 unit 测试集
  - [ ] SubTask D11.3: 执行 ui 测试集
  - [ ] SubTask D11.4: 执行 integration 测试集（条件满足时）
  - [ ] SubTask D11.5: 输出门禁失败项清单
  - [ ] SubTask D11.6: 修复高优先失败项
  - [ ] SubTask D11.7: 更新 docs 模块索引
  - [ ] SubTask D11.8: 记录周中可发布状态

## Day 12 Windows 原生轨道架构设计冻结
- [ ] Task D12: Windows 原生建设方案冻结
  - [ ] SubTask D12.1: 明确首批模块范围（建议 Servers/Settings/Files）
  - [ ] SubTask D12.2: 明确导航与内容容器结构
  - [ ] SubTask D12.3: 明确 C# 与 Dart 桥接边界
  - [ ] SubTask D12.4: 明确不可跨层规则
  - [ ] SubTask D12.5: 明确状态同步策略
  - [ ] SubTask D12.6: 明确异常回退与降级策略
  - [ ] SubTask D12.7: 明确验收标准与截图要求
  - [ ] SubTask D12.8: 冻结方案并回写文档

## Day 13 Windows Shell 页面分发升级
- [ ] Task D13: 从占位内容升级为真实页面分发
  - [ ] SubTask D13.1: 创建模块页面容器基类
  - [ ] SubTask D13.2: 为 NavigationView 添加路由分发表
  - [ ] SubTask D13.3: 将 TextBlock 占位替换为页面对象
  - [ ] SubTask D13.4: 增加页面切换状态保持机制
  - [ ] SubTask D13.5: 增加空数据态组件
  - [ ] SubTask D13.6: 增加错误态组件
  - [ ] SubTask D13.7: 增加加载态组件
  - [ ] SubTask D13.8: 提交第一版可演示壳

## Day 14 Windows 与 Dart 桥接首批打通
- [ ] Task D14: 打通首批桥接调用
  - [ ] SubTask D14.1: 确认 onepanel/windows_bridge 能力清单
  - [ ] SubTask D14.2: 增加模块数据请求桥接命令
  - [ ] SubTask D14.3: 增加响应解析与错误映射
  - [ ] SubTask D14.4: 增加桥接超时保护
  - [ ] SubTask D14.5: 增加重试策略（仅幂等）
  - [ ] SubTask D14.6: 增加桥接日志脱敏输出
  - [ ] SubTask D14.7: 运行 windows_bridge_validation
  - [ ] SubTask D14.8: 输出桥接连通性报告

## Day 15 Windows 首批模块真实数据渲染
- [ ] Task D15: 页面从静态切换到动态数据
  - [ ] SubTask D15.1: Servers 页接入真实列表
  - [ ] SubTask D15.2: Settings 页接入真实配置摘要
  - [ ] SubTask D15.3: Files 页接入目录列表只读视图
  - [ ] SubTask D15.4: 增加分页/滚动性能防护
  - [ ] SubTask D15.5: 增加错误提示统一组件
  - [ ] SubTask D15.6: 增加无权限提示
  - [ ] SubTask D15.7: 增加页面刷新机制
  - [ ] SubTask D15.8: 完成首批模块演示验收

## Day 16 Windows 交互能力补齐（第一批）
- [ ] Task D16: 增加可操作能力
  - [ ] SubTask D16.1: Servers 页切换当前服务器
  - [ ] SubTask D16.2: Files 页基础导航（进入/返回）
  - [ ] SubTask D16.3: Settings 页基础切换（展示类）
  - [ ] SubTask D16.4: 增加操作确认弹窗
  - [ ] SubTask D16.5: 增加危险操作二次确认
  - [ ] SubTask D16.6: 增加 toast/tray 回退验证
  - [ ] SubTask D16.7: 增加失败可重试按钮
  - [ ] SubTask D16.8: 输出交互能力清单

## Day 17 Apple 轨道结构拆分设计
- [ ] Task D17: iOS 原生代码拆分方案冻结
  - [ ] SubTask D17.1: 拆分目标文件结构设计
  - [ ] SubTask D17.2: 抽离 ChannelManager
  - [ ] SubTask D17.3: 抽离模块 ViewModel
  - [ ] SubTask D17.4: 抽离公共组件层
  - [ ] SubTask D17.5: 约定状态流转范式
  - [ ] SubTask D17.6: 约定错误处理范式
  - [ ] SubTask D17.7: 约定命名与目录规范
  - [ ] SubTask D17.8: 输出拆分计划文档

## Day 18 iOS 拆分实施（第一批）
- [ ] Task D18: 拆分 AppDelegate 大文件
  - [ ] SubTask D18.1: 创建 Core 目录与 Channel 文件
  - [ ] SubTask D18.2: 创建 Modules 目录与 View 文件
  - [ ] SubTask D18.3: 创建 ViewModels 目录
  - [ ] SubTask D18.4: 迁移 servers/files 模块逻辑
  - [ ] SubTask D18.5: 迁移 monitoring/settings 模块逻辑
  - [ ] SubTask D18.6: 保持 render mode 切换可用
  - [ ] SubTask D18.7: 通过 iOS 本地编译
  - [ ] SubTask D18.8: 输出拆分前后对比

## Day 19 macOS 轨道语义对齐
- [ ] Task D19: macOS 与 iOS 语义一致性收敛
  - [ ] SubTask D19.1: 对齐导航层级命名
  - [ ] SubTask D19.2: 对齐错误提示策略
  - [ ] SubTask D19.3: 对齐加载态行为
  - [ ] SubTask D19.4: 对齐空态与无权限态
  - [ ] SubTask D19.5: 对齐操作确认策略
  - [ ] SubTask D19.6: 对齐国际化 key 使用
  - [ ] SubTask D19.7: 对齐平台差异记录
  - [ ] SubTask D19.8: 输出语义对齐清单 v1

## Day 20 双轨（Native vs MDUI3）模块对账
- [ ] Task D20: 模块级双轨对账
  - [ ] SubTask D20.1: Servers 双轨对账
  - [ ] SubTask D20.2: Files 双轨对账
  - [ ] SubTask D20.3: Containers 双轨对账
  - [ ] SubTask D20.4: Apps 双轨对账
  - [ ] SubTask D20.5: Websites 双轨对账
  - [ ] SubTask D20.6: Monitoring 双轨对账
  - [ ] SubTask D20.7: Settings 双轨对账
  - [ ] SubTask D20.8: 输出差异修复列表

## Day 21 Week3 质量门禁冲刺
- [ ] Task D21: 强化测试矩阵
  - [ ] SubTask D21.1: API 关键路径回归
  - [ ] SubTask D21.2: Provider 层关键路径回归
  - [ ] SubTask D21.3: Widget/UI 关键路径回归
  - [ ] SubTask D21.4: Windows 原生构建回归
  - [ ] SubTask D21.5: iOS 构建回归
  - [ ] SubTask D21.6: macOS 构建回归
  - [ ] SubTask D21.7: 问题分级与修复排期
  - [ ] SubTask D21.8: 输出 Week3 回归报告

## Day 22 CI 硬门禁方案实现（第一批）
- [ ] Task D22: 新增 CI 工作流骨架
  - [ ] SubTask D22.1: 新增 flutter analyze + unit 工作流
  - [ ] SubTask D22.2: 新增 UI 测试工作流
  - [ ] SubTask D22.3: 新增 integration 条件工作流
  - [ ] SubTask D22.4: 新增 Windows 原生构建工作流
  - [ ] SubTask D22.5: 新增 iOS 构建工作流
  - [ ] SubTask D22.6: 新增 macOS 构建工作流
  - [ ] SubTask D22.7: 配置失败即阻断策略
  - [ ] SubTask D22.8: 在 PR 中启用 required checks

## Day 23 CI 硬门禁方案实现（第二批）
- [ ] Task D23: 门禁稳定性增强
  - [ ] SubTask D23.1: 增加缓存策略提速
  - [ ] SubTask D23.2: 增加失败日志归档
  - [ ] SubTask D23.3: 增加 flaky 用例隔离策略
  - [ ] SubTask D23.4: 增加重试策略（仅网络类）
  - [ ] SubTask D23.5: 增加并发执行矩阵
  - [ ] SubTask D23.6: 增加门禁状态汇总输出
  - [ ] SubTask D23.7: 增加异常中断告警
  - [ ] SubTask D23.8: 输出 CI 运行手册

## Day 24 文档一致性门禁实现
- [ ] Task D24: 五文档同步守卫
  - [ ] SubTask D24.1: 定义触发条件（策略变更）
  - [ ] SubTask D24.2: 定义必同步文档集合
  - [ ] SubTask D24.3: 新增文档一致性检查脚本
  - [ ] SubTask D24.4: 将脚本接入 CI
  - [ ] SubTask D24.5: 增加本地 pre-commit 检查
  - [ ] SubTask D24.6: 增加失败提示与修复指引
  - [ ] SubTask D24.7: 运行一次全量演练
  - [ ] SubTask D24.8: 输出文档门禁验收报告

## Day 25 模块文档回写（第一批）
- [ ] Task D25: 更新 API 模块文档
  - [ ] SubTask D25.1: 更新 app_module_index
  - [ ] SubTask D25.2: 更新 backup_module_index
  - [ ] SubTask D25.3: 更新 command_module_index
  - [ ] SubTask D25.4: 更新 host_module_index
  - [ ] SubTask D25.5: 更新 module_planning_index
  - [ ] SubTask D25.6: 更新契约偏差章节
  - [ ] SubTask D25.7: 更新测试覆盖章节
  - [ ] SubTask D25.8: 输出文档变更摘要

## Day 26 模块文档回写（第二批）
- [ ] Task D26: 更新原生 UI 与治理文档
  - [ ] SubTask D26.1: 更新跨平台治理文档执行状态
  - [ ] SubTask D26.2: 更新模块工作流执行状态
  - [ ] SubTask D26.3: 更新原生工作流执行状态
  - [ ] SubTask D26.4: 更新 AGENTS 关键规则落地进展
  - [ ] SubTask D26.5: 更新 CLAUDE 流程细则落地进展
  - [ ] SubTask D26.6: 增加例外审批记录模板
  - [ ] SubTask D26.7: 增加平台矩阵现状表
  - [ ] SubTask D26.8: 输出治理同步记录

## Day 27 发布前全量回归（第一轮）
- [ ] Task D27: 执行全量回归
  - [ ] SubTask D27.1: 运行 API 全量核心用例
  - [ ] SubTask D27.2: 运行 Provider 核心用例
  - [ ] SubTask D27.3: 运行 Widget/UI 核心用例
  - [ ] SubTask D27.4: 运行 Windows 原生构建与验证
  - [ ] SubTask D27.5: 运行 iOS 构建
  - [ ] SubTask D27.6: 运行 macOS 构建
  - [ ] SubTask D27.7: 汇总失败项并修复
  - [ ] SubTask D27.8: 输出第一轮回归报告

## Day 28 发布前全量回归（第二轮）
- [ ] Task D28: 复验与稳定性确认
  - [ ] SubTask D28.1: 重跑所有失败修复用例
  - [ ] SubTask D28.2: 复验关键链路（登录/切服/文件/容器/应用）
  - [ ] SubTask D28.3: 复验双轨语义差异项
  - [ ] SubTask D28.4: 复验门禁脚本稳定性
  - [ ] SubTask D28.5: 复验 CI 并发场景
  - [ ] SubTask D28.6: 复验文档门禁策略
  - [ ] SubTask D28.7: 输出第二轮回归报告
  - [ ] SubTask D28.8: 形成发布候选结论

## Day 29 发布候选审查
- [ ] Task D29: 发布候选审批资料准备
  - [ ] SubTask D29.1: 准备代码变更摘要
  - [ ] SubTask D29.2: 准备测试与门禁结果
  - [ ] SubTask D29.3: 准备原生轨道能力说明
  - [ ] SubTask D29.4: 准备 API 覆盖变化说明
  - [ ] SubTask D29.5: 准备风险与回退预案
  - [ ] SubTask D29.6: 准备文档同步证明
  - [ ] SubTask D29.7: 完成发布评审会议纪要
  - [ ] SubTask D29.8: 形成可发布判定

## Day 30 收官与下一周期入口
- [ ] Task D30: 收官与复盘
  - [ ] SubTask D30.1: 输出 30 天总复盘
  - [ ] SubTask D30.2: 输出完成度统计（任务/缺陷/门禁）
  - [ ] SubTask D30.3: 输出未完成项清单
  - [ ] SubTask D30.4: 输出下一周期 P0/P1/P2 列表
  - [ ] SubTask D30.5: 输出可复用模板清单
  - [ ] SubTask D30.6: 更新仓库记忆长期结论
  - [ ] SubTask D30.7: 归档执行证据
  - [ ] SubTask D30.8: 创建下一周期 specs 入口

## 横向持续任务（每日必做）
- [ ] Daily A1: 当天开始前跑一次模块覆盖检查
- [ ] Daily A2: 当天结束前再跑一次模块覆盖检查
- [ ] Daily A3: 每天更新 tasks 与 checklist 勾选状态
- [ ] Daily A4: 每天输出 5 行内阶段摘要
- [ ] Daily A5: 每天记录新增风险与阻断项
- [ ] Daily A6: 每天记录文档同步是否触发
- [ ] Daily A7: 每天记录是否触发原生专项门禁
- [ ] Daily A8: 每天回写仓库记忆（关键决策与踩坑）

## 任务依赖
- D02 依赖 D01
- D03 依赖 D01
- D04 依赖 D01
- D05 依赖 D01
- D06 依赖 D04 与 D05
- D07 依赖 D06
- D08 依赖 D06
- D09 依赖 D06
- D10 依赖 D06
- D11 依赖 D07-D10
- D12 依赖 D11
- D13 依赖 D12
- D14 依赖 D13
- D15 依赖 D14
- D16 依赖 D15
- D17 依赖 D11
- D18 依赖 D17
- D19 依赖 D18
- D20 依赖 D16 与 D19
- D21 依赖 D20
- D22 依赖 D21
- D23 依赖 D22
- D24 依赖 D23
- D25 依赖 D21
- D26 依赖 D24
- D27 依赖 D25 与 D26
- D28 依赖 D27
- D29 依赖 D28
- D30 依赖 D29
