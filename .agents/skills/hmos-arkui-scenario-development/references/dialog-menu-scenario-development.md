# 弹窗/菜单等临时交互/提示界面案例集

---

## 弹窗进阶能力

## 功能点典型使用场景对比

| 弹窗类型 | 典型使用场景 | 核心能力 | 不适用场景 |
|---------|------------|---------|-----------|
| AlertDialog | 删除确认、退出登录、版本更新 | 系统固定样式+按钮回调 | 带图标列表选择、自定义内容 |
| ActionSheet | 分享渠道、消息操作、更换头像 | 底部列表选择+标题 | 日期选择、纯操作菜单 |
| 选择器弹窗 | 生日选择、时间预约、学历选择 | 滚轮选择器+范围控制 | 自由文本输入 |
| showDialog (promptAction) | 提交确认、文件覆盖、下一步 | Promise异步返回按钮索引 | 需要自定义样式 |
| showActionMenu (promptAction) | 编辑/删除/分享/收藏操作菜单 | 轻量纯操作菜单+Promise | 带消息说明的选择弹窗 |
| openCustomDialog (ComponentContent) | 倒计时广告、全局通知 | 动态更新弹窗内容+不依赖UI上下文 | 内容固定的简单弹窗 |
| @CustomDialog + CustomDialogController | 商品规格选择、服务条款、更新弹窗 | 自定义内容+父组件状态共享 | 需动态更新弹窗属性 |
| levelOrder | 多弹窗层级管理 | 控制弹窗间覆盖顺序 | 弹窗与页面的层级 |
| focusable:false | 搜索建议/联想词弹窗 | 弹窗不获取焦点不收键盘 | 需要弹窗内输入 |
| autoCancel/isModal/maskRect | 支付确认、非模态、局部蒙层引导 | 蒙层显隐/交互/区域控制 | 默认蒙层即可满足 |
| transition | 节日活动弹窗淡入/滑动 | 自定义过渡动画 | 默认动画即可满足 |

---

## 场景一：删除/退出等敏感操作二次确认

**场景示例描述**：用户执行删除文件、退出登录、清除数据等敏感操作时，需要二次确认防止误操作。

**解决方案**：使用 AlertDialog.show() 弹出固定样式的警告弹窗，设置 title、message 和确认/取消按钮。

```typescript
// 双按钮确认（primaryButton + secondaryButton）
this.getUIContext().showAlertDialog({
  title: '删除确认',
  message: '确定要删除该文件吗？删除后无法恢复。',
  primaryButton: { value: '取消', action: () => { /* ... */ } },
  secondaryButton: { value: '确定删除', fontColor: '#e74c3c', action: () => { /* ... */ } }
});

// 单按钮提示（confirm）
this.getUIContext().showAlertDialog({
  title: '网络错误',
  message: '网络连接失败，请检查网络设置后重试。',
  confirm: { value: '重试', action: () => { /* ... */ } }
});

// 三按钮变体（buttons 数组，最多3个）
this.getUIContext().showAlertDialog({
  title: '保存修改',
  message: '是否保存对文档的修改？',
  buttons: [
    { value: '不保存', fontColor: '#999', action: () => {} },
    { value: '取消', action: () => {} },
    { value: '保存', fontColor: '#007DFF', action: () => {} }
  ]
});
```

### AlertDialog 按钮配置

| 属性 | 按钮数量 | 适用场景 |
|------|---------|---------|
| `confirm` | 单按钮 | 仅需"知道了/重试"的提示 |
| `primaryButton` + `secondaryButton` | 双按钮 | 确认/取消二选一 |
| `buttons` | 多按钮（最多3个） | 不保存/取消/保存三选一 |

---

## 场景二：分享渠道列表选择

**场景示例描述**：用户点击分享按钮时，展示微信、QQ、微博等分享渠道列表供用户选择。

**解决方案**：使用 ActionSheet.show()，通过 sheets 数组配置各分享渠道的图标和标题。

```typescript
this.getUIContext().showActionSheet({
  title: '分享到',
  subtitle: '选择分享平台',
  message: '请选择要分享的平台',
  sheets: [
    { title: '微信', action: () => { /* ... */ } },
    { title: 'QQ', action: () => { /* ... */ } },
    { title: '微博', action: () => { /* ... */ } }
  ] as Array<SheetInfo>,
  cancel: () => { /* 取消分享 */ }
});
```

---

## 场景三：日期/时间/文本选择器弹窗

