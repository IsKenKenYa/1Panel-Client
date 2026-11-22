# 代码上下文分析规则

## 适用场景

当开发者提供文件路径和组件信息时，Skill 使用本规则读取和分析开发者代码，为生成上下文感知的接入方案提供基础。

## 分析步骤

### 1. 读取文件

使用 Read 工具读取开发者提供的 .ets 文件路径。只读取明确提供的路径，不扫描工程目录。

- 文件不存在时：提示"文件路径 xxx 不存在，请提供有效的 .ets 文件路径"
- 文件不含 ArkUI 组件时：提示"文件中未找到 ArkUI 组件，请提供包含 @Component 或 @Entry 的文件"

### 2. 识别组件结构

分析文件中的以下要素：

| 要素 | 识别方式 | 用途 |
|------|---------|------|
| @Entry/@Component struct | 查找 `@Entry` 和 `@Component` 装饰器后的 `struct XXX` | 确定页面/组件名称 |
| build 方法 | 查找 `build()` 方法体内的组件树 | 理解 UI 结构 |
| 容器组件 | 识别 List/Grid/Column/Row/Stack/Navigation 等 | 确定可挂载命令式节点的位置 |
| 数据源 | 识别 ForEach/LazyForEach/IDataSource/Repeat | 理解数据驱动方式 |
| 已有命令式节点 | 查找 BuilderNode/FrameNode/RenderNode/NodeController/NodeContainer | 避免重复创建或冲突 |
| 状态管理 | 识别 @State/@Prop/@Link/@Reusable/@Provide/@Consume | 确定状态管理版本和约束 |

### 3. 确定接入位置

根据组件结构确定命令式节点的接入位置：

| 场景 | 接入位置 | 注意事项 |
|------|---------|---------|
| 列表中动态挂载 | ListItem 内添加 NodeContainer | 确保数据源与 NodeController 配合 |
| 页面中动态挂载 | build 方法内添加 NodeContainer | 确保 NodeController 生命周期管理 |
| 预创建组件 | aboutToAppear 或页面前置逻辑中创建 | 确保 dispose 在 aboutToDisappear 或页面销毁时调用 |
| 已有 FrameNode 树追加 | 在现有 FrameNode 的 appendChild 位置 | 确保不破坏现有树结构 |
| 已有 RenderNode 树追加 | 在现有 RenderNode 的 appendChild 位置 | 确保通过 FrameNode.getRenderNode 上树 |

### 4. 输出修改后的完整代码

根据分析结果，直接输出修改后的完整 .ets 代码，不只给骨架和指导：

1. **保留原始代码**：在开发者原有代码基础上修改，不破坏现有逻辑
2. **插入命令式节点**：在确定的位置插入 NodeContainer、NodeController、BuilderNode/FrameNode/RenderNode 创建和 dispose 逻辑
3. **替换组件名**：将模板中的占位组件名替换为开发者代码中的实际组件名
4. **生命周期管理**：在正确的生命周期回调中添加创建和 dispose 逻辑
5. **接入说明**：在代码修改处用注释标注"新增"和"修改"
6. **注意事项**：在代码后附上基于排障规则的关键提醒（如 @Reusable 冲突、双挂等）

## 规则依据

- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)：组件创建、挂载、dispose
- [FrameNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-frameNode.md)：节点树操作
- [RenderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-renderNode.md)：渲染节点挂载
- [节点 FAQ](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-node-faq.md)：生命周期和内存管理
