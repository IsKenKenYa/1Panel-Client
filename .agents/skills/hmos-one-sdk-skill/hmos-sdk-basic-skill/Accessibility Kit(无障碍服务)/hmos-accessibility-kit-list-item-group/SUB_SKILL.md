---
name: hmos-accessibility-kit-list-item-group
description: 实现列表项无障碍组合，将显示文本和可操控组件作为整体聚焦播报，支持通过ID或类型桥接子组件状态和操作，适用于开关、单选框、复选框组合场景
---

# 列表项组合场景无障碍技能

## 功能描述

实现列表项的无障碍组合功能，将显示文本和可操控组件（如开关、单选框、复选框等）作为一个整体进行聚焦和播报。通过设置 accessibilityGroup 和 accessibilityOptions，桥接可操控组件的无障碍状态和点击事件，避免用户需要对子组件单独进行聚焦。

### 核心能力

1. **无障碍分组聚合**：将容器及其子组件作为整体进行无障碍聚焦
2. **状态桥接**：通过 stateControllerId 或 stateControllerRoleType 指定子组件控制状态播报
3. **操作桥接**：通过 actionControllerId 或 actionControllerRoleType 指定子组件控制点击操作
4. **文本拼接优化**：通过 accessibilityPreferred 优先使用无障碍文本进行拼接

## 使用场景

### 触发词

- "列表项无障碍组合"
- "无障碍分组设置"
- "accessibilityGroup"
- "列表项整体播报"
- "开关组合无障碍"
- "单选框组合无障碍"
- "复选框组合无障碍"

### 能做

- 实现列表项的整体聚焦和播报
- 桥接 Toggle、Radio、Checkbox 等组件的状态和操作
- 设置优先使用无障碍文本拼接
- 通过 ID 或类型指定控制组件
- 提升屏幕朗读用户体验

### 绝不做

- 不用于独立的可操控组件无障碍设置
- 不替代子组件本身的 accessibilityLevel 设置
- 不处理跨组件树的复杂无障碍逻辑
- 不支持自定义无障碍事件（仅支持点击）

### 补充

- 仅支持 API version 14+ 的 accessibilityOptions 参数
- 子组件需设置唯一 ID 以便精确桥接
- 多个相同类型/ID 子组件时，使用组件树上第一个匹配的子组件
- stateControllerId 优先级高于 stateControllerRoleType
- actionControllerId 优先级高于 actionControllerRoleType

## 调用规范和规则

### 输入约束

- **组件类型**：必须是容器组件（如 Column、Row、Flex）
- **子组件要求**：至少包含一个可操控组件（Toggle、Radio、Checkbox）和一个文本组件
- **ID 设置**：使用 stateControllerId 或 actionControllerId 时，子组件必须设置唯一 id
- **API 版本**：accessibilityOptions 参数需要 API version 14+

### 执行约束

- **最大嵌套层级**：建议不超过 3 层容器嵌套
- **子组件数量**：建议不超过 5 个直接子组件
- **文本长度**：拼接后的播报文本建议不超过 50 字符

### 内容约束

- 禁止在 accessibilityGroup 内使用 accessibilityLevel 为 "yes" 的子组件（会破坏聚合）
- 禁止同时设置 stateControllerId 和 stateControllerRoleType 指向不同组件（可能导致冲突）
- 禁止在动态生成的组件上使用（id 必须稳定）

### 降级约束

- **API 版本不支持**：仅使用 accessibilityGroup(true)，不设置 accessibilityOptions
- **找不到匹配组件**：回退到默认拼接逻辑，使用所有子组件文本
- **id 不存在**：忽略 stateControllerId/actionControllerId，使用默认逻辑

## 调用流程和步骤

### 步骤 1：准备阶段 - 创建列表项容器

**前置校验**：

1. 确认目标组件为容器组件（Column/Row/Flex 等）
2. 确认包含至少一个可操控组件（Toggle/Radio/Checkbox）
3. 确认包含文本描述组件

**参数准备**：

```typescript
// ArkTS 示例 - 准备列表项组件参数
@State isToggleOn: boolean = false; // 可操控组件状态
const toggleId: string = 'toggleControlId'; // 控制组件ID
```

### 步骤 2：设置子组件和 ID

**示例代码**：

