# ArkUI-X 桥接生成报告

## 执行摘要

- 输入 ScanReport：{{scanReportPath}}
- 桥接接口数：{{total}}（③equivalent_bridge：{{equivalentCount}} / ④degraded_bridge：{{degradedCount}}）
- ②Local 迁移：成功 {{localMigrated}} / 失败 {{localFailed}}
- 签名类型不匹配（需人工）：{{mismatchCount}} 项
- 等价映射未收录（unmapped，需人工确认）：{{unmappedCount}} 项

## 五件套清单

{{artifactTable}}

## 签名类型不匹配项（①Interface 真相源派生）

{{mismatchList}}

## 等价映射待确认项

{{unmappedList}}

## ②Local 读取失败明细

{{localFailureList}}

## 产物自检（兜底——残缺项需补全）

- 自检 {{auditChecked}} 件：硬残缺 {{auditDeficientCount}} 件（必补——读取 action 指向文件与源工程 locations 补全，重跑幂等不覆盖手改）；建议级见下
{{auditList}}

### 建议级（可选增强——contract-thin 单方法兜底契约）

{{auditSuggestionList}}

## 增量再生成说明

- ①Interface/③ArkUIX/④⑤BridgePlugin 骨架区已幂等更新；④⑤围栏内（ARKUIX-BRIDGE-HANDOFF）手改区保留。
- ②Local 文件已存在时保留开发者版本不覆盖；如需重新迁移请先删除对应文件。
{{keptNote}}

## 头文件依赖跳过清单（G4，不生成桥接件）

{{skippedIncludes}}

## 接线指引（N4——生成 ≠ 接通，按此三步接入）

{{wiringGuide}}