**场景示例描述**：用户设置生日、选择出行日期或预约时间等需要滑动选择年月日的场景。

**解决方案**：使用 DatePickerDialog.show()，设置 start/end 范围、selected 默认日期，通过 onDateAccept 回调获取选中日期。

```typescript
// 日期选择
this.getUIContext().showDatePickerDialog({
  start: new Date('2000-01-01'),
  end: new Date('2030-12-31'),
  selected: new Date(),
  lunar: false,
  onDateAccept: (value: Date) => { /* ... */ },
  onCancel: () => {}
});

// 时间选择
this.getUIContext().showTimePickerDialog({
  selected: new Date(),
  useMilitaryTime: true,
  onAccept: (value: TimePickerResult) => { /* ... */ },
  onCancel: () => {}
});

// 文本选择
this.getUIContext().showTextPickerDialog({
  range: ['高中', '大专', '本科', '硕士', '博士'],
  onAccept: (value: TextPickerResult) => { /* ... */ },
  onCancel: () => {}
});

// 日历选择
CalendarPickerDialog.show({
  selected: new Date(),
  start: new Date('2024-01-01'),
  end: new Date('2027-12-31'),
  onAccept: (value: Date) => {},
  onCancel: () => {}
});
```

### 选择器弹窗对比

| 弹窗 | 调用方式 | 选择内容 | 关键回调 |
|------|---------|---------|---------|
| DatePickerDialog | `getUIContext().showDatePickerDialog()` | 日期 | `onDateAccept` |
| TimePickerDialog | `getUIContext().showTimePickerDialog()` | 时分 | `onAccept` |
| TextPickerDialog | `getUIContext().showTextPickerDialog()` | 文本数组 | `onAccept` |
| CalendarPickerDialog | `CalendarPickerDialog.show()` | 日历日期 | `onAccept` |

---

## 场景四：异步确认对话框

**场景示例描述**：提交表单前需要异步确认"是否提交当前内容"，根据用户点击"确认"或"取消"的异步返回结果决定是否执行后续提交。

**解决方案**：使用 promptAction.showDialog()，通过 Promise 获取用户点击的按钮索引，在 then 回调中处理异步逻辑。

```typescript
async showSubmitDialog(): Promise<void> {
  try {
    const result = await this.getUIContext().getPromptAction().showDialog({
      title: '提交确认',
      message: '确认提交当前表单数据？提交后不可修改。',
      buttons: [
        { text: '取消', color: '#999' },
        { text: '确认', color: '#007DFF' }
      ]
    });
    if (result.index === 1) {
      // 确认提交
    } else {
      // 取消提交
    }
  } catch (err) {
    // 弹窗关闭
  }
}
```

### showDialog 与 AlertDialog 对比

| 特性 | AlertDialog | showDialog |
|------|------------|-----------|
| 返回方式 | 同步 action 回调 | Promise 异步返回 |
| 按钮索引 | 无 | `result.index` |
| 调用方式 | `getUIContext().showAlertDialog()` | `getUIContext().getPromptAction().showDialog()` |
| 适用场景 | 直接执行操作 | 需异步处理结果后再操作 |

---

## 场景五：操作菜单

**场景示例描述**：工具栏中点击"更多"按钮，弹出"编辑/删除/分享/收藏"等操作选项菜单，需要根据用户选择的菜单项异步执行对应操作。

**解决方案**：使用 promptAction.showActionMenu()，通过 buttons 配置菜单项，Promise 返回用户选择的按钮索引。

```typescript
async showMoreActions(): Promise<void> {
  try {
    const result = await this.getUIContext().getPromptAction().showActionMenu({
      title: '更多操作',
      buttons: [
        { text: '编辑', color: '#333' },
        { text: '删除', color: '#e74c3c' },
        { text: '分享', color: '#007DFF' },
        { text: '收藏', color: '#f39c12' }
      ]
    });
    const actions: string[] = ['编辑', '删除', '分享', '收藏'];
    // 执行 actions[result.index] 对应操作
  } catch (err) {
    // 取消操作
  }
}
```

---

## 场景六：不依赖UI的全局弹窗（动态更新内容）

**场景示例描述**：电商促销活动中，弹出广告弹窗且需要在倒计时结束后动态更新弹窗内容（如倒计时数字、按钮文案变为"立即抢购"）。

**解决方案**：使用 getUIContext().getPromptAction().openCustomDialog() 创建弹窗，通过 ComponentContent 的 update() 方法动态更新弹窗属性。

