# 功能性测试用例

> 本文件是功能用例的唯一来源，供仓库智能检视流水线（hmos-skill-test-runner）及人工验证共用。覆盖默认能力门（D0）、知识问答（Q 类）、A~G 诉求路由与版本门禁上下文，共 35 个功能用例。执行时只提交每条"输入"，不传入"预期输出"；使用方式见 [测试说明](README.md)。

通用适配判定：产出代码时属性用法与 templates/ 基线一致，且已核对工程 build-profile.json5 三字段；纯答疑、知识问答、追问与版本阻断类用例不产出属性代码本身即为预期，不计入编译分母（知识问答类另需零工程文件读取、零版本门禁）。

---

### 测试用例：FUNC-DEFAULT-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

我们的应用准备适配无障碍，但还不知道从哪里开始，帮我看看从哪里入手。

**业务场景与成立条件**：

普通 ArkTS 工程（API 26），未提供具体组件或高阶诉求；首页为普通导航列表。

```ts
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('Accessibility Demo')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      List({ space: 8 }) {
        ListItem() {
          Text('B01 设置页')
            .fontSize(16)
            .padding(12)
            .onClick(() => { /* 路由跳转 */ })
        }
      }.width('92%')
    }.width('100%').height('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 走 D0 默认能力门：输出默认播报四要素（组件类型、文本内容、操作结果、当前状态）
- 指出需额外适配的边界（如无文本图标/图片、自绘内容、需显式状态语义、聚合/走焦等高阶诉求）；可一并说明无障碍可达前提（可识别、功能及操作信息、状态与行为）
- 明确询问默认能力是否满足，不直接生成属性代码

**应包含**：组件类型, 操作结果, 当前状态


---

### 测试用例：FUNC-DEFAULT-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

设置页里那两个'保存设置''恢复默认'按钮，读屏用户用起来有问题吗？需要专门处理吗？

**业务场景与成立条件**：

API 26 工程；目标为有可见文本的标准 Button 组件。

```ts
@Entry
@Component
struct B01DefaultAdapt {
  build() {
    Column({ space: 24 }) {
      Text('设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('当前版本：1.0.0')
        .fontSize(16)
        .fontColor('#666666')
      Button('保存设置')
        .width('60%')
        .onClick(() => { /* 保存设置 */ })
      Button('恢复默认')
        .width('60%')
        .backgroundColor('#f0f0f0')
        .fontColor('#333333')
        .onClick(() => { /* 恢复默认 */ })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 判定有文本的标准组件默认能力满足（如 Button 默认播报"按钮，保存设置，单指双击即可执行"）
- 明确告知已默认适配、无需额外设置，零属性收尾
- 不输出多余无障碍属性代码（避免过度适配）

**应包含**：默认
**不应包含**：.accessibilityText(


---

### 测试用例：FUNC-TEXT-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这个页面里的播放图标没有文字，读屏不知道它是干什么的，帮我加上说明。

**业务场景与成立条件**：

API 26 工程（build-profile 三字段满足 12+）；无文本 Image 组件承载播放操作。

```ts
@Entry
@Component
struct B02PlayIcon {
  build() {
    Column({ space: 24 }) {
      Text('B02 无文本播放图标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column() {
        Image($r('app.media.play'))
          .width(60)
          .height(60)
          .onClick(() => { /* 播放逻辑 */ })
      }
      .backgroundColor('#f1f2f3')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 诉求明显超出默认能力，不重复走 D0 询问，直接路由 A 类并说明判定依据
- 给出 Image `.accessibilityText('播放')`；text 表达"是什么"，不混入操作引导与状态信息
- 说明改前/改后播报差异：改后播报"播放，图片，单指双击即可执行"，系统仍补充组件类型与操作提示

**应包含**：accessibilityText, 播放
**不应包含**：.accessibilityDescription(


---

### 测试用例：FUNC-TEXT-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这个按钮显示'提交订单'，读屏聚焦它时我希望念'支付 99 元'，请直接帮我修改。

**业务场景与成立条件**：

API 26 工程；目标 Button 已有可见文本"提交订单"，属就地修改既有文本组件场景。

```ts
@Entry
@Component
struct B03SubmitOrder {
  build() {
    Column({ space: 24 }) {
      Text('B03 有文本的提交订单按钮')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 8 }) {
        Text('商品：无线蓝牙耳机 x1')
          .fontSize(16)
        Text('合计：99 元')
          .fontSize(16)
          .fontColor('#e84030')
      }
      .alignItems(HorizontalAlign.Start)
      Button('提交订单')
        .width('60%')
        .onClick(() => { /* 提交订单 */ })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 就地落地 Button `.accessibilityText('支付 99 元')`，保留原有属性/事件链；输出中重申覆盖语义：设置后原文本"提交订单"不再播报
- 文案符合 A/B 职责边界自检：text 只表达"是什么"，不混入操作引导与状态信息（如开发者后续有操作后果诉求，可顺带提示归 description）

**应包含**：不再播报, accessibilityText, 支付 99 元


---

### 测试用例：FUNC-TEXT-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

把播放器页面里唯一的那个播放图片按钮，改成读屏播报'播放'。

**业务场景与成立条件**：

API 26 工程；目标 Image 已带完整属性链（id/尺寸/圆角/背景/边距/onClick），验证就地追加模式。

```ts
@Entry
@Component
struct Player {
  @State isPlaying: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B12 播放器页面')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(this.isPlaying ? '正在播放' : '已暂停')
        .fontSize(16)
        .fontColor('#666666')
      Image($r('app.media.play'))
        .id('playIcon')
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor('#f0f0f0')
        .margin({ top: 24 })
        .onClick(() => {
          this.isPlaying = !this.isPlaying;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 就地模式：在原属性链上追加 `.accessibilityText('播放')`，保留既有 id、尺寸、圆角、背景、边距与 onClick
- 附改动说明与 A 类路由依据，不改无关文件

**应包含**：accessibilityText, playIcon


---

### 测试用例：FUNC-TEXT-004

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这个'提交订单'按钮之前配过读屏文案和提示说明，现在为什么没有系统默认的读文本和操作提示了？

**业务场景与成立条件**：

API 26 工程；页面现场已同时设置 accessibilityText 与 accessibilityDescription，属覆盖/替代语义答疑。

```ts
@Entry
@Component
struct B15OverrideQuery {
  build() {
    Column({ space: 24 }) {
      Text('B15 已设置 text 与 description 的组件')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Button('提交订单')
        .accessibilityText('支付 99 元')
        .accessibilityDescription('单指双击即可提交订单并完成支付')
        .onClick(() => { /* 提交订单 */ })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 解释覆盖语义：accessibilityText 不为空时原文本"提交订单"不再播报，读屏只播"支付 99 元"
- 解释替代语义：accessibilityDescription 替代系统默认新手提醒；用户关闭新手提醒开关后 description 也不播报
- 给出恢复默认（删除两个属性）或调整文案的建议；答疑不强制改动代码

**应包含**：不再播报, 新手提醒


---

### 测试用例：FUNC-DESC-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这个全屏按钮聚焦时只播'单指双击即可执行'，不易理解，用户根本不知道点了会进入全屏，请帮我为这个按钮添加操作说明。

**业务场景与成立条件**：

API 26 工程（description 下限 10，满足）；诉求为按钮添加操作说明（B 类路由）。

```ts
@Entry
@Component
struct B04FullScreen {
  build() {
    Column({ space: 24 }) {
      Text('B04 全屏按钮')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Button()
        .background(Color.Blue)
        .width(120)
        .height(48)
        .onClick(() => { /* 全屏逻辑 */ })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 路由 B 类：给出 `.accessibilityDescription(...)`（如"单指双击即可全屏"）说明操作后果，并说明其在文本后播报、替代系统默认新手提醒
- 目标 Button 无可见文本，允许同时补充 `accessibilityText` 表用途（A+B 组合），但"点了会怎样"必须由 description 承担

**应包含**：accessibilityDescription, 全屏


---

### 测试用例：FUNC-TEXT-DESC-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这个点赞图标既没有文字说明是什么，聚焦时也听不出点了会发生什么，两个都帮我补上。

**业务场景与成立条件**：

API 26 工程；A+B 组合诉求，一次落齐不留半成品。

```ts
@Entry
@Component
struct B21IconAction {
  @State liked: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B21 点赞图标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text('《无障碍设计实践指南》')
        .fontSize(16)
      Image($r('app.media.like'))
        .width(48)
        .height(48)
        .fillColor(this.liked ? Color.Red : Color.Gray)
        .onClick(() => {
          this.liked = !this.liked;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- A+B 组合一次落齐：`.accessibilityText('点赞')` + `.accessibilityDescription(...)`（如"单指双击即可点赞"）
- 职责分工正确：text=是什么、description=操作后果；组合诉求不拆开部分落地

**应包含**：accessibilityText, accessibilityDescription


---

### 测试用例：FUNC-GROUP-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

日期是年、月、日三段文字，读屏要分别聚焦三次才能听完，太碎了，能不能一次读完？帮我改好。

**业务场景与成立条件**：

API 26 工程；三个同语义 Text 的容器聚合场景。

```ts
@Entry
@Component
struct B05DateGroup {
  build() {
    Column({ space: 24 }) {
      Text('B05 日期三段文本')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column() {
        Text('2026年')
          .fontSize(24)
        Text('1月27日')
          .fontSize(24)
        Text('星期二')
          .fontSize(24)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 在父容器上设置 `.accessibilityGroup(true)`，说明容器成为单一聚焦单元、子 Text 拼接播报不再分别聚焦
- 不给组内每个 Text 单独加 accessibilityText 作为"聚合"方案
- 说明组播报文本优先级：用户设置文本优先，否则组内文本聚合

**应包含**：accessibilityGroup


---

### 测试用例：FUNC-GROUP-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

把生日的三段文字合成一次播报，但年份那段还要能单独聚焦并念'出生年份'，帮我改好。

**业务场景与成立条件**：

API 26 工程；C+D+A 组合诉求：聚合 + 组内例外朗读。

```ts
@Entry
@Component
struct B14Birthday {
  build() {
    Column({ space: 24 }) {
      Text('B14 生日三段文本')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 4 }) {
        Text('2010年')
          .fontSize(24)
        Text('8月')
          .fontSize(24)
        Text('15日')
          .fontSize(24)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- C+D+A 组合一次落齐：容器 `.accessibilityGroup(true)` + 年份 `.accessibilityLevel('yes')`（反 group 例外）+ 年份 `.accessibilityText('出生年份')`
- 说明 level 是 group 的反操作维度，年份恢复单独聚焦
- 年份设置 text 前提示覆盖语义（设置后原文本"2010年"不再播报）

**应包含**：accessibilityGroup, accessibilityLevel, 出生年份


---

### 测试用例：FUNC-GROUP-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

商品卡片聚合播报时，我不想让它把子文本一段一段拼起来，要直接读完整一句'华为手机，4999 元，已售 1024 件'，帮我适配

**业务场景与成立条件**：

API 26 工程；聚合后需自定义组播报文本的场景。

```ts
@Entry
@Component
struct B22ProductCard {
  build() {
    Column({ space: 24 }) {
      Text('B22 商品卡片')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 6 }) {
        Text('华为手机')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('¥4999')
          .fontSize(20)
          .fontColor('#e84030')
        Text('已售 1024 件')
          .fontSize(14)
          .fontColor('#666666')
      }
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => { /* 进入商品详情 */ })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 容器 `.accessibilityGroup(true)` + `.accessibilityText('华为手机，4999 元，已售 1024 件')`
- 说明组文本优先级：容器自身用户文本优先于组内文本聚合
- 说明容器设置 text 后子文本聚合不再播报的覆盖关系

**应包含**：accessibilityGroup, 华为手机


---

### 测试用例：FUNC-LEVEL-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

页头那个纯装饰的小圆点图标不要读出来，但它下面的返回按钮必须保留能读；还有下面那个三方内容区和它里面所有东西都不要读，帮我处理。

**业务场景与成立条件**：

API 26 工程；确定性隐藏/聚焦诉求，考验 level 三值语义区分。

```ts
@Entry
@Component
struct B06DecorHeader {
  build() {
    Column({ space: 24 }) {
      Text('B06 装饰图标与三方容器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row({ space: 12 }) {
        Image($r('app.media.decor'))
          .width(120)
          .height(24)
        Text('页面标题')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('90%')

      Button('返回')
        .fontSize(14)
        .width(96)
        .onClick(() => { /* 返回上一页 */ })

      Column({ space: 8 }) {
        Image($r('app.media.decor'))
          .width(200)
          .height(40)
        Text('三方推广位标题')
          .fontSize(16)
        Text('点击进入三方活动页面')
          .fontSize(12)
          .fontColor('#666666')
      }
      .padding(12)
      .borderRadius(12)
      .backgroundColor('#f5f5f5')
      .width('90%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 装饰 Image `.accessibilityLevel('no')`（只隐藏当前节点）；三方容器 `.accessibilityLevel('no-hide-descendants')`（连同后代隐藏）
- 返回按钮两种处理均可接受：显式 `.accessibilityLevel('yes')` 强制可识别，或明确说明其默认已可朗读、无需改动
- 确定性隐藏诉求不输出 auto 方案；说明 no 与 no-hide-descendants 的差异（是否连同后代）

**应包含**：no-hide-descendants


---

### 测试用例：FUNC-CHECKED-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

页面里的开关和标签页，读屏听不出当前开的是哪个、选中的是哪个，是不是都标记成'勾选状态'就行了？帮我适配。

**业务场景与成立条件**：

API 26 工程；含 Toggle（物理状态）与 Tabs（互斥单选）两类组件，开发者存在"都标勾选"的误用思路。

```ts
@Entry
@Component
struct B07CheckedAndTabs {
  @State isOn: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B07 开关与标签页')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Row({ space: 12 }) {
        Text('消息通知')
          .fontSize(16)
        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .onChange((value: boolean) => {
            this.isOn = value;
          })
      }

      Tabs() {
        TabContent() {
          Text('首页内容区域').fontSize(16)
        }
        .tabBar('首页')

        TabContent() {
          Text('推荐内容区域').fontSize(16)
        }
        .tabBar('推荐')

        TabContent() {
          Text('我的内容区域').fontSize(16)
        }
        .tabBar('我的')
      }
      .width('90%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 纠正"都标勾选"的误用：Toggle 物理状态用 `.accessibilityChecked(this.isOn)`；TabContent 互斥单选用 `.accessibilitySelected(...)`，不混用
- 附 checked/selected 对比表（语义目标、常见场景、典型组件）
- 状态随 @State 切换同步；Tabs 需配套 onChange/currentIndex 状态源

**应包含**：accessibilityChecked, accessibilitySelected


---

### 测试用例：FUNC-CHECKED-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

给工程里的复选框加上选中状态播报。

**业务场景与成立条件**：

API 26 工程（checked/selected 下限 13，三字段满足放行）；两个未受控 Checkbox。

```ts
@Entry
@Component
struct B08Checkbox {
  build() {
    Column({ space: 20 }) {
      Text('B08 复选框')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row({ space: 8 }) {
        Checkbox({ name: 'agree', group: 'licenseGroup' })
          .width(24)
          .height(24)
        Text('我已阅读并同意用户协议')
          .fontSize(16)
      }
      Row({ space: 8 }) {
        Checkbox({ name: 'subscribe', group: 'licenseGroup' })
          .width(24)
          .height(24)
        Text('订阅产品动态消息')
          .fontSize(16)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 版本门禁：说明 checked/selected 需 API 13+ 并核对工程版本；仅有代码片段、无工程上下文时，以"需确认 build-profile 三字段 ≥13"的提示形式替代实际读取
- 选中状态挂 `.accessibilityChecked(...)` 并与状态源联动：`@State` + `.onChange()` 同步；推荐补受控 `.select(state)` 三要素完整形态
- Checkbox 无 onSelect 方法，状态同步一律用 onChange（不给 .onSelect 写法）

**应包含**：accessibilityChecked, onChange
**不应包含**：.onSelect(


---

### 测试用例：FUNC-CHECKED-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这个收藏图标没有文字读不出用途，另外还要让读屏知道当前是否已收藏，两个问题一起帮我适配。

**业务场景与成立条件**：

API 26 工程；A+E 正交组合诉求。

```ts
@Entry
@Component
struct B09FavoriteIcon {
  @State isFavorite: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B09 无文字收藏图标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text('蓝牙音箱 Hi-Fi 版')
        .fontSize(18)
      Image($r('app.media.favorite'))
        .width(48)
        .height(48)
        .fillColor(this.isFavorite ? Color.Orange : Color.Gray)
        .onClick(() => {
          this.isFavorite = !this.isFavorite;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- A+E 组合一次落齐：`.accessibilityText('收藏')` + `.accessibilityChecked(this.isFavorite)`
- 正交分工：text 传用途、checked 传状态，状态不塞进 text
- 先过 E 的版本门（13+）；不误用 selected

**应包含**：accessibilityText, accessibilityChecked


---

### 测试用例：FUNC-CHECKED-004

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

主题选择列表，读屏用户听不出当前选的是哪个主题，帮我适配。

**业务场景与成立条件**：

API 26 工程；List 实现的互斥单选，视觉用"✓"与高亮标识当前项。

```ts
@Entry
@Component
struct B23ThemeList {
  @State selectedIndex: number = 0;
  private themes: string[] = ['浅色模式', '深色模式', '跟随系统'];

  build() {
    Column({ space: 24 }) {
      Text('B23 主题单选列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      List({ space: 8 }) {
        ForEach(this.themes, (theme: string, index: number) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(theme)
                .fontSize(16)
                .layoutWeight(1)
              if (this.selectedIndex === index) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#007dfe')
              }
            }
            .padding(14)
            .borderRadius(10)
            .backgroundColor(this.selectedIndex === index ? '#eef5ff' : '#f5f6f7')
            .onClick(() => {
              this.selectedIndex = index;
            })
          }
        }, (theme: string) => theme)
      }
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- List 单选场景：在项容器 Row 上设置 `.accessibilitySelected(this.selectedIndex === index)`，与视觉"✓"/高亮同一焦点单元
- 状态随点击 @State 同步；不误用 checked（互斥单选不用物理状态属性）

**应包含**：accessibilitySelected


---

### 测试用例：FUNC-VNODE-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

用 Canvas 画的折线图读屏完全读不到，请让读屏能读出当前的数据趋势，帮我实现。

**业务场景与成立条件**：

API 26 工程（virtualNode 下限 11，满足放行）；Canvas 绘制近 7 日销量折线（30/58/42/80/65/92/74）。

```ts
@Entry
@Component
struct B10LineChart {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private data: number[] = [30, 58, 42, 80, 65, 92, 74];

  build() {
    Column({ space: 24 }) {
      Text('B10 Canvas 折线图')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width('90%')
        .height(260)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 3;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          for (let i = 0; i < this.data.length; i++) {
            let x: number = 24 + i * 44;
            let y: number = 230 - this.data[i] * 2;
            if (i === 0) {
              this.context.moveTo(x, y);
            } else {
              this.context.lineTo(x, y);
            }
          }
          this.context.stroke();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 路由 F 类并先版本检查（virtualNode 需 11+，本工程满足）
- 定义 @Builder 语义节点承载趋势描述（如"近 7 日销量折线图，整体呈上升趋势，最高 92"），Canvas 挂 `.accessibilityVirtualNode(this.customAccessibilityNode)`
- builder 以方法引用直传；禁止 lambda 包裹与 `{ builder: ... }` 对象包裹（两种写法均编译报错）
- builder 内容为**单个 Text 直述**（默认播报即可，不叠加 accessibilityText/不套容器 group）
- 说明辅助工具读取虚拟节点语义而非绘制内容；保留原有绘制逻辑不变

**应包含**：accessibilityVirtualNode, @Builder
**不应包含**：`.accessibilityGroup(true)`（builder 语义节点内）、builder 语义节点内 Text 叠加 `.accessibilityText(` 的组合（合并文本丢弃子无障碍文本，vod-5）


---

### 测试用例：FUNC-VNODE-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

给自绘的仪表盘加上读屏能读的内容。

**业务场景与成立条件**：

API 26 工程；Canvas 绘制转速仪表盘（当前 2450 rpm）。

```ts
@Entry
@Component
struct B11Dashboard {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column({ space: 24 }) {
      Text('B11 自绘仪表盘')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width(320)
        .height(300)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 14;
          this.context.strokeStyle = '#e0e0e0';
          this.context.beginPath();
          this.context.arc(160, 150, 100, Math.PI * 0.75, Math.PI * 2.25);
          this.context.stroke();
          this.context.lineWidth = 14;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          this.context.arc(160, 150, 100, Math.PI * 0.75, Math.PI * 1.45);
          this.context.stroke();
          this.context.fillStyle = '#333333';
          this.context.font = '32px sans-serif';
          this.context.fillText('2450 rpm', 108, 165);
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 版本检查（11+）后输出 @Builder 语义节点（如"仪表盘：当前转速 2450 转/分"）+ Canvas `.accessibilityVirtualNode(this.customAccessibilityNode)`
- builder 方法引用直传约束同 FUNC-VNODE-001
- builder 内容为**单个 Text 直述**（默认播报即可，不叠加 accessibilityText/不套容器 group），约束同 FUNC-VNODE-001
- 绘制逻辑保持不变

**应包含**：accessibilityVirtualNode
**不应包含**：同 FUNC-VNODE-001（lambda/对象包裹；builder 语义节点内 group(true)+子 accessibilityText 组合）


---

### 测试用例：FUNC-VNODE-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

给自绘的仪表盘加上读屏能读的内容，希望聚焦一次就能听完整描述。

**业务场景与成立条件**：

API 26 工程；Canvas 转速仪表盘（当前 2450 rpm），代码内联如下。本题考察"一次听完"诉求下
是否误用"容器 group(true) + 子 accessibilityText"组合（该组合合并文本只拼子组件通用文本，
无障碍文本被丢弃，播报残缺——vod-5 隐蔽陷阱）。

```ts
@Entry
@Component
struct B11Dashboard {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  build() {
    Column({ space: 24 }) {
      Text('B11 自绘仪表盘')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width(320)
        .height(300)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 14;
          this.context.strokeStyle = '#e0e0e0';
          this.context.beginPath();
          this.context.arc(160, 150, 100, Math.PI * 0.75, Math.PI * 2.25);
          this.context.stroke();
          this.context.lineWidth = 14;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          this.context.arc(160, 150, 100, Math.PI * 0.75, Math.PI * 1.45);
          this.context.stroke();
          this.context.fillStyle = '#333333';
          this.context.font = '32px sans-serif';
          this.context.fillText('2450 rpm', 108, 165);
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 基线方案：builder 内**单个 Text 直述完整描述**（如"仪表盘：当前转速 2450 转每分钟"），
  一次聚焦一次播报，天然满足"听完整描述"，无需任何容器/无障碍属性
- 若输出分组方案，必须使用 `.accessibilityGroup(true, { accessibilityPreferred: true })`，
  并说明默认合并文本只拼子组件通用文本、不使用子无障碍文本的陷阱（vod-5）
- builder 方法引用直传约束同 FUNC-VNODE-001

**应包含**：accessibilityVirtualNode
**不应包含**：builder 语义节点内 `.accessibilityGroup(true)` 且不带 `accessibilityPreferred` 的分组写法


---

### 测试用例：FUNC-EVENT-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

这张卡片，读屏用户单指摸到时希望能预览详情（展开），焦点进入时展开、焦点离开时收起，帮我实现。

**业务场景与成立条件**：

API 26 工程；hover（12+）与 focus（18+）事件组合，工程版本均满足。

```ts
@Entry
@Component
struct B13FocusCard {
  @State expanded: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B13 可聚焦卡片')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 8 }) {
        Text('张三')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('前端开发工程师 · 工号 1024')
          .fontSize(14)
          .fontColor('#666666')
        if (this.expanded) {
          Text('详细信息：负责 ArkUI 无障碍能力建设，联系方式 zhangsan@example.com')
            .fontSize(14)
            .fontColor('#666666')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .width('85%')
      .onClick(() => {
        this.expanded = !this.expanded;
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- hover+focus 组合：`.onAccessibilityHover((isHover: boolean, event: AccessibilityHoverEvent) => {...})` 双参签名，isHover=true 展开 / false 收起；单参数 `(event)` 写法编译报错，不给
- `.onAccessibilityFocus((isFocus: boolean) => {...})` 实现焦点进入展开、离开收起
- hover 12+、focus 18+ 逐方法标注版本（满足版本时软提示即可）；触摸/预览诉求用 hover、聚焦移入移出用 focus，不混用；说明属性与事件回调可叠加

**应包含**：onAccessibilityHover, onAccessibilityFocus


---

### 测试用例：FUNC-FOCUS-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

搜索页里搜索输入框是核心组件，希望进入页面后读屏第一个聚焦、第一个朗读的就是它，帮我实现。

**业务场景与成立条件**：

API 26 工程（defaultFocus 下限 18，满足）；G 类首焦点诉求。

```ts
@Entry
@Component
struct B16DefaultFocus {
  build() {
    Column({ space: 16 }) {
      Text('B16 商品搜索')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '请输入要搜索的商品' })
        .width('85%')
      List({ space: 8 }) {
        ListItem() {
          Text('商品 A - 已售 1024').fontSize(16)
        }
        ListItem() {
          Text('商品 B - 已售 512').fontSize(16)
        }
        ListItem() {
          Text('商品 C - 已售 256').fontSize(16)
        }
      }
      .width('85%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- G 类首焦点：TextInput `.accessibilityDefaultFocus(true)`，页面进入后读屏首次聚焦该组件
- 说明与 accessibilityNextFocusId 的语义差异（默认/首个焦点 vs 指定下一焦点）
- 18+ 版本软提示（满足版本不阻断）

**应包含**：accessibilityDefaultFocus


---

### 测试用例：FUNC-FOCUS-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

姓名输入框聚焦后，希望下一个聚焦的是手机号输入框而不是默认的邮箱，帮我实现。

**业务场景与成立条件**：

API 26 工程（nextFocusId 下限 18，满足）；表单默认走焦顺序为姓名→邮箱→手机号。

```ts
@Entry
@Component
struct B17NextFocus {
  build() {
    Column({ space: 16 }) {
      Text('B17 注册表单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '姓名' })
        .width('85%')
      TextInput({ placeholder: '邮箱' })
        .width('85%')
      TextInput({ placeholder: '手机号' })
        .width('85%')
      Button('注册')
        .width('60%')
        .onClick(() => { /* 注册逻辑 */ })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 姓名 TextInput 挂 `.accessibilityNextFocusId(<目标id>)`，值为目标组件 id（string）；**id 命名不限定具体字符串**，与组件语义匹配即可（如 phone_input/phoneId 等均可）
- 手机号 TextInput 配套 `.id(<同一id>)`，与 accessibilityNextFocusId 指向值**一致**，走焦功能生效
- **仅目标组件加 `.id()`**，源组件（姓名输入框）不加 id（代码简约性，vod-6）
- 18+ 版本软提示

**应包含**：accessibilityNextFocusId
**不应包含**：源组件（姓名输入框）上新增的 `.id(`


---

### 测试用例：FUNC-FOCUS-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

搜索框聚焦后，希望下一个焦点进入会员卡片里面的子内容，帮我实现。

**业务场景与成立条件**：

API 26 工程；isConsiderDescendants 为 API 26+，需进入目标子节点的参与模式。

```ts
@Entry
@Component
struct B18NextFocusChild {
  build() {
    Column({ space: 16 }) {
      Text('B18 下一焦点进入子节点')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '搜索' })
        .width('85%')
      Column({ space: 8 }) {
        Text('会员卡片')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Button('领取会员权益')
          .fontSize(14)
        Text('会员有效期至 2027-12-31')
          .fontSize(14)
          .fontColor('#666666')
      }
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .width('85%')
      .alignItems(HorizontalAlign.Start)
      Button('下一步')
        .width('60%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 搜索框 `.accessibilityNextFocusId(<目标id>, { isConsiderDescendants: true })` + 会员卡片容器 `.id(<同一id>)`；**id 命名不限定具体字符串**，与组件语义匹配且两处一致（走焦功能生效）即可
- true 表示下一焦点考虑目标节点的子节点（进入子内容）；true 为**非默认值**（默认 false），显式传入合理
- **仅目标容器加 `.id()`**，源组件（搜索框）不加 id（代码简约性，vod-6）
- 说明版本差异：基础属性 18+、isConsiderDescendants 26+

**应包含**：isConsiderDescendants
**不应包含**：源组件（搜索框）上新增的 `.id(`


---

### 测试用例：FUNC-FOCUS-004

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

搜索框聚焦后，希望下一个焦点跳过会员卡片里的子内容、直接到'下一步'按钮，帮我实现。

**业务场景与成立条件**：

API 26 工程；跳过目标子节点为 isConsiderDescendants **默认行为**（默认 false，无需传参）；页面结构与 FUNC-FOCUS-003 相同（搜索框 + 会员卡片 + 下一步按钮）。本题考察默认值不显式传与源组件不加 id 的代码简约性（vod-6）。

```ts
@Entry
@Component
struct B19NextFocusSkipChild {
  build() {
    Column({ space: 16 }) {
      Text('B19 下一焦点跳过子节点')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '搜索' })
        .width('85%')
      Column({ space: 8 }) {
        Text('会员卡片')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Button('领取会员权益')
          .fontSize(14)
        Text('会员有效期至 2027-12-31')
          .fontSize(14)
          .fontColor('#666666')
      }
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .width('85%')
      .alignItems(HorizontalAlign.Start)
      Button('下一步')
        .width('60%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 搜索框（源组件）仅挂 `.accessibilityNextFocusId(<目标id>)`，**不传第二参数**——跳过目标子节点是 isConsiderDescendants 默认行为（默认 false）
- 下一步按钮（目标组件）配套 `.id(<同一id>)`，与指向值一致（走焦功能生效）；**id 命名不限定具体字符串**，与组件语义匹配即可；**仅目标组件加 `.id()`**，源组件（搜索框）不加 id（vod-6）
- 说明默认行为语义：下一焦点落到目标本身、不进入其子节点；与 FUNC-FOCUS-003 的 true 模式（进入子节点）语义相反，不混淆
- 显式传 `{ isConsiderDescendants: false }` 属与默认值一致的冗余参数，不生成（代码简约性）

**应包含**：accessibilityNextFocusId
**不应包含**：`isConsiderDescendants: false`（默认值冗余）、源组件（搜索框）上新增的 `.id(`


---

### 测试用例：FUNC-EVENT-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

质检卡片被读屏用户摸到时，希望卡片上的文字自动变成'已检查完成'，怎么做？帮我实现。

**业务场景与成立条件**：

API 26 工程（hover 下限 12，满足）；触摸时更新 @State 文案。

```ts
@Entry
@Component
struct B20HoverText {
  @State message: string = '待检查';

  build() {
    Column({ space: 24 }) {
      Text('B20 触摸改文案')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 8 }) {
        Text('质检工位 03')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(this.message)
          .fontSize(20)
          .fontColor('#007dfe')
      }
      .padding(24)
      .borderRadius(12)
      .backgroundColor('#f0f6ff')
      .onClick(() => {
        this.message = '已检查完成';
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 卡片挂 `.onAccessibilityHover((isHover: boolean, event: AccessibilityHoverEvent) => {...})` 双参签名，isHover=true 时更新 `this.message = '已检查完成'`
- 单参数 `(event)` 写法编译报错，不给
- 说明触发条件为开启无障碍后的单指触摸，hover 需 12+

**应包含**：onAccessibilityHover, 已检查完成


---

### 测试用例：FUNC-VERSION-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

给工程里的复选框加上选中状态播报。

**业务场景与成立条件**：

低版本工程：`build-profile.json5` 中 `compatibleSdkVersion = "4.0.0(10)"`、`targetSdkVersion = "26.0.0"`；页面为两个未受控 Checkbox（代码内联如下）。checked/selected 下限 API 13。

```ts
@Entry
@Component
struct B08Checkbox {
  build() {
    Column({ space: 20 }) {
      Text('B08 复选框')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row({ space: 8 }) {
        Checkbox({ name: 'agree', group: 'licenseGroup' })
          .width(24)
          .height(24)
        Text('我已阅读并同意用户协议')
          .fontSize(16)
      }
      Row({ space: 8 }) {
        Checkbox({ name: 'subscribe', group: 'licenseGroup' })
          .width(24)
          .height(24)
        Text('订阅产品动态消息')
          .fontSize(16)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 版本门禁阻断：说明 accessibilityChecked/Selected 需 API 13+，当前 compatibleSdkVersion=10 低于下限
- 给出版本提升建议
- 不生成 checked/select/onChange 等属性代码（**含"方案示意""仅供参考"形式的代码块**；阻断≠报错，是主动拦截，页面零改动保持可编译）

**应包含**：compatibleSdkVersion, 13


---

### 测试用例：FUNC-VERSION-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

用 Canvas 画的折线图读屏完全读不到，请让读屏能读出当前的数据趋势，帮我实现。

**业务场景与成立条件**：

低版本工程：`build-profile.json5` 中 `compatibleSdkVersion = "4.0.0(10)"`、`targetSdkVersion = "26.0.0"`；页面为 Canvas 折线图（代码内联如下）。virtualNode 下限 API 11，为最小版本差边界（10 < 11），最易误放行。

```ts
@Entry
@Component
struct B10LineChart {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private data: number[] = [30, 58, 42, 80, 65, 92, 74];

  build() {
    Column({ space: 24 }) {
      Text('B10 Canvas 折线图')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width('90%')
        .height(260)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 3;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          for (let i = 0; i < this.data.length; i++) {
            let x: number = 24 + i * 44;
            let y: number = 230 - this.data[i] * 2;
            if (i === 0) {
              this.context.moveTo(x, y);
            } else {
              this.context.lineTo(x, y);
            }
          }
          this.context.stroke();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 版本门禁阻断：说明 accessibilityVirtualNode 需 API 11+，当前 10 < 11（最小差边界不放行）
- 给出版本提升建议
- 不生成 virtualNode/@Builder 相关代码（**含"方案示意""仅供参考""版本就绪后可用"等形式的代码块**），页面保持原始态可编译

**应包含**：compatibleSdkVersion, 11


---

### 测试用例：FUNC-QA-001

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

我想先了解一下，ArkUI 现在都支持哪些无障碍能力？有没有一个整体介绍？

**业务场景与成立条件**：

普通 ArkTS 工程（API 26，如 Accessibility-before）；开发者纯知识询问平台能力全景，未指定任何待适配组件或页面。知识问答模式不依赖工程上下文（验证 Skill 不读取工程文件）。

#### 预期输出

**验证标准**：

- 进入知识问答模式（Q 类）：不读取工程文件（含 build-profile.json5）、不做版本门禁、不进入第 0~6 步适配流程
- 先说明默认使能能力：屏幕朗读四要素（组件类型、文本内容、操作结果、当前状态），有文本内容的标准组件免适配
- 再按能力类别给出需主动适配清单：播报内容 / 聚合与可见性 / 状态语义 / 自绘与走焦 / 交互行为 / 事件回调 / 动态播报，逐项含接口名与下限 API
- 清单口径与 `references/api-facts.md` 能力总览一致（含路由表未覆盖的 accessibilityRole、accessibilityCustomActions 等）
- 零适配代码输出

**应包含**：组件类型, accessibilityText
**不应包含**：compatibleSdkVersion


---

### 测试用例：FUNC-QA-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

无障碍这块，哪些能力是系统默认就开启的？哪些是需要我自己写代码适配的？

**业务场景与成立条件**：

同 FUNC-QA-001（纯知识询问默认使能与主动适配边界，不依赖工程上下文）。

#### 预期输出

**验证标准**：

- 知识问答模式两栏对照作答：默认使能 vs 需主动适配
- 默认侧完整给出四要素与"有文本内容的标准组件零属性免适配"结论
- 主动适配侧按能力类别列接口清单（属性/事件/动态播报），含接口名与下限 API
- 零适配代码输出、零工程文件读取

**应包含**：组件类型, 文本内容, 操作结果, 当前状态, accessibilityGroup
**不应包含**：compatibleSdkVersion


---

### 测试用例：FUNC-QA-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

accessibilityText 是干什么的？什么场景下需要用它？

**业务场景与成立条件**：

纯知识询问具体属性语义；未提供待改组件代码，不依赖工程上下文。

#### 预期输出

**验证标准**：

- 知识问答模式四元组作答：签名（`value: string | Resource`）/ 下限 API 12 / 关键语义（无障碍播报文本，表达"是什么"）/ 关联场景（A 类：无文本元素读不出用途）或深读文档指引
- 覆盖语义陷阱必答：设置后原文本不再播报（accessibilityText 不为空时优先于显示文本）；默认值为空字符串
- 允许一行级内联用法示意（如 `.accessibilityText('播放')`），不输出完整适配方案或多行代码
- 下限 API 12 仅为事实陈述，不发起工程版本判定或版本追问

**应包含**：不再播报, 12
**不应包含**：compatibleSdkVersion


---

### 测试用例：FUNC-QA-004

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

accessibilityChecked 和 accessibilitySelected 这两个属性长得很像，到底有什么区别？

**业务场景与成立条件**：

纯知识询问两个状态属性的差异；未提供待改组件代码，不依赖工程上下文。

#### 预期输出

**验证标准**：

- 知识问答模式作答，语义对比准确：checked=控件物理选中状态（二态/三态，Checkbox、Toggle）；selected=互斥单选当前项（List、Tabs），二者不混用
- 下限 API 均为 13（仅为事实陈述）
- 可按关键维度对比（语义目标/典型组件/挂载位置/undefined 行为），与 decision-matrix 口径一致
- 零适配代码输出、零工程文件读取

**应包含**：物理状态, 单选, 13
**不应包含**：compatibleSdkVersion


---

### 测试用例：FUNC-QA-005

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

accessibilityVirtualNode 是怎么用的？顺便帮我把这个 Canvas 折线图也加上读屏内容。

**业务场景与成立条件**：

API 26 工程（如 Accessibility-before，virtualNode 下限 11，满足放行）；输入**混合**知识问句（virtualNode 用法）与明确适配诉求（B10 折线图加读屏内容）。

```ts
@Entry
@Component
struct B10LineChart {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private data: number[] = [30, 58, 42, 80, 65, 92, 74];

  build() {
    Column({ space: 24 }) {
      Text('B10 Canvas 折线图')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Canvas(this.context)
        .width('90%')
        .height(260)
        .backgroundColor('#f1f2f3')
        .onReady(() => {
          this.context.lineWidth = 3;
          this.context.strokeStyle = '#007dfe';
          this.context.beginPath();
          for (let i = 0; i < this.data.length; i++) {
            let x: number = 24 + i * 44;
            let y: number = 230 - this.data[i] * 2;
            if (i === 0) {
              this.context.moveTo(x, y);
            } else {
              this.context.lineTo(x, y);
            }
          }
          this.context.stroke();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- **混合输入拆分处理**：知识部分按知识问答口径作答——签名（@Builder 方法引用直传，禁 lambda/对象包裹）/ 下限 API 11 / 关键语义（辅助工具读取虚拟节点语义而非绘制内容）/ builder 内单个 Text 直述基线
- 适配部分进入核心工作流：读取 build-profile.json5 三字段做版本门禁（本工程满足 11+ 放行）
- 落地：@Builder 单 Text 语义节点（如"近 7 日销量折线图，整体呈上升趋势，最高 92"）+ Canvas `.accessibilityVirtualNode(this.customAccessibilityNode)`，保留原有绘制逻辑
- 知识段的"下限 API 事实陈述"与适配段的"工程实际版本判定"区分清晰

**应包含**：accessibilityVirtualNode, @Builder, 11
**不应包含**：lambda 包裹（`() => { this.`）、builder 语义节点内 `.accessibilityGroup(true)` 且不带 accessibilityPreferred 的组合写法（同 FUNC-VNODE-001）


---

### 测试用例：FUNC-DESC-002

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

我的Text组件中播报的内容随状态变量isDownloading的改变而改变，我希望仅在isDownloading为false时，Text播报"下载文件"时播报点击事件自带的"单指双击即可执行"。若isDownloading为true，Text播报内容为"文件已下载"时则不播报"单指双击即可执行"。请帮我处理。

**业务场景与成立条件**：

API 26 工程（`Accessibility-before`，页面 B24DownloadState.ets，代码同下）；Text 显示文本随 `@State isDownloading` 三元切换（"下载文件"/"文件已下载"），Text 挂 onClick（vod-7 场景）。

```ts
@Entry
@Component
struct B24DownloadState {
  @State isDownloading: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text(this.isDownloading ? '文件已下载' : '下载文件')
        .onClick(() => {
          // 下载文件操作
        })

      Button('修改下载状态')
        .onClick(() => {
          this.isDownloading = this.isDownloading ? false : true;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

#### 预期输出

**验证标准**：

- 识别 B 类变体（操作提示动态开关，vod-7）：说明规格——description 非空串时替代系统默认新手提醒"单指双击即可执行"，空串（默认值）时保留默认播报
- 落地 `.accessibilityDescription(this.isDownloading ? ' ' : '')`：isDownloading=true 传空格（非空，替代后不再播报"单指双击即可执行"），false 传空串（走默认提示）
- 保留原 Text/onClick/Button 逻辑不变
- **空串分支不得按简约性删除**：条件分支中的默认值取值是"恢复默认操作提示"的行为开关（api-facts 默认值清单"动态分支例外"）

**应包含**：accessibilityDescription
**不应包含**：accessibilityChecked


---

### 测试用例：FUNC-TEXT-005

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

在B25PageTwo有两个组件，一个Text，一个Button，有时候焦点会自动跳到第二个焦点，忽略第一个焦点，我不想让它自动跳，请帮我处理。

**业务场景与成立条件**：

API 26 工程（`Accessibility-before`，页面 B25PageOne.ets / B25PageTwo.ets，代码同下，AppStorage key 为 `b25Content`）；B25PageTwo 的 Text 显示 `@StorageLink('b25Content') content`（B25PageOne 可将其置为空串）；content 为空串时读屏跳过 Text 直接聚焦 Button（vod-8 场景）。

```ts
// B25PageOne
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct B25PageOne {
  @StorageLink('b25Content') content: string = 'Text1';

  build() {
    Column({ space: 24 }) {
      Button('change content')
        .onClick(() => {
          this.content = '';
        })

      Button('go to next page').fontSize(30)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/B25PageTwo' }, (err: Error) => {
            if (err) {
              hilog.error(0x0000, 'test', 'pushUrl failed. Cause: %{public}s', JSON.stringify(err));
            }
          });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

// B25PageTwo
@Entry
@Component
struct B25PageTwo {
  @StorageLink('b25Content') content: string = '';

  build() {
    Column({ space: 24 }) {
      Text(`${this.content}`)
        .fontSize(50)
      Button('back')
        .onClick(() => {
          this.getUIContext().getRouter().back();
        })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 根因定位：显示文本为空串的 Text 无可播报内容，被读屏跳焦（非组件缺陷，与可识别性/走焦属性无关）
- 落地 B25PageTwo Text `.accessibilityText(this.content === '' ? ' ' : this.content)`：空串兜底空格保持可聚焦，非空原样传入
- 不改 B25PageOne、Button 与路由逻辑
- **兜底三元不得按简约性删除**（动态分支例外，vod-8）；不误路由 level('yes')/nextFocusId（根因是内容为空）

**应包含**：accessibilityText
**不应包含**：`.accessibilityLevel(`、`.accessibilityNextFocusId(`（正解为 text 空串兜底，非可识别性/走焦问题）


---

### 测试用例：FUNC-VERSION-003

**skill**：hmos-arkui-accessibility-skill
**类型**：functional（功能验证）

#### 输入

为什么这段代码在accessibilityGroup有编译报错？

```ts
@Entry
@Component
struct B26GroupRole {

  build() {
    Column({ space: 24 }) {
      Column() {
        Text('是否开始功能')
        Toggle({ type: ToggleType.Switch, isOn: false})
          .onChange((isOn: boolean) => {
            console.info('Component status: ' + isOn)
          })
      }
      .accessibilityGroup(true, {
        stateControllerRoleType: AccessibilityRoleType.TOGGLER,
        actionControllerRoleType: AccessibilityRoleType.TOGGLER
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

**业务场景与成立条件**：

答疑场景（vod-9，版本敏感）：**仅在 `Accessibility-api10-before` 工程执行**（compatibleSdkVersion 10，10 < 12 且 10 < 23 双重命中，真实复现编译报错前提；代码随输入内联不落页面，用例见该工程 `skill-eval-cases-api10-block.md` 第四节 B26）。`Accessibility-before` 工程（API 26）下同代码可正常编译、无法复现，不设此用例。

#### 预期输出

**验证标准**：

- 答疑定位（通用答疑模式）：group 本体 API 12+ 可用；options 参数 `stateControllerRoleType` / `actionControllerRoleType` **下限 API 23**——**参数版本独立于属性本体**（同类先例 isConsiderDescendants 26+）
- 读本工程 build-profile 三字段判定：10 < 12 且 10 < 23，该写法双重不满足 → 编译报错
- 修复建议：提升 compatibleSdkVersion（完整支持该写法需 23+，仅基础聚合能力至少 12+，版本串以官方 SDK 版本映射为准）；**不给"移除角色参数即可编译"的误导**（本体 12 仍拦截本工程）
- 零代码产出：不输出保留角色参数的"可用代码"，任何文件零改动，`AccessibilityRoleType` 不得出现在工程源文件

**应包含**：23, compatibleSdkVersion
