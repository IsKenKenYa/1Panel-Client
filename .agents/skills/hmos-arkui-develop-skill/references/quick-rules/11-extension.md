# 11. 扩展能力与交互

## 扩展能力

### DrawModifier
- **一个实例只能设置给一个组件**，禁止多个组件复用同一个 DrawModifier
- **不支持**在 attributeModifier 内调用 drawModifier

### GestureModifier
- **不支持**自定义组件
- **不支持**在 attributeModifier 内调用 gestureModifier

### AttributeUpdater
- **一个对象只能关联一个组件**，用于多个组件时只有一个生效
- 与状态变量同时更新同一属性时会**互相覆盖**

### NodeContainer
- **仅支持**自定义 FrameNode 节点和 BuilderNode 根节点作为子节点
- 系统组件代理节点**不能**成功挂载

### 节点单父规则
- 一个节点**只能有一个父节点**。挂载到多个 NodeContainer 会导致异常
- 迁移节点时**必须先从旧父节点移除**，再添加到新父节点

### FrameNode
- 声明式（系统）FrameNode **不可修改**：不能设置属性、增删子节点、绑定控制器（错误码 100021）
- 未挂载的节点**不能进行节点操作**（错误码 106203）

---

## 交互与手势

| 规则 | 说明 |
|------|------|
| 长按与拖拽冲突 | 长按手势与拖拽手势同时绑定时可能冲突，需注意优先级 |
| onDragLeave 限制 | onDragLeave 在某些场景下不触发，不要将核心逻辑挂在其上 |
| 匿名函数 this 问题 | ArkTS 中**不允许使用匿名函数**绑定事件，必须使用箭头函数 |
| bind(this) 不推荐 | 成员函数配合 bind(this) 配置事件方法不推荐 |
| TouchEvent 类型 | 触摸事件参数是 `TouchEvent`/`TouchObject`，**不存在 `TouchInfo`** |

### 事件绑定

```ts
// ❌ WRONG
.onClick(function() { this.do() })
.onClick(this.handler.bind(this))

// ✅ RIGHT
.onClick(() => { this.handler() })
```

## 参考

- 错误码：**100021**（声明式 FrameNode 不可修改）、**106203**（未挂载节点操作）