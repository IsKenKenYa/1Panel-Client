# 状态装饰器迁移指导

> 最后同步：2026-09
> 适用：步骤 3（设计）识别装饰器版本与选型、步骤 4（改码）实施改造

---

## 0. 快速识别

```
扫描页面文件
  │
  ├─ 发现 @Component + @State / @Prop / @Link
  │   └─ V1 组件 → 按 §1 改造（@StorageLink 模式）
  │
  ├─ 发现 @ComponentV2 + @Local / @Param / @Event / @Monitor
  │   └─ V2 组件 → 按 §2 改造（手动 AppStorage 绑定模式）
  │
  └─ 同时发现两种
      └─ 混合项目 → V1 部分按 §1，V2 部分按 §2
```

---

## 1. V1 装饰器 → @StorageLink 改造规则

> **目标端承接落点（完整链路）**：Ability 在 `onCreate`/`onNewWant` 的 CONTINUATION 分支把 `want.parameters` 写入 AppStorage → 页面组件用**同名 `@StorageLink`** 承接（如 Player/编辑器等业务组件字段的默认承接方式）。改造页面时先列出 Ability 侧写入的 key 清单，再逐 key 改造为 `@StorageLink`，勿手工在组件里二次搬运。

### 1.1 改造决策矩阵

| 原装饰器 | 值是否需要迁移到对端 | 改造方式 | 注意事项 |
|---|---|---|---|
| `@State x: T` | ✅ 需要 | 改为 `@StorageLink('x') x: T = defaultValue` | 移除原 `@State`；AppStorage key 建议与变量名一致；确保 Ability 的 `onCreate`/`onNewWant` 中先 `setOrCreate` 再触发页面加载（`restoreWindowStage()` / `loadContent`） |
| `@State x: T` | ❌ 不需要 | **保持 `@State`，不改** | 仅用于 UI 动画中间值、临时计算缓存等纯本组件内部状态 |
| `@Prop x: T` | ✅ 需要 | 改为 `@StorageLink('x') x: T = defaultValue`，**同时修改父组件**移除对应的 `@State` → 改 `@StorageLink` 同一 key | `@Prop` 是父→子单向流，改造后变为 AppStorage 全局共享，语义发生变化——需确认父子组件不再需要独立副本 |
| `@Prop x: T` | ❌ 不需要 | **保持 `@Prop`，不改** | 父组件传入的展示型数据 |
| `@Link x: T` | ✅ 需要 | 改为 `@StorageLink('x') x: T = defaultValue`，**同时修改父组件**移除 `@State` → 改 `@StorageLink` 同一 key | `@Link` 是双向绑定，改造后父子均通过 AppStorage 间接同步，语义等价 |
| `@Link x: T` | ❌ 不需要 | **保持 `@Link`，不改** | 仅父子组件间内部通信 |
| `@Watch('fn')` | 跟随宿主装饰器 | 改造宿主装饰器后，`@Watch` 可保留（V1 中 `@Watch` 可与 `@StorageLink` 共用） | 需验证回调触发时序 |
| `private x: T` | ✅ 需要 | 提升为 `@StorageLink('x') x: T = defaultValue` | 变量从 private 变为响应式，需确认无副作用 |
| `private x: T` | ❌ 不需要 | **不改** | Controller 实例、Scroller 等不可序列化对象始终保持 private |

### 1.2 改造步骤

```
1. 识别：从页面代码中提取所有 @State / @Prop / @Link 变量
2. 分类：逐个判断是否需要跨端迁移（参考 confirm-scene-inventory 中的"可变状态"定义）
3. 检查冲突：确认 AppStorage 中不存在同名 key（全局唯一性）
4. 改造：
   a. @State → @StorageLink('key')   （直接替换）
   b. @Prop  → @StorageLink('key')   （需同步修改父组件）
   c. @Link  → @StorageLink('key')   （需同步修改父组件）
5. 清理：移除原装饰器的初始化逻辑（@StorageLink 的默认值仅在 key 不存在时生效）
6. 验证：确保 Ability 的 onCreate/onNewWant 中在触发页面加载（restoreWindowStage() / loadContent）之前
         已 setOrCreate 所有相关 key
```

### 1.3 @State 改造示例