```typescript
import { ComponentContent } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

// 1. 定义参数类
class CountdownParams {
  countdownText: string = '';
  buttonText: string = '';
  onButton: () => void = () => {};
  onClose: () => void = () => {};
  constructor(countdownText: string, buttonText: string,
    onButton: () => void, onClose: () => void) { /* ... */ }
}

// 2. 定义 @Builder 构建弹窗内容
@Builder
function buildCountdownDialog(params: CountdownParams) {
  Column({ space: 16 }) {
    Text('🎉 限时特惠').fontSize(20).fontWeight(FontWeight.Bold)
    Text(params.countdownText).fontSize(28).fontColor('#e74c3c')
    Text('全场商品低至5折').fontSize(14).fontColor('#666')
    Button(params.buttonText).width('100%').onClick(() => params.onButton())
    Button('关闭').width('100%').backgroundColor('#f0f0f0').onClick(() => params.onClose())
  }.width(280).padding(24).backgroundColor(Color.White).borderRadius(16)
}

// 3. 创建 ComponentContent 并打开弹窗
private content: ComponentContent<CountdownParams> | null = null;

showCountdownDialog(): void {
  this.content = new ComponentContent(
    this.getUIContext(),
    wrapBuilder(buildCountdownDialog),
    new CountdownParams(`倒计时：5秒`, '等待倒计时', () => {}, () => { this.closeDialog(); })
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.content, {
    alignment: DialogAlignment.Center,
    isModal: true,
    autoCancel: false
  }).then(() => {
    this.startCountdown();  // 启动定时器
  }).catch((error: BusinessError) => {});
}

// 4. 定时器中动态更新弹窗内容
startCountdown(): void {
  this.timerId = setInterval(() => {
    this.countdown--;
    if (this.countdown <= 0) {
      clearInterval(this.timerId);
      // 倒计时结束，更新按钮文案为"立即抢购"
      this.content?.update(new CountdownParams(
        '倒计时结束！', '立即抢购', () => { /* ... */ }, () => { this.closeDialog(); }
      ));
    } else {
      // 更新倒计时数字
      this.content?.update(new CountdownParams(
        `倒计时：${this.countdown}秒`, '等待倒计时', () => {}, () => { this.closeDialog(); }
      ));
    }
  }, 1000);
}

// 5. 关闭弹窗 & 销毁资源
closeDialog(): void {
  if (this.timerId !== -1) { clearInterval(this.timerId); }
  if (this.content) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.content)
      .then(() => { this.content = null; })
      .catch((error: BusinessError) => {});
  }
}

aboutToDisappear(): void {
  if (this.timerId !== -1) { clearInterval(this.timerId); }
  if (this.content) { this.content.dispose(); }  // 必须释放资源
}
```

### openCustomDialog 关键 API

| 方法 | 作用 |
|------|-----|
| `new ComponentContent(uiContext, wrapBuilder(builder), params)` | 创建弹窗内容 |
| `openCustomDialog(content, options)` | 打开弹窗，返回 Promise |
| `content.update(newParams)` | 动态更新弹窗内容 |
| `closeCustomDialog(content)` | 关闭弹窗，返回 Promise |
| `content.dispose()` | 销毁组件内容，释放资源 |

---

## 场景七：基础自定义弹窗

**场景示例描述**：电商应用中，商品详情弹出包含商品规格选择（颜色/尺码）、数量调节和加入购物车按钮的弹窗。

**解决方案**：使用 @CustomDialog 装饰器定义包含规格选择组件的弹窗，通过 CustomDialogController 管理弹窗交互。