```typescript
Column() {
  Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
    Text("是否开启功能") // 文本描述
    Toggle({ type: ToggleType.Switch, isOn: this.isToggleOn })
      .selectedColor('#007DFF')
      .switchPointColor('#FFFFFF')
      .onChange((isOn: boolean) => {
        this.isToggleOn = isOn;
        console.info('Toggle state changed:', isOn);
      })
      .id("toggletest1") // 设置唯一ID，用于桥接
  }
}
```

### 步骤 3：设置 accessibilityGroup 和 accessibilityOptions

**示例代码**：

```typescript
Column() {
  // ... 子组件定义 ...
}
.width('100%')
.accessibilityGroup(true, {
  stateControllerId: "toggletest1",  // 指定状态控制组件
  actionControllerId: "toggletest1"   // 指定操作控制组件
})
.border({ color: Color.Black, width: 2 })
.padding(10)
```

### 步骤 4：完整示例 - Toggle 开关组合

```typescript
@Entry
@Component
struct ToggleListItemExample {
  @State isToggleOn: boolean = false;
  
  build() {
    Column() {
      Text("按ID接管, state和action接管, 一个 toggle, 样式为开关")
      
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
          Text("是否开启功能")
          Toggle({ type: ToggleType.Switch, isOn: this.isToggleOn })
            .selectedColor('#007DFF')
            .switchPointColor('#FFFFFF')
            .onChange((isOn: boolean) => {
              this.isToggleOn = isOn;
              console.info('Toggle state:', isOn);
            })
            .id("toggletest1") // 关键：设置唯一ID
        }
      }
      .width('100%')
      .accessibilityGroup(true, {
        stateControllerId: "toggletest1",  // 桥接Toggle的状态
        actionControllerId: "toggletest1"   // 桥接Toggle的点击
      })
      .border({ color: Color.Black, width: 2 })
      .padding(10)
    }
  }
}
```

### 步骤 5：错误处理

```typescript
// 错误处理示例
Column() {
  Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
    Text("功能开关")
    Toggle({ type: ToggleType.Switch, isOn: false })
      .id("toggleId")
      .onChange((isOn: boolean) => {
        try {
          // 处理状态变更
          console.info('Toggle changed to:', isOn);
        } catch (error) {
          console.error('Toggle change error:', error.message);
        }
      })
  }
}
.accessibilityGroup(true, {
  stateControllerId: "toggleId",
  actionControllerId: "toggleId"
})
```

## accessibilityOptions 参数说明

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| accessibilityPreferred | boolean | 否 | 是否优先使用无障碍文本拼接，默认 false |
| stateControllerRoleType | string | 否 | 指定特定类型的子组件控制状态播报，默认空 |
| stateControllerId | string | 否 | 指定特定ID的子组件控制状态播报，默认空 |
| actionControllerRoleType | string | 否 | 指定特定类型的子组件控制操作执行，默认空 |
| actionControllerId | string | 否 | 指定特定ID的子组件控制操作执行，默认空 |

### 参数优先级

