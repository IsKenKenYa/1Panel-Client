# BuilderNode JSON 序列化检查

## 检查条件

代码中对 BuilderNode / FrameNode / RenderNode 对象调用了 `JSON.stringify()`、`JSON.parse()` 或其他序列化接口（典型形式：`JSON.stringify(this.builderNode)`、`JSON.parse(JSON.stringify(builderNode))`）。凡存在命令式节点对象序列化操作的位置，都需检查。

## 检查步骤

1. **检查是否对命令式节点对象调用 JSON.stringify**：搜索 `JSON.stringify(`，检查入参是否为 BuilderNode / FrameNode / RenderNode 对象或其引用。BuilderNode 对象内部持有后端实体节点的引用关系（含循环引用），`JSON.stringify(builderNode)` 会因循环引用导致 JSCrash。
2. **检查是否存在间接序列化路径**：检查是否有将命令式节点对象存入 Map/Array 后整体序列化的代码（如 `JSON.stringify(this.nodeMap)`），同样会触发循环引用。

## 诊断与修复

### 发现问题时

- **诊断**：对 BuilderNode/FrameNode/RenderNode 对象调用 JSON.stringify 导致 JSCrash。
- **原因**：BuilderNode 内部持有后端实体节点的引用关系，且该引用关系含循环引用（BuilderNode → 后端节点 → BuilderNode）。`JSON.stringify` 在序列化过程中递归遍历对象图，遇到循环引用时无法终止，导致 JSCrash。这是平台约束，不是 bug。
- **修复方向**：只序列化业务数据参数对象（Params），不序列化 BuilderNode 对象本身。
- **输出约束（强制）**：本问题修复方向唯一且明确，**修改建议只限该唯一修复方向**（序列化目标改为业务数据 Params），**禁止追加 dispose、生命周期、内存释放等与本次问题无关的范围外修改建议**——即使原代码缺少 dispose 交互也不在本次修复范围内提及。输出形式遵循排障修复规则：给出**修复后的完整可运行代码**（只改问题点，其余代码与原样保持不变），**不得只给局部代码片段**。
- **修复代码模式**：
```typescript
// ❌ 错误：对 BuilderNode 对象调用 JSON.stringify
serializeNode(): string {
  return JSON.stringify(this.builderNode);  // JSCrash！循环引用
}

// ✅ 正确：只序列化业务数据参数
class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

serializeParams(): string {
  return JSON.stringify(this.params);  // 序列化 Params，安全
}
```

### 未发现问题时

未对命令式节点对象调用 JSON.stringify，或已改为序列化业务数据参数对象。不报告。

## 规则依据

- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：说明章节——"BuilderNode对象不支持使用JSON序列化"。