```typescript
// 1. 定义 @CustomDialog 弹窗
@CustomDialog
struct SpecDialog {
  controller: CustomDialogController;
  onResult: (result: string) => void = () => {};
  @State selectedColor: string = '';
  @State selectedSize: string = '';
  @State quantity: number = 1;

  build() {
    Column({ space: 12 }) {
      Text('商品规格').fontSize(18).fontWeight(FontWeight.Bold)

      // 颜色选择
      Text('颜色').fontSize(14).alignSelf(ItemAlign.Start)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(['黑色', '白色', '蓝色', '红色'], (item: string) => {
          Button(item)
            .backgroundColor(this.selectedColor === item ? '#007DFF' : '#f0f0f0')
            .onClick(() => { this.selectedColor = item; })
        })
      }.width('100%')

      // 尺码选择（同理省略）
      // ...

      // 数量调节
      Row({ space: 16 }) {
        Button('-').enabled(this.quantity > 1).onClick(() => { this.quantity--; })
        Text(this.quantity.toString()).fontSize(16)
        Button('+').onClick(() => { this.quantity++; })
      }

      // 操作按钮
      Row({ space: 12 }) {
        Button('取消').onClick(() => { this.controller.close(); })
        Button('加入购物车')
          .enabled(this.selectedColor !== '' && this.selectedSize !== '')
          .onClick(() => {
            this.onResult(`已加入：${this.selectedColor} ${this.selectedSize} x${this.quantity}`);
            this.controller.close();
          })
      }
    }.width(300).padding(24)
  }
}

// 2. 在页面中创建 Controller 并使用
private specDialogController: CustomDialogController = new CustomDialogController({
  builder: SpecDialog({ onResult: (result: string) => { /* ... */ } }),
  autoCancel: true,
  alignment: DialogAlignment.Bottom,
  customStyle: true
});

// 使用
Button('商品规格').onClick(() => { this.specDialogController.open(); })
```

### CustomDialogController 关键配置

| 属性 | 作用 | 示例 |
|------|-----|------|
| `builder` | 弹窗内容构建器 | `SpecDialog({ onResult: ... })` |
| `autoCancel` | 点击蒙层是否关闭 | `true` / `false` |
| `alignment` | 弹窗位置 | `Center` / `Bottom` / `Top` |
| `customStyle` | 是否自定义样式 | `true` 时移除默认圆角背景 |

### DialogAlignment 枚举

| 枚举值 | 弹窗位置 | 适用场景 |
|--------|---------|---------|
| `Top` | 顶部对齐 | 搜索建议、顶部提示 |
| `Center` | 居中对齐 | 通用弹窗、确认框 |
| `Bottom` | 底部对齐 | 规格选择、底部面板 |
| `Default` | 默认（居中） | 不指定时默认值 |

### @CustomDialog 与 openCustomDialog 对比

| 特性 | @CustomDialog + Controller | openCustomDialog + ComponentContent |
|------|---------------------------|-----------------------------------|
| 动态更新 | 不支持，创建后属性固定 | 支持，通过 `content.update()` |
| 状态共享 | 与父组件绑定，便于共享 | 不依赖特定组件上下文 |
| API 推荐 | API 12 起不推荐 | 推荐 |
| 适用场景 | 内容固定的自定义弹窗 | 需动态更新、全局弹窗 |

### @CustomDialog 与 transition 兼容性禁止写法
> **禁止用 @CustomDialog + CustomDialogController 实现需要 transition 自定义过渡动画的弹窗**。CustomDialogController 的配置项中**不含 transition 参数**,无法设置 TransitionEffect 过渡动画;自定义弹窗动画必须使用 `openCustomDialog(content, { transition: ... })` 方案。同理,禁止用 animateTo 或 animation 属性修饰器手动模拟弹窗过渡——它们无法作用于弹窗/蒙层的进出过渡阶段,只有 `transition` 参数才能接管弹窗系统过渡。

---

## 场景八：弹窗层级管理

**场景示例描述**：多任务编辑器中，基础设置弹窗（层级50）之上弹出"未保存提醒"弹窗（层级200），确保保存提醒始终覆盖在设置弹窗之上。

**解决方案**：分别为两个弹窗设置不同的 levelOrder 值，确保关键提醒弹窗的层级高于普通设置弹窗。

