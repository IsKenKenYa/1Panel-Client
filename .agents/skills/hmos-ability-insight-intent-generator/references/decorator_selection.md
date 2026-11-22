# 装饰器选择指南

## 🚨 强制约束

只能使用以下 **6 种装饰器**，严禁根据语义自行创造任何其他装饰器名称（如 `@InsightIntentCustom`、`@IntentHandler` 等）。  
若用户需求无法由这 6 种装饰器实现，必须使用 `@InsightIntentEntry` 作为通用方案，并提示用户。

**可用装饰器列表**：
- `@InsightIntentEntry`
- `@InsightIntentLink`
- `@InsightIntentPage`
- `@InsightIntentFunctionMethod`
- `@InsightIntentForm`
- `@InsightIntentEntity`

## 选择优先级（从高到低）

### 1. 用户明确指定 → 直接使用
- 用户说了 `entry` / `func` / `page` / `link` / `form` 等 → 使用对应装饰器。
- 若技术上无法实现 → 提示并建议替代方案。

### 2. URI/Deep Link 跳转 → 优先 `@InsightIntentLink`
- 触发：用户要求通过链接（URI/URL/Deep Link）唤起应用或跳转。
- 处理流程：
  - 检查 `module.json5` 中是否已配置对应 URI。
  - ✅ 已配置 → 直接生成 Link 代码。
  - ❌ 未配置 → 停止，询问用户：“当前项目未配置 URI，我可以自动添加配置，是否同意？”
    - 同意 → 按“生成→预览→确认→写入”流程添加配置，再生成 Link 代码。
    - 拒绝 → 若能用 `@InsightIntentPage` 实现则降级使用 Page，否则提示手动配置。

### 3. 关键词快速匹配（需同时满足对应技术条件）

| 匹配类型             | 触发关键词                                                   | 必须满足的技术条件                                           | 不满足时处理                                                 |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **`标准意图`**       | `标准意图`、`系统意图`、`预定义意图`、`schema`、`Play+名词`、`Query+名词` 等系统预定义模式 | 官方定义了该意图的 schema；参数和返回值参照官方文档           | 搜索不到定义 → 降级为自定义 Entry（无 schema）               |
| **`Entry` (通用)**   | `新增`、`删除`、`修改`、`播放`、`发送`、`开启`、`关闭` 等操作类动词 | 无特殊限制                                                   | 直接使用                                                     |
| **`Function`**       | `返回`、`查询`、`获取`、`列出`、`计算`、`转换` **且** 不含操作类动词 | 方法必须是静态；类必须用 `@InsightIntentFunction()`；方法用 `@InsightIntentFunctionMethod()` | 告知必须满足静态方法+返回值规范，若用户坚持带 UI 则降级为 Entry |
| **`Page`**           | `跳转到xxx页面`、`打开xxx页面`、`查看`+页面类名词 **且** 目标固定（非动态路由） | 目标页面为 `@Entry` 或 `NavDestination` 且已注册             | 动态路由→降级Entry；未注册→提示先注册                        |

### 4. 按场景自动匹配

| 场景                       | 适用条件                                  | 使用的装饰器                                                 | 降级/处理方式                                                |
| -------------------------- | ----------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 页面跳转（打开应用内页面） | 核心动作是打开已有页面；无需复杂异步前置  | `@InsightIntentPage`                                         | 若无法确认页面存在或为 NavDestination → 降级 Entry           |
| 服务卡片                   | 明确要求添加/更新/删除系统桌面/负一屏卡片 | `@InsightIntentForm`                                         | 无降级，不匹配则跳过                                         |
| 轻量查询/操作（无界面）    | 无需打开页面；纯逻辑计算或 I/O            | `@InsightIntentFunction` (类) + `@InsightIntentFunctionMethod` (方法) | 若数据依赖 UI 渲染初始化（即使通过 `AppStorage` 中转），冷启动时会读到默认值；可在返回结果中标注状态，或改用 `@InsightIntentEntry` |
| **默认（以上均不满足）**   | 多步骤/动态路由/标准意图/需求模糊         | **`@InsightIntentEntry`**                                    | -                                                            |

## 降级路径速查

