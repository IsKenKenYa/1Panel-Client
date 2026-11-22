# 13. 样式与主题约束

## 规则

### @Extend

| 规则 | 说明 | 错误码 |
|------|------|--------|
| 仅支持全局定义 | 不能在组件内部定义 | — |
| 仅当前文件可用 | 不支持 export（需 export 用 AttributeModifier） | — |
| **不能与 @Styles 混用** | | — |
| **必须省略返回类型** | 不写 `: void`，否则破坏链式调用 | — |
| **禁止嵌套函数定义** | 逻辑抽到顶层方法，否则连锁语法崩溃 | arkts-no-nested-funcs |

```ts
// ❌ WRONG -- 标了 :void，链式调用炸
@Extend(Text) function card(): void { .padding(8) }
// -> .card().width() 报 Property 'width' does not exist on type 'void'

// ❌ WRONG -- 内嵌套函数
@Extend(Text) function card() { function inner() {} .padding(8) }
// -> 连锁引发 ';' expected / Only UI component syntax can be written here

// ✅ RIGHT -- 省略返回类型，逻辑抽顶层
@Extend(Text) function card() { .padding(8) .backgroundColor(Color.White) }
```

### @Styles

| 规则 | 说明 |
|------|------|
| 不支持参数 | |
| 不支持业务逻辑语句 | |
| 仅支持通用属性 | 不支持组件私有属性（如 Button 的 fontColor） |
| 不支持 export | |

### stateStyles

| 规则 | 说明 |
|------|------|
| 仅支持通用属性 | 组件私有属性不生效 |
| 聚焦状态仅通过外接键盘 Tab/方向键触发 | 不支持嵌套滚动组件内按键触发 |

### 实时模糊性能

| 接口 | 说明 |
|------|------|
| backdropBlur / blur / backgroundBlurStyle / foregroundBlurStyle / motionBlur | **每帧实时渲染，性能开销大** |
| 静态模糊场景 | 用 effectKit 的静态模糊接口 |

### clipShape

- clipShape 使用时，shape 的 **fill 属性不生效**

### 深色/浅色模式

| 规则 | 说明 |
|------|------|
| 通过函数返回值动态读取 colorMode 不可靠 | 热更新时属性设置代码可能不重新执行 |
| BuilderNode / ComponentContent 需手动传播系统环境变更 | 调用 `updateConfiguration()` |

### 动画约束

| 规则 | 说明 |
|------|------|
| 位置/尺寸动画性能差 | 推荐用 scale 替代 |
| onFinish 回调慎用 | 关闭开发者转场动画或 UIAbility 后台时，finish 回调立即触发 |
| animateToImmediately 慎用 | 绕过 vsync，正常用 animateTo |
| keyframeAnimateTo 不支持弹簧曲线 | 不支持 springMotion/responsiveSpringMotion/interpolatingSpring |
| springMotion/interpolatingSpring 自动计算时长 | 开发者指定的 duration 被忽略 |
| springCurve 不推荐 | 扭曲物理时间 |
| TransitionEffect.animation 的 onFinish 不生效 | |
| 父组件必须有 transition | 否则子组件消失转场不触发 |
| pageTransition 已废弃 | 用 Navigation 转场 / Modal 转场 |
| @AnimatableExtend 参数限制 | 只允许 number/string/Color 及其联合类型；卡片动画最大 1000ms |
| AnimatorResult 需及时销毁 | 否则内存泄漏 |

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `@Extend(Text) function card(): void { ... }` | 省略 `: void` | 破坏链式调用 |
| `@Extend` 内写 `function inner() {}` | 逻辑抽到顶层方法 | arkts-no-nested-funcs |
| `@Styles` 里写组件私有属性 | 仅通用属性 | 不生效 |
| `@Extend` 与 `@Styles` 混用 | 分开使用 | 不能混用 |

## 参考

- @Extend/@Styles 在状态管理中的位置见 [05-state-v1](05-state.md)
- 废弃接口 pageTransition 见 [19-deprecated](14-deprecated.md)