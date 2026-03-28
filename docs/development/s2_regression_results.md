# S2-6 回归结果清单

更新日期: 2026-03-28  
适用分支: 模块适配-阶段2

## 1. 执行命令与结果

| 检查项 | 命令 | 结果 |
| --- | --- | --- |
| 静态分析 | flutter analyze | 通过（No issues found） |
| 单元回归 | dart run test_runner.dart unit | 通过 |
| UI 回归 | dart run test_runner.dart ui | 通过 |
| 集成回归 | dart run test_runner.dart integration | 通过（含预期 skip） |
| 全量基线回归 | dart run test_runner.dart all | 通过 |

## 2. 结果解读

- 本轮回归满足 S2-6 门禁要求。
- integration 中按环境变量控制的 skip 属预期行为，不构成阻塞。
- 回归结果与阶段文档、矩阵文档、覆盖文档保持一致。

## 3. 关联产物

- 模块完成清单: docs/development/s2_module_completion_list.md
- 风险残留清单: docs/development/s2_risk_residual_list.md
- 路由清理清单: docs/development/s2_route_cleanup_list.md