| 原计划       | 触发降级的条件                         | 降级方案                            |
| ------------ | -------------------------------------- | ----------------------------------- |
| `Link`       | 项目无 URI 配置且用户拒绝添加          | `Page`（若可行）否则提示手动        |
| `Page`       | 目标页面不是 `@Entry` 或未注册         | `Entry`                             |
| `Function`   | 需要打开界面或依赖 Ability 上下文      | `Page` 或 `Entry`（根据是否需界面） |
| `Function`   | 数据依赖 UI 渲染初始化且默认值不可接受 | `Entry`（需等待页面加载）           |
| 用户指定类型 | 技术上无法实现                         | 提示并建议替代                      |

## 字段命名规范（最容易出错）

| 装饰器                | Ability名称字段 | 执行模式字段  | 说明                              |
| --------------------- | --------------- | ------------- | --------------------------------- |
| `@InsightIntentPage`  | `uiAbility`     | 无            | 通过指定 `uiAbility` 关联 Ability |
| `@InsightIntentEntry` | `abilityName`   | `executeMode` | `executeMode` 必须是数组          |

**常见错误**：
```typescript
// ❌ 错误：在 @InsightIntentPage 中使用 abilityName
@InsightIntentPage({ abilityName: 'EntryAbility' })

// ✅ 正确：使用 uiAbility
@InsightIntentPage({ uiAbility: 'EntryAbility' })
```

## 标准意图处理流程

当匹配为"标准意图"时，必须执行以下步骤：

### 步骤 1：搜索官方定义
使用 `webfetch` 搜索官方文档获取标准意图规范：
- 标准意图接入规范：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-access-specifications — 包含所有标准意图的 schema、domain、参数和返回值定义
- 标准意图开发步骤：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/insight-intent-decorator-development#%E9%80%9A%E8%BF%87%E6%84%8F%E5%9B%BE%E8%A3%85%E9%A5%B0%E5%99%A8%E5%BC%80%E5%8F%91%E6%A0%87%E5%87%86%E6%84%8F%E5%9B%BE
- 搜索关键词格式：`HarmonyOS {意图名称} 标准意图`

### 步骤 2：获取完整规范
必须从搜索结果中提取以下信息：

| 信息 | 说明 | 示例 |
|------|------|------|
| `schema` | 标准意图名称 | `"PlayGame"` |
| `domain` | 意图垂域 | `"EntertainmentDomain"` |
| `intentVersion` | 版本号 | `"1.0.1"` |
| `parameters` | 参数列表及类型 | `entityId: string` |
| `result` | 返回值结构 | `{ code, result }` |

### 步骤 3：生成代码
- 在 `@InsightIntentEntry` 中必须添加 `schema` 字段
- 参数名、类型、必填性与官方定义完全一致
- 泛型参数 `T` 使用自定义接口匹配返回值结构
- 类属性名与 `parameters.properties` 中定义的属性名一一对应

```typescript
@InsightIntentEntry({
  intentName: 'PlayGame',
  schema: 'PlayGame',  // ← 标准意图标识
  domain: 'EntertainmentDomain',
  intentVersion: '1.0.1',
  displayName: '玩转游戏',
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],
  parameters: {
    'type': 'object',
    'properties': {
      'entityId': {
        'type': 'string',
        'description': '意图实体ID',
        'minLength': 1
      }
    },
    'required': ['entityId']
  }
})
```

### 步骤 4：验证
- schema 名称与官方文档一致
- 所有参数名、类型与官方定义一致
- `result` 字段包含 `resultDesc`
- 代码中无任何自创字段或类型

## 决策流程图

```text
用户需求
 → 明确指定装饰器？ → 是 → 技术可行？→ 生成 / 否→提示替代
 → 否 → URI/Link 跳转？ → 是 → 有配置？→ 生成 Link / 否→询问添加配置 → 同意则添加后生成 / 拒绝则降级 Page 或提示
 → 否 → 用户提及"标准意图/schema/系统意图/预定义意图"？
 → 是 → 搜索官方文档获取标准意图规范 → 找到？→ @InsightIntentEntry + schema / 未找到→降级自定义 Entry
 → 否 → 关键词匹配 Function/Page/Entry？ → 满足条件 → 生成对应类型 / 不满足→降级或提示
 → 否 → 按场景自动匹配 → 匹配则生成 / 否则默认 Entry
```

