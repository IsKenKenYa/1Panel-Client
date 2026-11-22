# 依赖图日志格式（log-format）

设备侧 DFX 生成的 `<bundle>_dependency_graph.txt` 日志格式，以及工具的模块名提取规则。

## 文件总体结构

```text
=== 可选的头部信息行（以 "=== " 开头，解析时跳过） ===
Total Nodes: 123              （可选统计行，跳过）

Node: <节点路径>
  File: <文件路径>
  Dependencies:
    [static] <依赖路径>
    [dynamic] <依赖路径> (specifier: <原始导入说明符>)
    -> <依赖路径>              （旧格式，按 static 处理）

（空行分隔节点，最后一个节点可无空行结尾）
```

- `Node:` 行为文件级节点起始，值为模块路径标识。
- `File:` 行为该节点对应的实际文件路径（可选）。
- `Dependencies:` 行之后直到空行均为该节点的依赖项。
- 超长行（最长 1MB）已被解析器兼容。

## 依赖行两种格式

| 格式 | 含义 | 可视化呈现 |
|------|------|-----------|
| `[static] <路径>` | 编译期确定的静态导入（普通 `import`） | 实线边 |
| `[dynamic] <路径> (specifier: <值>)` | 运行时动态加载（如 `import()`） | 虚线边，specifier 可溯源原始导入语句 |
| `-> <路径>` | 旧版日志格式，按 static 兜底 | 实线边 |

specifier 使用 `LastIndex("(specifier:")` 从行尾切出，依赖路径本身含括号不会误切。

## 路径前缀与模块名提取规则

文件级依赖聚合为模块级时，按下列规则提取模块名（取路径前两段，`@scope/name` 取到第二段）：

| 原始路径 | 提取的模块名 | 说明 |
|----------|--------------|------|
| `@ohos:taskpool` | `@ohos:taskpool` | 系统模块，原样保留 |
| `@normalized:N&&&@douyin/feed_aweme/src/main/ets/business/m11&1.0.0` | `@douyin/feed_aweme` | 去掉 `@normalized:N&&&` 前缀与 `&版本号` 后缀 |
| `@normalized:Y&&&libimageknifepro.so&` | `libimageknifepro.so` | `Y` 类为 native .so 依赖 |
| `@bundle:com.huawei.hms.mapservice.kit/mapLibrary/ets/utils/LogM` | `com.huawei.hms.mapservice.kit/mapLibrary` | 三方共享包 |
| `&@xxx/yyy/src/...` | `@xxx/yyy` | 无前缀的 & 包裹形式 |

## 设备侧落盘位置与采集条件

- 路径：`/data/app/el2/100/base/<bundle>/files/<bundle>_dependency_graph.txt`
- 仅**冷启动**后生成：设备需先配置 DFX 参数（`persist.ark.properties=0x400000105c`、`persist.ark.importDuration=<ms>`），再完全冷启动目标应用。
- 头部第二行 `Total nodes: N` 声明节点总数，modtree 拉取后据此与实际 `Node:` 行数校验完整性，防止读到写入中的半成品快照；采集结束后工具会自动恢复 DFX 参数原值（原先未设置则置 0 关闭）。
- `importDuration` 决定落盘前等待的模块加载时长：应用越大应设置越大，否则日志不完整。

## 完整示例

```text
=== Module Dependency Graph ===
Total Nodes: 3

Node: &entry/src/main/ets/modules/Foo&
  File: entry/src/main/ets/modules/Foo.ets
  Dependencies:
    [static] &entry/src/main/ets/modules/Bar&
    [dynamic] &entry/src/main/ets/modules/Baz& (specifier: @normalized:N&&&entry/src/main/ets/modules/Baz&)
    [static] @ohos:taskpool

Node: &entry/src/main/ets/modules/Bar&
  File: entry/src/main/ets/modules/Bar.ets
  Dependencies:
    -> @normalized:Y&&&libimageknifepro.so&
```
