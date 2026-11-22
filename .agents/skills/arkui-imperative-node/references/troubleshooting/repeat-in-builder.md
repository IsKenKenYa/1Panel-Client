# @Builder 内 Repeat 检查

## 检查条件

代码中 BuilderNode 的 `@Builder` 函数体内直接使用了 `Repeat` 组件（即 `@Builder` 函数体内出现了 `Repeat(...)` 调用，且不在任何 `@Component`/`@ComponentV2` 自定义组件的 `build()` 内）。凡 BuilderNode 的 @Builder 中使用 Repeat 的位置，都需检查是否直接使用。

## 检查步骤

1. **检查 @Builder 函数体内是否直接使用 Repeat**：扫描 `@Builder` 装饰的函数体，检查是否有 `Repeat(...)` 调用。Repeat 仅支持在自定义组件（`@Component`/`@ComponentV2`）中使用，`@Builder` 函数体内不能直接使用，否则运行时 crash。
2. **检查 Repeat 是否在 @Component 内**：若 Repeat 出现在 `@Builder` 内，检查是否已被自定义组件包裹。正确做法是：将 Repeat 放在 `@Component` 自定义组件的 `build()` 内，再在 `@Builder` 中使用该自定义组件。

## 诊断与修复

### 发现问题时

- **诊断**：@Builder 函数体内直接使用了 Repeat 组件，运行时 crash。
- **原因**：BuilderNode 仅支持在自定义组件（`@Component`/`@ComponentV2`）中使用 Repeat 组件。`@Builder` 是全局无状态 UI 方法，不是自定义组件，框架无法在其内部管理 Repeat 的懒加载和节点复用。
- **修复方向**：将 Repeat 移入 `@Component` 自定义组件内部，再在 `@Builder` 中使用该自定义组件。
- **输出约束（强制）**：本问题修复方向唯一且明确，**修改建议只限该唯一修复方向**（Repeat 移入 @Component + @Builder 引用该组件），**禁止追加 dispose、生命周期、内存释放等与本次问题无关的范围外修改建议**——即使原代码缺少 dispose 交互也不在本次修复范围内提及。输出形式遵循排障修复规则：给出**修复后的完整可运行代码**（只改问题点，其余代码与原样保持不变），**不得只给局部代码片段**。
- **修复代码模式**：
```typescript
// ❌ 错误：@Builder 内直接使用 Repeat
@Builder
function buildList(params: Params) {
  List() {
    Repeat(params.items)
      .each((ri: RepeatItem<string>) => {
        ListItem() {
          Text(ri.item).fontSize(16)
        }
      })
  }
}

// ✅ 正确：Repeat 放在 @Component 内，@Builder 使用该组件
@Component
struct ListContent {
  @Prop items: string[] = [];
  build() {
    List() {
      Repeat(this.items)
        .each((ri: RepeatItem<string>) => {
          ListItem() {
            Text(ri.item).fontSize(16)
          }
        })
    }
    .width('100%')
    .height(200)
  }
}

@Builder
function buildList(params: Params) {
  ListContent({ items: params.items })
}
```

### 未发现问题时

@Builder 内未直接使用 Repeat，或 Repeat 已放在 @Component 自定义组件内部再被 @Builder 引用。不报告。

## 规则依据

- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：说明章节——"仅支持在自定义组件中使用 Repeat"。
- [Repeat 开发指南](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/rendering-control/arkts-new-rendering-control-repeat.md)：使用限制——Repeat 必须在滚动类容器组件内使用。