```typescript
// 低层级弹窗（levelOrder: 50）
showLowLevelDialog(): void {
  this.lowContent = new ComponentContent(
    this.getUIContext(), wrapBuilder(buildLevelDialog),
    new LevelDialogParams('基础设置弹窗', '普通优先级的设置消息。', 50, () => { this.closeLowDialog(); })
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.lowContent, {
    alignment: DialogAlignment.Center,
    isModal: true,
    autoCancel: true,
    levelOrder: LevelOrder.clamp(50)    // 层级 50
  }).then(() => {}).catch((error: BusinessError) => {});
}

// 高层级弹窗（levelOrder: 200，覆盖在低层级之上）
showHighLevelDialog(): void {
  this.highContent = new ComponentContent(
    this.getUIContext(), wrapBuilder(buildLevelDialog),
    new LevelDialogParams('未保存提醒', '您有未保存的修改，是否保存？', 200, () => { this.closeHighDialog(); })
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.highContent, {
    alignment: DialogAlignment.Center,
    isModal: true,
    autoCancel: true,
    levelOrder: LevelOrder.clamp(200)   // 层级 200，高于 50
  }).then(() => {}).catch((error: BusinessError) => {});
}

// 3. 分别关闭两弹窗并释放资源
closeLowDialog(): void {
  if (this.lowContent) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.lowContent)
      .then(() => { this.lowContent?.dispose(); this.lowContent = null; })
      .catch((error: BusinessError) => {});
  }
}

closeHighDialog(): void {
  if (this.highContent) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.highContent)
      .then(() => { this.highContent?.dispose(); this.highContent = null; })
      .catch((error: BusinessError) => {});
  }
}

aboutToDisappear(): void {
  // 先关高层级再关低层级,两者均需 dispose
  this.closeHighDialog();
  this.closeLowDialog();
}
```

### levelOrder 禁止写法
> **禁止用 zIndex 或 Position 绝对定位代替 levelOrder 管理弹窗层级**。zIndex/Position 作用于组件树中的普通节点,无法影响 `promptAction.openCustomDialog` 弹窗的独立渲染层叠顺序;只有 `levelOrder` 参数才能控制 openCustomDialog 弹窗之间的覆盖优先级。两弹窗必须使用各自独立的 ComponentContent 对象,不可共用同一实例,否则内容冲突。

---

## 场景九：弹窗焦点管理（不获取焦点的弹窗）

**场景示例描述**：用户在搜索框中输入文字时，实时弹出搜索建议/联想词弹窗，弹窗不应关闭软键盘，焦点保持在输入框中让用户继续输入。

**解决方案**：使用 openCustomDialog() 并设置 focusable 为 false，弹窗弹出时不获取焦点，软键盘不会收起。

```typescript
@Builder
function buildSuggestionDialog(param: SuggestionParams) {
  Column({ space: 8 }) {
    Text('搜索建议').fontSize(14).fontWeight(FontWeight.Bold)
    Column({ space: 4 }) {
      ForEach(param.suggestions, (item: string) => {
        Text('• ' + item)
          .fontSize(13).fontColor('#007DFF').width('100%')
          .onClick(() => param.onSelect(item))  // 点击建议词:填入搜索框并关闭弹窗
      })
    }.width('100%').padding(8).backgroundColor('#f5f5f5').borderRadius(8)
    Button('关闭').onClick(() => param.onClose())
  }.width(260).padding(16).backgroundColor(Color.White).borderRadius(12)
}

// SuggestionParams 需增加 onSelect 回调
class SuggestionParams {
  suggestions: string[] = [];
  onSelect: (item: string) => void = () => {};
  onClose: () => void = () => {};
  constructor(suggestions: string[], onSelect: (item: string) => void, onClose: () => void) { /* ... */ }
}

showSuggestionDialog(): void {
  this.content = new ComponentContent(
    this.getUIContext(),
    wrapBuilder(buildSuggestionDialog),
    new SuggestionParams(
      ['ArkTS 开发指南', 'ArkUI 组件参考', '弹窗最佳实践'],
      (item: string) => { /* 将选中词填入搜索框 */ this.closeDialog(); },
      () => { this.closeDialog(); }
    )
  );
  this.getUIContext().getPromptAction().openCustomDialog(this.content, {
    alignment: DialogAlignment.Top,
    isModal: false,      // 非模态，允许与蒙层外组件交互
    autoCancel: true,
    focusable: false     // 关键：弹窗不获取焦点，软键盘不收起
  }).then(() => {}).catch((error: BusinessError) => {});
}
```

---

## 场景十：弹窗蒙层控制（显隐/样式/交互）

**场景示例描述**：支付确认弹窗中禁止点击蒙层关闭防止误触；新手引导中蒙层只遮挡部分区域实现局部高亮；非模态弹窗允许与蒙层外组件交互。

**解决方案**：通过 autoCancel、isModal、maskRect 三个参数控制蒙层行为。

