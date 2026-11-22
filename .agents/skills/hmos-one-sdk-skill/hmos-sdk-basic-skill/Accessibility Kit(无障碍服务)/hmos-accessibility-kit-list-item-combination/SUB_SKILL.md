---
name: hmos-accessibility-kit-list-item-combination
description: 将列表项中的显示文本和可操控组件组合为一个整体进行聚焦和播报，支持Toggle、Radio、Checkbox等组件的无障碍状态和点击事件桥接，适用于提升屏幕朗读无障碍体验场景
---

# 列表项组合场景技能

## 功能描述

本技能用于实现列表项的无障碍组合功能，将列表项中的显示文本和可操控组件（如开关、单选框、复选框）作为一个整体进行聚焦和播报。通过设置accessibilityGroup属性和使用accessibilityOptions参数，可以桥接可操控组件的无障碍状态和无障碍点击事件，提升屏幕朗读用户体验。

核心能力包括：
- 将容器组件及其子组件聚合为一个无障碍焦点
- 通过stateControllerId和actionControllerId指定控制组件
- 桥接子组件的选中状态和点击事件到聚合组件
- 支持Toggle（开关、按钮、复选框）、Radio、Checkbox等组件

## 使用场景

### 触发词
- "列表项无障碍组合"
- "列表项聚合播报"
- "组合组件无障碍"
- "屏幕朗读列表项"
- "Toggle无障碍组合"
- "Radio无障碍组合"
- "Checkbox无障碍组合"

### 能做
- 将列表项中的文本和可操控组件组合为一个整体进行聚焦
- 桥接Toggle、Radio、Checkbox组件的状态和点击事件
- 设置特定子组件作为状态控制器和操作控制器
- 实现屏幕朗读时的整体播报体验

### 绝不做
- 不处理非列表项场景的无障碍组合
- 不修改组件的视觉样式和交互行为
- 不替代组件原有的无障碍属性设置
- 不处理复杂的嵌套组件结构（建议拆解为更小的组合单元）

### 补充
- 适用于API version 14及以上版本
- 需要为控制组件设置唯一id属性
- 仅支持无障碍点击操作的桥接
- 聚合组件内的多个相同类型子组件，默认使用组件树上的第一个作为控制组件

## 调用规范和规则

### 输入约束
- 组件层级：列表项结构应包含容器组件（如Column、Row）和至少一个可操控组件
- 控制组件id：stateControllerId和actionControllerId必须对应实际存在的子组件id
- API版本：需要API version 14及以上才能使用accessibilityOptions参数

### 执行约束
- 最大嵌套层级：建议不超过3层，避免复杂的无障碍聚合
- 控制组件数量：每个聚合组件建议只设置1-2个控制组件（状态和操作）
- 无障碍文本设置：聚合组件建议设置accessibilityText，避免播报内容缺失

### 内容约束
- 禁止在非容器组件上设置accessibilityGroup
- 禁止使用不存在或重复的id作为controllerId
- 禁止同时设置stateControllerRoleType和stateControllerId的冲突配置
- 禁止在聚合组件内使用accessibilityLevel为"yes"的子组件（会脱离聚合约束）

### 降级约束
- API version低于14：使用基础版accessibilityGroup(value: boolean)，不支持控制组件桥接
- 控制组件不存在：聚合组件仍可聚焦，但无法桥接状态和操作
- 无障碍文本缺失：使用子组件文本拼接作为播报内容

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认目标组件为容器组件（Column、Row、Flex等）
2. 确认容器内包含可操控组件（Toggle、Radio、Checkbox）
3. 确认API version ≥ 14（需要使用accessibilityOptions）
4. 确认可操控组件已设置唯一id

**参数准备**：
```typescript
// ArkTS示例
interface AccessibilityOptionsConfig {
  stateControllerId?: string;     // 状态控制组件id
  actionControllerId?: string;    // 操作控制组件id
}
```

### 步骤2：设置容器组件accessibilityGroup