- **状态控制**：stateControllerId > stateControllerRoleType
- **操作控制**：actionControllerId > actionControllerRoleType
- **匹配顺序**：组件树上第一个匹配的子组件

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| ACCESSIBILITY_ID_NOT_FOUND | 指定的 stateControllerId 或 actionControllerId 对应的子组件不存在 | 确认子组件已设置正确的 id 属性 |
| ACCESSIBILITY_ROLE_NOT_MATCH | stateControllerRoleType 或 actionControllerRoleType 指定的类型无匹配子组件 | 确认子组件类型正确，或改用 ID 方式 |
| ACCESSIBILITY_API_UNSUPPORTED | API version 不支持 accessibilityOptions | 升级到 API version 14+，或仅使用 accessibilityGroup(true) |
| ACCESSIBILITY_LEVEL_CONFICT | 子组件设置了 accessibilityLevel("yes") 破坏了聚合 | 移除子组件的 accessibilityLevel("yes") 设置 |

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {},
  "devDependencies": {}
}
```

### 环境要求

- **HarmonyOS SDK**: API version 14+
- **DevEco Studio**: 3.1+

### 常见编译问题

**问题 1：accessibilityOptions 参数不生效**

```
Property 'accessibilityOptions' does not exist on type 'ColumnAttribute'
```

**解决方法**：升级到 API version 14+，检查 build-profile.json5 中的 compileSdkVersion

**问题 2：ID 指定的组件不匹配**

```
找不到 id="toggletest1" 的子组件
```

**解决方法**：确认子组件使用了 `.id("toggletest1")` 设置，且 id 唯一

**问题 3：状态播报不正确**

```
屏幕朗读未播报 Toggle 的选中状态
```

**解决方法**：检查 stateControllerId 是否指向正确的 Toggle 组件，确认 Toggle 的 onChange 事件正常触发

## 常见问题与解决方法

### Q1：如何选择使用 ID 还是 RoleType？

**原因**：两种方式各有优缺点

**解决方法**：

- **推荐使用 ID 方式**：精确匹配，避免歧义，适合固定结构
- **使用 RoleType 方式**：适合动态生成、不确定具体 ID 的场景
- **优先级**：ID 方式优先级更高，可同时设置作为备选

### Q2：多个相同类型的子组件如何处理？

**原因**：RoleType 匹配可能存在多个相同类型的子组件

**解决方法**：

- 系统会使用组件树上第一个匹配的子组件
- 建议使用 ID 方式精确指定
- 或通过调整组件顺序确保正确的组件被匹配

### Q3：accessibilityPreferred 如何使用？

**原因**：需要优先播报无障碍文本而非通用文本

**解决方法**：

```typescript
Column() {
  Text('123456')
    .accessibilityText("优先读此文本")
  Button("文本内容")
}
.accessibilityGroup(true, {
  accessibilityPreferred: true  // 优先拼接 accessibilityText
})
```

### Q4：动态列表项如何设置？

**原因**：列表项动态生成，ID 不固定

**解决方法**：

```typescript
List() {
  ForEach(this.dataList, (item: DataItem) => {
    ListItem() {
      Column() {
        Text(item.title)
        Toggle({ isOn: item.enabled })
          .id(`toggle_${item.id}`)  // 使用数据ID生成唯一ID
      }
      .accessibilityGroup(true, {
        stateControllerId: `toggle_${item.id}`,
        actionControllerId: `toggle_${item.id}`
      })
    }
  })
}
```

## 输出结果报告

执行完成后，列表项将具备以下无障碍特性：

```json
{
  "status": "success",
  "accessibilityFeature": "list-item-group",
  "componentsAffected": ["Column容器", "Toggle组件", "Text组件"],
  "apiUsed": [
    "accessibilityGroup",
    "accessibilityOptions.stateControllerId",
    "accessibilityOptions.actionControllerId"
  ],
  "userExperience": {
    "focusMode": "整体聚焦",
    "stateReporting": "桥接Toggle状态",
    "actionHandling": "桥接Toggle点击"
  }
}
```

## 参考文档

- [API开发指南 - 列表项组合场景](references/list-item-combination-scenarios.md)
- [API参考 - accessibilityGroup](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [API参考 - accessibilityOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-types)

## 完整示例代码

- [Toggle开关组合示例](assets/toggle-list-item-example.ets)
- [Radio单选框组合示例](assets/radio-list-item-example.ets)
- [Checkbox复选框组合示例](assets/checkbox-list-item-example.ets)
- [完整示例集合](assets/list-item-combination-full-example.ets)

## 测试用例

### 正向测试用例

- [Toggle开关ID桥接测试](tests/test_toggle_id_bridge.ets)：验证通过ID桥接Toggle状态和操作
- [Radio单选框ID桥接测试](tests/test_radio_id_bridge.ets)：验证通过ID桥接Radio状态和操作
- [Checkbox复选框ID桥接测试](tests/test_checkbox_id_bridge.ets)：验证通过ID桥接Checkbox状态和操作
- [accessibilityPreferred文本拼接测试](tests/test_accessibility_preferred.ets)：验证优先使用无障碍文本拼接

### 边界测试用例

- [多层嵌套容器测试](tests/test_nested_containers.ets)：验证多层容器下的聚合效果
- [多个相同ID组件测试](tests/test_duplicate_id.ets)：验证多个相同ID时的匹配逻辑
- [多个相同类型组件测试](tests/test_duplicate_role.ets)：验证多个相同类型时的匹配逻辑

### 异常测试用例

- [ID不存在测试](tests/test_invalid_id.ets)：验证指定ID不存在时的降级处理
- [API版本不支持测试](tests/test_api_version_unsupported.ets)：验证API version低于14时的降级处理
- [子组件accessibilityLevel冲突测试](tests/test_level_conflict.ets)：验证子组件设置accessibilityLevel("yes")时的冲突处理