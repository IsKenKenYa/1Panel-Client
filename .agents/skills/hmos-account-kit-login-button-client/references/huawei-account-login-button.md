# 华为账号登录按钮样式知识

> 用途：供 Skill 在生成、修改或审查 `LoginWithHuaweiIDButton` 代码时直接读取。
>
> 适用范围：Account Kit `LoginWithHuaweiIDButton` 组件中，本 Skill 使用的
> 华为账号登录按钮样式。
>
> **全局默认配色规则：如果用户、需求文档或现有代码没有显式指定按钮配色，
> 必须默认使用华为红，即 `BUTTON_RED`。**
>
> 官方参考：[loginComponentManager（华为账号登录组件管理）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-v5/account-api-component-manager-V5)

## 目录

- [1. 核心结论](#1-核心结论)
- [2. 纯文本按钮](#2-纯文本按钮)
- [3. 图文混合按钮](#3-图文混合按钮)
- [4. Skill 选型规则](#4-skill-选型规则)
- [5. 代码审查清单](#5-代码审查清单)

## 1. 核心结论

本 Skill 使用以下两种华为账号登录按钮样式：

| 类型     | 关键参数                                 | 华为红预置样式      | 支持任意自定义颜色                |
| ------ | ------------------------------------ | ------------ | ------------------------ |
| 纯文本按钮  | `BUTTON_*`，`textAndIconStyle: false` | `BUTTON_RED` | 支持，但必须使用 `BUTTON_CUSTOM` |
| 图文混合按钮 | `BUTTON_*`，`textAndIconStyle: true`  | `BUTTON_RED` | 不支持                      |

必须遵守以下规则：

1. 本文所有华为账号登录按钮示例均使用
   `loginComponentManager.LoginType.ID`。
2. 如果没有显式指定配色，默认使用华为红：纯文本和图文混合使用
   `BUTTON_RED`。
3. `BUTTON_CUSTOM` 仅支持纯文本按钮，不能用于图文混合按钮。
4. 图文混合按钮只能选择系统预置配色，不能任意设置背景色、文字色或华为
   图标颜色。

本文只说明按钮 UI 相关的 `params` 设置。示例中的
`controller: this.loginController` 仅用于保留完整的组件调用结构，不展开控制器、
登录回调或授权结果处理。

## 2. 纯文本按钮

### 2.1 识别方式

纯文本按钮使用 `BUTTON_*` 样式，并满足以下条件：

```arkts
textAndIconStyle: false
```

`textAndIconStyle` 未设置时也是纯文本模式。建议在知识示例中显式设置为
`false`，便于识别按钮类型。

### 2.2 系统预置颜色

| Style                  | 背景颜色 | 文字颜色 | 描边  |
| ---------------------- | ---- | ---- | --- |
| `BUTTON_RED`           | 红色   | 白色   | 无   |
| `BUTTON_WHITE`         | 白色   | 黑色   | 无   |
| `BUTTON_WHITE_OUTLINE` | 白色   | 黑色   | 有   |
| `BUTTON_BLACK`         | 黑色   | 白色   | 无   |
| `BUTTON_GRAY`          | 灰色   | 黑色   | 无   |

系统文档描述的是语义颜色，不应自行假设或硬编码系统样式内部使用的具体色值。
本类型没有显式指定配色时，必须默认选择 `BUTTON_RED`。

### 2.3 华为红调用模板

```arkts
LoginWithHuaweiIDButton({
  params: {
    style: loginComponentManager.Style.BUTTON_RED,
    loginType: loginComponentManager.LoginType.ID,
    textAndIconStyle: false,
    supportDarkMode: true
  },
  controller: this.loginController
})
.width('100%')
.height(40)
```

### 2.4 更换系统预置颜色

基于 2.3 的模板，只需替换 `style`，其他参数不变。例如需要白底黑字且带描边
时，将其改为 `loginComponentManager.Style.BUTTON_WHITE_OUTLINE`。

### 2.5 自定义颜色模式

纯文本按钮需要任意自定义颜色时，必须设置：

```arkts
style: loginComponentManager.Style.BUTTON_CUSTOM
```

#### 简单自定义

`CustomButtonParams` 支持自定义背景颜色，文字颜色可以选择白色或黑色：

```arkts
LoginWithHuaweiIDButton({
  params: {
    style: loginComponentManager.Style.BUTTON_CUSTOM,
    loginType: loginComponentManager.LoginType.ID,
    borderRadius: 20,
    supportDarkMode: false,
    customButtonParams: {
      backgroundColor: '#007DFF',
      fontColor: loginComponentManager.FontColor.WHITE
    }
  },
  controller: this.loginController
})
.width('100%')
.height(40)
```

`CustomButtonParams.fontColor` 支持：

| FontColor         | 文字颜色 |
| ----------------- | ---- |
| `FontColor.WHITE` | 白色   |
| `FontColor.BLACK` | 黑色   |

#### 使用 ButtonStyle 设置任意文字色

如果文字颜色不是白色或黑色，可以通过 `ButtonStyle` 传入
`ResourceColor`。在上面的完整模板中，将 `customButtonParams` 替换为：

```arkts
extraStyle: {
  buttonStyle: new loginComponentManager.ButtonStyle()
    .backgroundColor('#007DFF')
    .fontColor('#FFF0F0')
}
```

如果同时设置 `customButtonParams` 和 `extraStyle.buttonStyle` 中的同名颜色
属性，以 `ButtonStyle` 设置的值为准。

#### 自定义模式注意事项

- `BUTTON_CUSTOM` 仅支持纯文本按钮。
- 自定义按钮需要应用自行适配深色模式和浅色模式。
- 固定十六进制颜色通常应设置 `supportDarkMode: false`，然后由应用根据当前
  主题切换颜色。
- 不要使用 `BUTTON_CUSTOM` 配合 `textAndIconStyle: true`，该组合不能产生
  合法的自定义图文按钮。

## 3. 图文混合按钮

### 3.1 识别方式

图文混合按钮使用 `BUTTON_*` 样式，并设置：

```arkts
textAndIconStyle: true
```

该配置适用于华为账号登录按钮，本文示例使用 `LoginType.ID`，支持的样式为：

- `BUTTON_RED`
- `BUTTON_WHITE`
- `BUTTON_WHITE_OUTLINE`
- `BUTTON_BLACK`
- `BUTTON_GRAY`

### 3.2 系统预置颜色

| Style                  | 背景颜色 | 文字颜色 | 华为图标    |
| ---------------------- | ---- | ---- | ------- |
| `BUTTON_RED`           | 红色   | 白色   | 由组件自动匹配 |
| `BUTTON_WHITE`         | 白色   | 黑色   | 由组件自动匹配 |
| `BUTTON_WHITE_OUTLINE` | 白色   | 黑色   | 由组件自动匹配 |
| `BUTTON_BLACK`         | 黑色   | 白色   | 由组件自动匹配 |
| `BUTTON_GRAY`          | 灰色   | 黑色   | 由组件自动匹配 |

华为图标颜色由组件根据 `Style` 自动匹配，没有独立的图标颜色参数。
本类型没有显式指定配色时，必须默认选择 `BUTTON_RED`。

### 3.3 华为红调用模板

```arkts
LoginWithHuaweiIDButton({
  params: {
    style: loginComponentManager.Style.BUTTON_RED,
    loginType: loginComponentManager.LoginType.ID,
    textAndIconStyle: true,
    supportDarkMode: true
  },
  controller: this.loginController
})
.width('100%')
.height(40)
```

### 3.4 颜色限制

图文混合按钮不支持任意自定义背景色、文字色或华为图标颜色，只能选择系统
预置的 `BUTTON_*` 配色。

禁止生成以下配置：

```arkts
// 错误选型：BUTTON_CUSTOM 仅支持纯文本，不能生成自定义图文按钮。
style: loginComponentManager.Style.BUTTON_CUSTOM,
textAndIconStyle: true
```

如果用户要求图文混合按钮使用自定义颜色，应说明 Account Kit 官方组件不支持
该组合，并终止本 Skill；不得自行更换按钮类型、猜测近似颜色或进入交互选择。

## 4. Skill 选型规则

Skill 生成按钮代码时，按以下顺序判断：

1. 先判断用户、需求文档或现有代码是否显式指定配色：
   - 已明确指定：按指定配色选择对应的 `Style`；
   - 未明确指定：默认使用华为红，即 `BUTTON_RED`。
2. 华为账号登录按钮只显示文字：
   - 使用 `BUTTON_*`；
   - 设置 `textAndIconStyle: false`；
   - 如果要求任意颜色，使用 `BUTTON_CUSTOM`。
3. 华为账号登录按钮同时显示华为图标和文字：
   - 使用 `BUTTON_*`；
   - 设置 `textAndIconStyle: true`；
   - 如果要求系统预置配色以外的任意颜色，说明不支持并终止 Skill；不得猜测或选择近似配色。
4. 无论选择哪种按钮样式：
   - `loginType` 均设置为 `loginComponentManager.LoginType.ID`。

## 5. 代码审查清单

- [ ] `loginType` 是 `LoginType.ID`。
- [ ] 没有显式配色要求时，使用 `BUTTON_RED`。
- [ ] 纯文本使用 `BUTTON_*` 和 `textAndIconStyle: false`。
- [ ] 图文混合使用 `BUTTON_*` 和 `textAndIconStyle: true`。
- [ ] `BUTTON_CUSTOM` 只用于纯文本按钮。
- [ ] 图文混合没有使用 `BUTTON_CUSTOM`。
- [ ] 系统预置样式没有被外层 `.backgroundColor()` 强行覆盖。
- [ ] 自定义纯文本按钮已考虑深色模式和浅色模式。