**示例代码**：
```typescript
// 导入必要模块（ArkTS内置，无需额外导入）

// 设置容器组件的无障碍聚合
Column() {
  // 子组件内容
  Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
    Text("是否开启功能")
    Toggle({ type: ToggleType.Switch, isOn: true })
      .selectedColor('#007DFF')
      .switchPointColor('#FFFFFF')
      .onChange((isOn: boolean) => {
        console.info('Component status:' + isOn);
      })
      .id("toggletest1")  // 设置唯一id
  }
}
.width('100%')
.accessibilityGroup(true, {
  stateControllerId: "toggletest1",   // 指定状态控制组件
  actionControllerId: "toggletest1"   // 指定操作控制组件
})
.border({ color: Color.Black, width: 2 }).padding(10)
```

### 步骤3：配置控制组件

**Toggle组件示例（开关样式）**：
```typescript
Toggle({ type: ToggleType.Switch, isOn: true })
  .selectedColor('#007DFF')
  .switchPointColor('#FFFFFF')
  .onChange((isOn: boolean) => {
    console.info('Toggle status:' + isOn);
  })
  .id("toggletest1")  // 必须设置id，与accessibilityGroup配置一致
```

**Toggle组件示例（按钮样式）**：
```typescript
Toggle({ type: ToggleType.Button, isOn: true }) {
  Text('status button').fontColor('#182431').fontSize(12)
}
.width(106)
.selectedColor('rgba(0,125,255,0.20)')
.onChange((isOn: boolean) => {
  console.info('Button toggle status:' + isOn);
})
.id("toggletest1")
```

**Toggle组件示例（复选框样式）**：
```typescript
Toggle({ type: ToggleType.Checkbox, isOn: false })
  .selectedColor('#007DFF')
  .switchPointColor('#FFFFFF')
  .onChange((isOn: boolean) => {
    console.info('Checkbox toggle status:' + isOn);
  })
  .id("toggletest1")
```

**Radio组件示例**：
```typescript
Radio({
  value: 'Radio2.1', 
  group: 'radioGroup2',
  indicatorType: RadioIndicatorType.TICK
})
  .radioStyle({
    checkedBackgroundColor: Color.Pink
  })
  .checked(false)
  .height(20)
  .width(20)
  .onChange((isChecked: boolean) => {
    console.info('Radio1 status is ' + isChecked);
  })
  .id("radiotest1")  // 设置id
```

**Checkbox组件示例**：
```typescript
Checkbox({ name: 'checkbox2', group: 'checkboxGroup2' })
  .select(true)
  .selectedColor(0xed6f21)
  .shape(CheckBoxShape.CIRCLE)
  .onChange((value: boolean) => {
    console.info('Checkbox2 change is' + value);
  })
  .id("checkboxtest1")  // 设置id
```

### 步骤4：完整示例代码

```typescript
@Entry
@Component
export struct ListItemCombinationExample {
  @State isToggleSwitch: boolean = false;
  @State isChecked: boolean = false;
  @State isSelected: boolean = false;
  
  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column({ space: 30 }) {
            // 示例1：Toggle开关组合
            Column() {
              Text("开关组合示例")
              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否开启功能")
                  Toggle({ type: ToggleType.Switch, isOn: true })
                    .selectedColor('#007DFF')
                    .switchPointColor('#FFFFFF')
                    .onChange((isOn: boolean) => {
                      console.info('Component status:' + isOn);
                    })
                    .id("toggletest1")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "toggletest1",
                actionControllerId: "toggletest1"
              })
              .border({ color: Color.Black, width: 2 }).padding(10)
            }
            
            // 示例2：Radio组合
            Column() {
              Text("单选框组合示例")
              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否改变单选框")
                  Radio({
                    value: 'Radio2.1', 
                    group: 'radioGroup2',
                    indicatorType: RadioIndicatorType.TICK
                  })
                    .radioStyle({
                      checkedBackgroundColor: Color.Pink
                    })
                    .checked(false)
                    .height(20)
                    .width(20)
                    .onChange((isChecked: boolean) => {
                      console.info('Radio1 status is ' + isChecked);
                    })
                    .id("radiotest1")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "radiotest1",
                actionControllerId: "radiotest1"
              })
              .border({ color: Color.Black, width: 2 }).padding(10)
            }
            
            // 示例3：Checkbox组合
            Column() {
              Text("复选框组合示例")
              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否改变复选框")
                  Checkbox({ name: 'checkbox2', group: 'checkboxGroup2' })
                    .select(true)
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .onChange((value: boolean) => {
                      console.info('Checkbox2 change is' + value);
                    })
                    .id("checkboxtest1")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "checkboxtest1",
                actionControllerId: "checkboxtest1"
              })
              .border({ color: Color.Black, width: 2 }).padding(10)
            }
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .width("100%")
      }
      .width("100%")
      .height("100%")
    }
    .title("列表项组合场景")
  }
}
```

