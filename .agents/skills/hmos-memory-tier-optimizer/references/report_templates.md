# 报告模板

## UI 树分析报告模板

分析完成后，生成以下格式的报告并保存到 `{dataDir}/uiTree/ui_tree_analysis_report.md`：

```markdown
# UI 组件树分析报告

## 基本信息
| 项目 | 值 |
|------|-----|
| 应用 | {bundleName} |
| Ability | {abilityName} |
| 页面 | {pagePath} |
| 设备分辨率 | {width} x {height} px |

## 页面整体结构
（树形缩进展示关键组件层级）

## 滚动容器组件分析
### List 组件
| 属性 | 值 |
|------|-----|
| 类型 | List/Grid/WaterFlow |
| bounds | [x1,y1] -> [x2,y2] |
| scrollable | true |
| 代码位置 | {file}:{line} |

### ListItem 详情
| 索引 | ID | 联系人 | 时间 | 未读 | bounds | 完全可见 |
（表格列出所有 ListItem）

### Item 内部结构
（展示典型 ListItem 的组件树）

### Item 复杂度评估
| 维度 | 评估 |
（评估结果表格）

## 发现的问题
（按严重级别列出问题）

## 图片资源分析
### Image 组件统计
| 维度 | 值 |
|------|-----|
| Image 组件总数 | {count} |
| 大图组件数（> 屏幕 25%） | {large_count} |
| 未使用 autoResize | {no_autoresize_count} |
| 网络图片 | {network_count} |
| 本地图片 | {local_count} |

### Image 详情
| 索引 | bounds | 面积占比 | autoResize | source 类型 | 所在 ListItem |
（表格列出所有 Image 组件）

### 资源文件分析
| 文件路径 | 大小 | 格式 | 建议 |
（列出 resources 目录下 > 100KB 的图片文件）

## Web 预加载分析
### Web 组件统计
| 维度 | 值 |
|------|-----|
| Web 组件数量 | {count} |
| 全屏 Web 数 | {fullscreen_count} |
| 预加载级别 | {preload_level} |
| 预启动渲染进程 | {prestarted_process} |
| onActive 调用 | {on_active_status} |
| onInactive 调用 | {on_inactive_status} |
| FMP 停止渲染 | {fmp_inactive_status} |
| 离线 Web 组件数 | {offline_web_count} |
| 离线组件复用策略 | {offline_reuse_status} |
| 离线组件释放策略 | {offline_recycle_status} |
| 内存贡献(估) | {memory_cost} |
| 代码位置 | {code_location} |

### Web 预加载/离线组件调用检测
| API 调用 | 文件 | 行号 |
|----------|------|------|
| prepareForPageLoad | {file}:{line} |
| prefetchPage | {file}:{line} |
| prefetchResource | {file}:{line} |
| initializeWebEngine | {file}:{line} |
| createNWeb('about:blank') | {file}:{line} |
| 预渲染(Nodepool) | {file}:{line} |
| onActive | {file}:{line} |
| onFirstMeaningfulPaint | {file}:{line} |
| onInactive | {file}:{line} |
| precompileJavaScript | {file}:{line} |
| NodeContainer | {file}:{line} |
| NodeController | {file}:{line} |
| BuilderNode | {file}:{line} |
| createNWeb/getNWeb | {file}:{line} |
| recycleNWeb/recycleNWebs | {file}:{line} |
| loadUrl('about:blank') | {file}:{line} |
| dispose/rebuild/delete | {file}:{line} |
| onBind/onUnbind/isBound | {file}:{line} |

## 资源泄漏分析
### 代码扫描结果
| 泄漏类型 | 文件 | 代码行 | 详情 |
|----------|------|--------|------|
| Timer 未清理 | {file}:{line} | setInterval 无 clearInterval |
| FD 未关闭 | {file}:{line} | open 无 close |
| Worker 未终止 | {file}:{line} | new ThreadWorker 无 terminate |

### 内存增长趋势（如有多次采样）
| 采样时间 | PSS Total | native heap | ark ts heap | 趋势 |
（表格列出多次采样数据，标注增长趋势）

## 内存优化机会点
### 可用优化方案 1：cacheCount 动态分档
（基于 Item 复杂度和 cachedCount 分析）

### 可用优化方案 2：图片资源内存优化
（基于 Image 组件数量、大图比例和 native heap 占比分析）

### 可用优化方案 3：资源泄漏修复
（基于代码扫描结果和 meminfo 趋势分析）

### 可用优化方案 4：Web 预加载分档优化
（基于 Web 组件数量、预加载策略和设备内存分析）

### 可用优化方案 5：Web 预渲染活跃状态优化
（基于 onActive、onFirstMeaningfulPaint、onInactive 配对关系分析）

### 可用优化方案 6：Web 离线组件分档复用与释放优化
（基于离线 Web 组件数量、复用策略、释放链路和设备分档分析）

### 待完善的优化方向
（列出暂无方案的问题）

## 组件统计
（各组件类型数量统计）
```

## 内存分析报告模板

```markdown
# 内存分析报告

## 基本信息
- 应用: com.ohos.mms
- Ability: MainAbility
- PID: 9428
- 页面文件: src/main/ets/pages/Index.ets

## 内存概览
| 类型 | PSS | 占比 | 状态 |
|------|-----|------|------|
| native heap | 65MB | 54.8% | ⚠️ 过高 |
| ark ts heap | 26MB | 22.2% | ✅ 正常 |
| .so | 20MB | 16.7% | ✅ 正常 |

## 定位文件
| 文件 | 相关组件 | 内存关联 |
|------|----------|----------|
| Index.ets | List, ListItem | 滚动列表 |
| ConversationList.ets | List | 会话列表 |
| MessageItem.ets | ListItem | 消息项 |

## 问题分析
1. native heap 占用过高 (54.8%)
   - 可能原因: 图片资源未释放
   - 相关文件: MessageItem.ets

2. List 组件未设置 cacheCount
   - 文件: ConversationList.ets
   - 建议: 添加动态 cacheCount 配置

3. 图片资源分析（如检测到 Image 占比过高）
   - Image 组件数量: {count}
   - 大图组件: {large_count} 个
   - 未使用 autoResize: {no_autoresize_count} 个
   - 建议: 图片资源内存优化方案

4. 资源泄漏分析（如检测到泄漏）
   - Timer 泄漏: {file}:{line}
   - FD 泄漏: {file}:{line}
   - 建议: 资源泄漏修复方案

5. Web 预加载分析（如检测到 Web 组件）
   - Web 组件数量: {web_count}
   - 预加载策略: {current_strategy}
   - onActive 调用: {on_active_status}
   - FMP 停止渲染: {fmp_inactive_status}
   - 离线 Web 组件数: {offline_web_count}
   - 复用/释放策略: {offline_reuse_status} / {offline_recycle_status}
   - PSS 贡献: {pss_contribution}
   - 建议: Web 预加载分档优化方案；如存在预渲染活跃状态未配对，补充 Web 预渲染活跃状态优化方案；如离线 Web 组件过量或未释放，补充 Web 离线组件分档复用与释放优化方案

## 优化建议
[基于内置方案库生成具体建议]
```