```typescript
// ═══ 改造前 ═══
@Entry
@Component
struct NotePage {
  @State title: string = '';           // 需要迁移
  @State draft: string = '';           // 需要迁移
  @State isExpanded: boolean = false;  // 不需要迁移（纯 UI 展示状态）
  private scroller: Scroller = new Scroller(); // 不可序列化，不迁移

  build() {
    Column() {
      TextInput({ text: this.title })
        .onChange((v: string) => { this.title = v; })
      TextArea({ text: this.draft })
        .onChange((v: string) => { this.draft = v; })
    }
  }
}

// ═══ 改造后 ═══
@Entry
@Component
struct NotePage {
  @StorageLink('note_title') title: string = '';           // ← @State → @StorageLink
  @StorageLink('note_draft') draft: string = '';           // ← @State → @StorageLink
  @State isExpanded: boolean = false;                      // ← 保持不变
  private scroller: Scroller = new Scroller();             // ← 保持不变

  build() {
    Column() {
      TextInput({ text: this.title })
        .onChange((v: string) => { this.title = v; })      // onChange 逻辑不变
      TextArea({ text: this.draft })
        .onChange((v: string) => { this.draft = v; })
    }
  }
}

// ═══ Ability 侧对应 ═══
onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
  wantParam['note_title'] = AppStorage.get<string>('note_title') as string;
  wantParam['note_draft'] = AppStorage.get<string>('note_draft') as string;
  return AbilityConstant.OnContinueResult.AGREE;
}
```

### 1.4 @Prop 改造特别注意（父子联动）

```typescript
// ═══ 改造前：@State + @Prop 父子单向流 ═══
// 父组件
@Component
struct Parent {
  @State selectedItem: string = '';
  build() { Child({ item: this.selectedItem }) }
}
// 子组件
@Component
struct Child {
  @Prop item: string = '';
  build() { Text(this.item) }
}

// ═══ 改造后：双方均改用 @StorageLink ═══
// 父组件
@Component
struct Parent {
  @StorageLink('selectedItem') selectedItem: string = '';
  build() { Child() }  // ← 不再通过构造参数传递
}
// 子组件
@Component
struct Child {
  @StorageLink('selectedItem') item: string = '';
  build() { Text(this.item) }
}
```

> ⚠️ **语义变化警告**：原 `@Prop` 是**值的深拷贝**（子组件修改不影响父组件），改造为 `@StorageLink` 后变为**全局共享引用**（子组件修改会同步到父组件和所有观察者）。如果业务上确实需要单向流，应保留 `@Prop` 不变，在子组件的 `aboutToAppear` 中手动将值写入 AppStorage。

### 1.5 @Link 改造示例

```typescript
// ═══ 改造前：@State + @Link 父子双向绑定 ═══
// 父组件
@Component
struct Parent {
  @State count: number = 0;
  build() { Child({ count: $count }) }
}
// 子组件
@Component
struct Child {
  @Link count: number;
  build() {
    Button(`${this.count}`)
      .onClick(() => { this.count++; })
  }
}

// ═══ 改造后：双方均改用 @StorageLink ═══
// 父组件
@Component
struct Parent {
  @StorageLink('count') count: number = 0;
  build() { Child() }
}
// 子组件
@Component
struct Child {
  @StorageLink('count') count: number = 0;
  build() {
    Button(`${this.count}`)
      .onClick(() => { this.count++; })
  }
}
```

---

## 2. @ComponentV2 组件的接续适配

### 2.1 V1 / V2 装饰器对照表

| V1 装饰器 | V2 等价 | 接续适配差异 |
|---|---|---|
| `@Component` | `@ComponentV2` | V2 组件不支持 `@StorageLink` / `@StorageProp` |
| `@State` | `@Local` | V2 的 `@Local` 无 AppStorage 自动绑定能力 |
| `@Prop` | `@Param` | V2 的 `@Param` 为只读入参 |
| `@Link` | `@Event` + `@Param` | V2 无双向绑定，需 `@Event` 回调 |
| `@Watch` | `@Monitor` | V2 的 `@Monitor` 可监听 `@Local` 变化 |
| `@StorageLink` | **无直接等价** | V2 必须手动读写 AppStorage |
| `@StorageProp` | **无直接等价** | 同上 |

### 2.2 V2 组件接续方案——手动 AppStorage 绑定模式

**数据流：**

```
@Local 变量 ——→ @Monitor 自动写入 ——→ AppStorage ——→ want.parameters ——→ 对端
                  ↑ aboutToAppear 手动读取 ↓
```

### 2.3 V2 页面改造示例

```typescript
// ═══ V2 改造前 ═══
@Entry
@ComponentV2
struct SearchPage {
  @Local searchText: string = '';

  build() {
    TextInput({ text: this.searchText, placeholder: '搜索' })
      .onChange((v: string) => { this.searchText = v; })
  }
}

// ═══ V2 改造后（手动 AppStorage 绑定）═══
@Entry
@ComponentV2
struct SearchPage {
  @Local searchText: string = '';

  aboutToAppear(): void {
    // 接续恢复：从 AppStorage 读取迁移数据
    const restored = AppStorage.get<string>('searchText');
    if (restored !== undefined) {
      this.searchText = restored;
    } else {
      AppStorage.setOrCreate<string>('searchText', this.searchText);
    }
  }

  // 监听 @Local 变化，自动同步到 AppStorage
  @Monitor('searchText')
  onSearchTextChanged(): void {
    AppStorage.set<string>('searchText', this.searchText);
  }

  build() {
    TextInput({ text: this.searchText, placeholder: '搜索' })
      .onChange((v: string) => { this.searchText = v; })
  }
}
```