### 步骤5：错误处理

```typescript
// 错误处理代码示例
Column() {
  // 子组件内容
  Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
    Text("是否开启功能")
    Toggle({ type: ToggleType.Switch, isOn: true })
      .onChange((isOn: boolean) => {
        try {
          // 业务逻辑处理
          if (isOn) {
            console.info('Feature enabled');
          } else {
            console.info('Feature disabled');
          }
        } catch (error) {
          console.error('Toggle onChange error:', error.message);
        }
      })
      .id("toggletest1")
  }
}
.width('100%')
.accessibilityGroup(true, {
  stateControllerId: "toggletest1",
  actionControllerId: "toggletest1"
})
.onError((error: Error) => {
  console.error('Accessibility group error:', error.message);
  // 降级处理：使用基础版accessibilityGroup
  // this.accessibilityGroup(true);
})
```

### 步骤6：降级处理

```typescript
// API version判断和降级处理
@Component
export struct ListItemCombinationFallback {
  @State apiVersion: number = 14;  // 实际应用中应从系统获取
  
  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
        Text("是否开启功能")
        Toggle({ type: ToggleType.Switch, isOn: true })
          .id("toggletest1")
      }
    }
    .width('100%')
    .accessibilityGroup(this.getAccessibilityGroupConfig())
    .border({ color: Color.Black, width: 2 }).padding(10)
  }
  
  private getAccessibilityGroupConfig(): boolean | [boolean, AccessibilityOptions] {
    if (this.apiVersion >= 14) {
      return [true, {
        stateControllerId: "toggletest1",
        actionControllerId: "toggletest1"
      }];
    } else {
      // 降级方案：使用基础版accessibilityGroup
      return true;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| INVALID_ID | 控制组件id不存在或重复 | 确保设置的id对应实际存在的组件，且id唯一 |
| API_VERSION_LOW | API version低于14，不支持accessibilityOptions | 使用基础版accessibilityGroup(value: boolean)，或升级API版本 |
| COMPONENT_TYPE_ERROR | 控制组件类型不支持 | 使用Toggle、Radio、Checkbox等支持无障碍操作的组件 |
| NESTING_TOO_DEEP | 组件嵌套层级超过限制 | 拆解复杂结构，减少嵌套层级 |
| ACCESSIBILITY_LEVEL_CONFLICT | 子组件accessibilityLevel设置为"yes"导致脱离聚合 | 将子组件accessibilityLevel设置为"auto"或"no" |

## 编译和修复问题

### 依赖声明
无额外依赖，使用ArkUI内置组件和属性。

### 环境要求
- API version：≥ 14（推荐）
- 开发环境：DevEco Studio
- 目标设备：支持HarmonyOS的设备

### 常见编译问题

**问题1：accessibilityOptions参数类型错误**
```
error: Type 'AccessibilityOptions' is not assignable to type 'boolean'
```
**解决方法**：确保使用accessibilityGroup的两个参数版本：`accessibilityGroup(true, options)`

**问题2：组件id未设置**
```
error: Property 'id' does not exist on type 'Toggle'
```
**解决方法**：确保组件支持id属性，并在组件上显式设置id：`.id("uniqueId")`

**问题3：API version不匹配**
```
error: 'accessibilityGroup' API version mismatch
```
**解决方法**：检查项目配置的API version，确保≥14，或使用降级方案

## 常见问题与解决方法

### Q1：聚合组件播报内容不完整
**原因**：未设置accessibilityText，子组件文本拼接规则不符合预期
**解决方法**：
- 为聚合组件设置accessibilityText属性
- 使用accessibilityPreferred参数优先拼接无障碍文本
- 确保子组件有明确的文本或无障碍文本

### Q2：控制组件的状态未正确播报
**原因**：stateControllerId未正确设置或组件id不匹配
**解决方法**：
- 检查stateControllerId与组件id是否一致
- 确认控制组件支持选中状态（如Toggle的isOn、Radio的checked）
- 确认控制组件在组件树上的位置正确

### Q3：聚合组件点击无响应
**原因**：actionControllerId未正确设置或组件不支持点击操作
**解决方法**：
- 检查actionControllerId与组件id是否一致
- 确认控制组件支持点击操作（如Toggle、Radio、Checkbox）
- 确认控制组件的onChange回调已实现

### Q4：多个相同类型组件时，状态播报混乱
**原因**：组件树上有多个相同类型的子组件，默认使用第一个
**解决方法**：
- 使用唯一id明确指定控制组件（推荐）
- 确保控制组件在组件树上的顺序正确
- 避免在聚合组件内使用多个相同类型的控制组件

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "function": "列表项无障碍组合",
  "accessibilityGroup": "已设置",
  "stateController": {
    "type": "Toggle/Radio/Checkbox",
    "id": "设置的组件id",
    "bridgeSuccess": true
  },
  "actionController": {
    "type": "Toggle/Radio/Checkbox",
    "id": "设置的组件id",
    "bridgeSuccess": true
  },
  "apiUsed": [
    "accessibilityGroup(isGroup: boolean, accessibilityOptions: AccessibilityOptions)",
    "Toggle.id(value: string)",
    "Radio.id(value: string)",
    "Checkbox.id(value: string)"
  ],
  "version": "API version 14+"
}
```

