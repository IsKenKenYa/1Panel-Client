# 先找清楚影响范围

每次迁移都要先读这份说明。目标是列出“必须一起修改的代码”，避免只改组件声明，却漏掉调用方、数据类或存储读写。

## 1. 记录迁移目标

先记录：

- 输入是应用/工程、模块，还是独立代码片段；
- 用户要求整仓/整个应用迁移，还是只迁移指定组件；
- 工程根目录（通常包含顶层 `build-profile.json5` 和 `hvigorfile.*`）；
- 目标 SDK/API、兼容 SDK/API 和构建工具链版本；
- 模块及类型（`entry`、feature、HAR、HSP 等）；
- 仓库已有的构建和测试命令；
- 当前检出版本在迁移前能否构建通过。

仓库不等于整仓授权。如果用户只给了组件或文件且没有说清楚范围，先确认是完整迁移还是组件级迁移。

## 2. 生成代码清单

Node.js 20+ 可用时，在 Skill 目录运行：

```text
node scripts/inventory.mjs <project-root> --component <ComponentName>
```

整仓扫描时省略 `--component`；其他工具需要机器可读结果时加 `--format json`。扫描器会排除生成目录和下载的依赖树，并输出候选项及行号；仍要回到源码确认实际关系。

扫描器不能用时，对工程自有 `.ets` 和 `.ts` 文件使用 `rg`。至少搜索：

```text
@Component|@ComponentV2|@Entry|@Reusable|@ReusableV2
@State|@Prop|@Link|@ObjectLink|@Provide|@Consume|@StorageLink|@StorageProp|@LocalStorageLink|@LocalStorageProp|@Watch
@Local|@Param|@Event|@Provider|@Consumer|@ObservedV2|@Trace|@Monitor
makeV1Observed|enableV2Compatibility|makeObserved
AppStorage|LocalStorage|PersistentStorage|Environment
ForEach|LazyForEach|Repeat
```

搜索应用自有源码时排除 `.git`、`.hvigor`、`build`、`node_modules` 和 `oh_modules`。依赖清单和公开导出要单独检查。

## 3. 找到组件的所有关系

对每个目标组件，同时检查声明和所有创建位置：直接构造、builder、`@BuilderParam`、路由 builder、弹窗控制器、工厂和重新导出。对每个跨组件字段记录：

| 字段 | 类型 | 方向 | V1 行为 | 写入位置 | V2 契约 |
| --- | --- | --- | --- | --- | --- |
| 示例 | 简单值/类/内置对象/函数 | 父→子、子→父、双向 | 仅初始化、单向、双向、观察深度 | 被赋值或修改的位置 | `@Param`、`@Param @Once`、`@Event`、适配器 |

不能只看装饰器。允许外部初始化的 `@State` 与纯本地 `@State` 不同；会被子组件修改的 `@Prop` 与只读 `@Prop` 也不同。

沿字段类型追到声明处，并检查基类、嵌套可观察对象、数组/Map/Set/Date、工厂返回类型，以及初始化后替换整个对象的赋值位置。

## 4. 检查跨文件的共享状态

### Provider/Consumer

解析 alias 参数，必要时继续解析其中的常量。找出该 alias 的全部 provider 和 consumer，并确认它们在组件树中的祖先关系。V1 `@Provide`/`@Consume` 与 V2 `@Provider`/`@Consumer` 不能跨版本互通。优先一起迁移相连组件；否则，只有在能修改 consumer 及完整组件创建链时，才删除 `@Consume` 并改为逐层传值和回调。仍需保留 V1 `@Consume` 或无法修改完整链路时，必须保留 V1 `@Provide` 桥接所有者。

### Storage

编辑前按状态 key 梳理完整的读写和同步关系，包含装饰器和命令式 API。解析字符串字面量、常量、枚举值和简单别名；解析不了的表达式标记为动态 key，并追踪它的构造路径。AppStorage 与每个 LocalStorage 实例是不同的命名空间，不能合并处理。详细格式见 [storage-and-application-state.md](storage-and-application-state.md)。

### 渲染和复用

对每个待迁移循环，记录数据源、item key 函数、通知调用、template、拖拽排序、缓存配置、item 组件，以及旧 item 是否有 `@Reusable`。查找可复用组件的所有使用位置，不要只看声明。

### 高级组件和模块

记录系统预置/高级 UI 组件的 import，并检查当前公共 API 是否真的导出了 V2 版本。记录依赖来自工程源码、本地归档包还是下载包。不要编辑生成文件或包管理器维护的文件。

## 5. 给每项关系分类

- **必须修改的声明：** 目标组件，以及必须改变装饰器或属性观察机制的数据类。
- **必须修改的调用点：** 参数名、输出回调或构造方式发生变化的调用方。
- **必须一起迁移的集合：** 必须共同迁移的 Provider/Consumer alias 或 storage key 所有者。
- **边界适配器：** 有意留在范围外、但仍与 V2 代码相连的 V1 代码。
- **可选扩展：** 能简化结果但不是必须修改的其他自有模块/组件；若会明显扩大授权范围，先询问。
- **外部阻塞项：** 缺少源码、没有 V2 导出、目标 API 不兼容、工具链不可用，或与迁移无关的基线构建失败。

批量修改前写下这份分类。它既是执行清单，也是最终报告的依据，可以防止误删仍在使用的 V1 状态。