```typescript
// 0. 定义支付确认弹窗内容(必须提供按钮,autoCancel:false 时只能通过按钮关闭)
class PaymentParams {
  onConfirm: () => void = () => {};
  onCancel: () => void = () => {};
  constructor(onConfirm: () => void, onCancel: () => void) { /* ... */ }
}

@Builder
function buildPaymentDialog(param: PaymentParams) {
  Column({ space: 16 }) {
    Text('支付确认').fontSize(20).fontWeight(FontWeight.Bold)
    Text('确认支付 ¥99.00?').fontSize(14).fontColor('#666')
    Row({ space: 12 }) {
      Button('取消').width('50%').backgroundColor('#f0f0f0')
        .onClick(() => param.onCancel())
      Button('确认支付').width('50%').backgroundColor('#007DFF').fontColor(Color.White)
        .onClick(() => param.onConfirm())
    }.width('100%')
  }.width(300).padding(24).backgroundColor(Color.White).borderRadius(16)
}

// this.content 需在调用前创建
this.content = new ComponentContent(
  this.getUIContext(), wrapBuilder(buildPaymentDialog),
  new PaymentParams(() => { /* 执行支付 */ this.closeDialog(); },
                    () => { this.closeDialog(); })
);

// 1. 禁止蒙层关闭（支付确认场景）
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: true,
  autoCancel: false   // 点击蒙层不关闭，必须通过按钮操作
});

// 2. 非模态弹窗（允许与蒙层外组件交互）
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: false,     // 非模态，蒙层外区域可交互
  autoCancel: true
});

// 3. 局部蒙层（只遮挡顶部10%区域，范围外事件透传）
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Top,
  isModal: true,
  autoCancel: true,
  maskRect: { x: 0, y: 0, width: '100%', height: '10%' }
});
```

### 蒙层控制参数对比

| 参数 | 作用 | 典型场景 |
|------|-----|---------|
| `autoCancel: false` | 禁止点击蒙层关闭 | 支付确认、关键操作防误触 |
| `isModal: false` | 非模态，蒙层外可交互 | 搜索建议、悬浮提示 |
| `maskRect: { x, y, width, height }` | 定制蒙层区域 | 新手引导局部高亮 |

---

## 场景十一：弹窗动画控制

**场景示例描述**：节日活动弹窗需要自定义淡入淡出动画效果，弹窗和蒙层整体以3秒缓慢渐显方式出现，增强视觉氛围。

**解决方案**：使用 openCustomDialog() 的 transition 参数设置 TransitionEffect 自定义过渡动画。

```typescript
// 1. 慢速淡入（3秒渐显）
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: true,
  autoCancel: true,
  transition: TransitionEffect.OPACITY.animation({ duration: 3000 })
});

// 2. 快速淡入（1秒）
transition: TransitionEffect.OPACITY.animation({ duration: 1000 })

// 3. 滑动+淡入组合动画
this.getUIContext().getPromptAction().openCustomDialog(this.content, {
  alignment: DialogAlignment.Center,
  isModal: true,
  autoCancel: true,
  transition: TransitionEffect.translate({ y: 300 })
    .combine(TransitionEffect.OPACITY)
    .animation({ duration: 800 })
});

// 4. 关闭弹窗并释放资源(transition 场景同样需要资源闭环)
closeDialog(): void {
  if (this.content) {
    this.getUIContext().getPromptAction().closeCustomDialog(this.content)
      .then(() => { this.content?.dispose(); this.content = null; })
      .catch((error: BusinessError) => {});
  }
}

aboutToDisappear(): void {
  if (this.content) { this.content.dispose(); }
}
```

### TransitionEffect 枚举

| 枚举值/方法 | 效果 | 用法 |
|------------|------|-----|
| `OPACITY` | 透明度过渡 | `TransitionEffect.OPACITY.animation({ duration: 3000 })` |
| `translate({ x, y })` | 平移过渡 | `TransitionEffect.translate({ y: 300 })` |
| `scale({ x, y })` | 缩放过渡 | `TransitionEffect.scale({ x: 0.8, y: 0.8 })` |
| `rotate({ angle })` | 旋转过渡 | `TransitionEffect.rotate({ angle: 180 })` |
| `move(...)` | 位移过渡 | `TransitionEffect.move(TransitionEdge.TOP)` |
| `.combine(effect)` | 组合多个效果 | `.combine(TransitionEffect.OPACITY)` |
| `.animation({ duration })` | 设置动画时长 | `.animation({ duration: 800 })` |

### TransitionEdge 枚举

| 枚举值 | 方向 |
|--------|------|
| `TOP` | 从顶部滑入/滑出 |
| `BOTTOM` | 从底部滑入/滑出 |
| `START` | 从起始侧（左）滑入/滑出 |
| `END` | 从结束侧（右）滑入/滑出 |