### 2.4 V2 改造要点

| 要点 | 说明 |
|---|---|
| **不使用 `@StorageLink`** | V2 组件编译器会报语法错误 |
| **`@Monitor` 替代 `@Watch`** | 用于监听 `@Local` 变化并写入 AppStorage |
| **`aboutToAppear` 读取** | 替代 `@StorageLink` 的自动初始化 |
| **`aboutToDisappear` 清理**（可选） | 如需在页面销毁时清除 AppStorage key |
| **Ability 侧无差异** | `onContinue` / `onCreate` / `onNewWant` 的写法与 V1 完全一致，因为数据都在 AppStorage 中 |

### 2.5 V2 多变量示例（编辑器场景）

```typescript
@Entry
@ComponentV2
struct EditorPage {
  @Local title: string = '';
  @Local content: string = '';
  @Local scrollOffset: number = 0;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 接续恢复
    const restoredTitle = AppStorage.get<string>('editor_title');
    const restoredContent = AppStorage.get<string>('editor_content');
    const restoredOffset = AppStorage.get<number>('editor_scrollOffset');
    if (restoredTitle !== undefined) this.title = restoredTitle;
    if (restoredContent !== undefined) this.content = restoredContent;
    if (restoredOffset !== undefined) {
      this.scrollOffset = restoredOffset;
      // 延迟恢复滚动位置（布局完成后）
      setTimeout(() => {
        this.scroller.scrollTo({ xOffset: 0, yOffset: this.scrollOffset });
      }, 50);
    }
  }

  @Monitor('title')
  onTitleChanged(): void {
    AppStorage.set<string>('editor_title', this.title);
  }

  @Monitor('content')
  onContentChanged(): void {
    AppStorage.set<string>('editor_content', this.content);
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        TextInput({ text: this.title, placeholder: '标题' })
          .onChange((v: string) => { this.title = v; })
        TextArea({ text: this.content, placeholder: '正文' })
          .onChange((v: string) => { this.content = v; })
      }
    }
  }
}
```

### 2.6 V2 与 V1 混合项目处理

同一项目中可能同时存在 V1 和 V2 组件。处理原则：

- **V1 组件**：按 §1 的 `@StorageLink` 模式改造
- **V2 组件**：按 §2 的手动绑定模式改造
- **Ability 侧不区分 V1/V2**，统一从 AppStorage 读写
- **AppStorage key 命名建议**：使用 `页面前缀_变量名` 避免冲突（如 `editor_title`、`search_text`）

---

## 3. 改造禁忌

| 禁忌 | 原因 | 正确做法 |
|---|---|---|
| ❌ 给 `@ComponentV2` 添加 `@StorageLink` | 编译器报语法错误，V2 不支持 | 使用 `@Local` + `@Monitor` + 手动 AppStorage |
| ❌ 将 Scroller / Controller 等实例改为 `@StorageLink` | 不可序列化，无法跨端传递 | 保持 `private`，目标端重新创建实例 |
| ❌ 保留 `@State` 的同时新增同名 `@StorageLink` | 同一变量不能有两个状态装饰器 | 二选一：删除 `@State`，替换为 `@StorageLink` |
| ❌ 改造 `@Prop` 时只改子组件不改父组件 | 父子数据链路断裂 | 父子组件同步改造 |
| ❌ 改造后 Ability 的 `onCreate` 中未 `setOrCreate` 相关 key | `@StorageLink` 读到空值 | 确保 `setOrCreate` 在触发页面加载（`restoreWindowStage()` / `loadContent`）之前执行 |
| ❌ V2 组件中遗漏 `@Monitor` 写入 | 用户修改不会同步到 AppStorage，`onContinue` 读到旧值 | 每个需要迁移的 `@Local` 变量必须有对应的 `@Monitor` |
| ❌ 用全局可持久状态的残留值（token/id 非空、计数 > 0 等）启发式判定"接续落地" | AppStorage 跨页面重进持续存在：迁移一次后，对端"新建/另开条目"误命中接续分支，旧 id/草稿经 `@StorageLink` 回写，保存时覆盖旧记录（新建功能失效，编译全过） | 用**一次性显式标记**：路由参数传递，或消费即清除的 flag（读后立即置回） |
| ❌ `@StorageLink` 共享键消费后不清，非接续入口未显式重置 | "新建/编辑另一条"读到上一条残留数据，多入口互相污染 | 非接续入口按 `id === ''`/`undefined` 显式重置；或在 `aboutToDisappear` 清理共享键 |