## 参考文档

- [API开发指南 - 列表项组合场景](references/list-item-combination-scenarios.md)
- [API参考说明 - accessibilityGroup](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [API参考说明 - AccessibilityOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-types)

## 完整示例代码

- [ArkTS完整示例 - Toggle组合](assets/example_toggle.ets)
- [ArkTS完整示例 - Radio组合](assets/example_radio.ets)
- [ArkTS完整示例 - Checkbox组合](assets/example_checkbox.ets)
- [ArkTS完整示例 - 多类型组合](assets/example_combined.ets)

## 测试用例

### 正向测试用例
- [Toggle开关组合测试](tests/test_toggle_switch.ets)：验证Toggle开关样式组件的无障碍组合
- [Radio组合测试](tests/test_radio.ets)：验证Radio组件的无障碍组合
- [Checkbox组合测试](tests/test_checkbox.ets)：验证Checkbox组件的无障碍组合

### 边界测试用例
- [多组件组合测试](tests/test_multi_components.ets)：验证多个相同类型组件的组合场景
- [嵌套容器测试](tests/test_nested_container.ets)：验证嵌套容器组件的组合场景
- [API version降级测试](tests/test_api_version_fallback.ets)：验证低API version的降级处理

### 异常测试用例
- [无效id测试](tests/test_invalid_id.ets)：验证控制组件id不存在时的错误处理
- [类型冲突测试](tests/test_type_conflict.ets)：验证组件类型不支持时的错误处理
- [accessibilityLevel冲突测试](tests/test_level_conflict.ets)：验证子组件accessibilityLevel设置冲突时的处理