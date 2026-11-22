/**
 * 基础属性组合模板（A/B/D/E 类诉求）
 * 事实基准：references/api-facts.md
 * 版本门禁：text 12+ / description 10+ / level 12+ / checked·selected 13+
 */

// ========== A 类：无文本元素可读（accessibilityText, API 12+） ==========
// 场景：播放图标等无文本组件，读屏听不出用途
Image($r('app.media.play'))
  .width(48)
  .height(48)
  .onClick(() => this.play())
  .accessibilityText('播放')
// 播报变化：'播放，图片，单指双击即可执行'（系统仍补充组件类型与操作提示）
// 注意：text 表达"是什么"，不放操作引导与状态信息；文案简洁达意，可用资源引用 $r('app.string.play_a11y')

// ========== B 类：操作后果说明（accessibilityDescription, API 10+） ==========
// 场景：按钮聚焦只播默认新手提醒，需说明点了会怎样
Button('全屏')
  .accessibilityDescription('单指双击即可全屏')
// 播报变化：'按钮，全屏，单指双击即可全屏'
// 注意：description 替代系统默认新手提醒；用户关闭新手提醒开关后 description 也不播报（不能承诺必达）

// ========== A+B 组合（正交配合：text=是什么，description=后果） ==========
Image($r('app.media.share'))
  .accessibilityText('分享')
  .accessibilityDescription('单指双击将当前文章分享到会话')

// ========== D 类：可识别性控制（accessibilityLevel, API 12+） ==========
// 枚举仅四种：'auto' | 'yes' | 'no' | 'no-hide-descendants'（无 'default'）
Image($r('app.media.decor'))          // 纯装饰：只隐藏当前节点
  .accessibilityLevel('no')

Column() {                            // 三方容器：连同后代一起隐藏
  // ... 三方内容
}
  .accessibilityLevel('no-hide-descendants')

Button('紧急止付')                     // 关键操作：强制可识别
  .accessibilityLevel('yes')

// ========== E 类：选中状态（API 13+，输出前先查 build-profile 三字段 ≥ 13） ==========
// checked = 控件物理状态（二态/三态：Checkbox、Toggle）
Toggle({ type: ToggleType.Checkbox, isOn: this.isFav })
  .accessibilityChecked(this.isFav)

// Checkbox 场景：状态源三要素（@State + 受控 select + onChange 同步）
// Checkbox 无 onSelect 方法，状态同步一律用 onChange（2026-10 评测 vod-3 实测）
@State isAgreed: boolean = false;
Checkbox({ name: 'agree', group: 'licenseGroup' })
  .select(this.isAgreed)
  .onChange((value: boolean) => {
    this.isAgreed = value;
  })
  .accessibilityChecked(this.isAgreed)

// selected = 互斥单选当前项（List、Tabs）——使能前提 + 逐项挂载 + 三同原则：
//   使能前提：只在读屏焦点节点（自身文本/onClick/内建点击）上被播报，纯容器被焦点穿透
//   （selected 不赋予可聚焦性）
//   挂在与内容、视觉选中态、点击交互同一节点的选项语义容器（每项独立 state === i）
@State selectedIndex: number = 0;
List({ space: 8 }) {
  ListItem() {                         // ListItem 只是结构壳，selected 不挂这里
    Row() { /* 项内容（含视觉选中态标识） */ }
      .onClick(() => { /* 选中该项 */ })
      .accessibilitySelected(this.selectedIndex === 0) // 交互与状态同层，挂项内容容器 Row
  }
}
// 错误示范1：Tabs() { ... }.accessibilitySelected(this.current === 1)
//   —— 挂容器整仓单一布尔，仅一项有选中态，切到其余页时读屏听不出当前选中项
// 必输出 checked/selected 对比表（见 references/decision-matrix.md），不混用二者

// ========== 覆盖语义警示（就地修改既有文本组件前必须确认） ==========
// Button 已有可见文本'提交订单'时：
// Button('提交订单').accessibilityText('支付 99 元')
// → 原文本'提交订单'不再播报，读屏只播'支付 99 元'——改动前必须向开发者确认
//   （开发者已明确知晓后果并确认、或明确指示直接修改时，视为已取得确认：直接落地并重申后果）
