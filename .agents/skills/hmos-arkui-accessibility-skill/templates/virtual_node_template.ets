/**
 * 自绘组件虚拟节点模板（F 类，accessibilityVirtualNode，API 11+）
 * 事实基准：references/api-facts.md、references/virtual-node.md
 * 约束 1：参数直传 @Builder 方法引用 this.xxx（lambda/对象包裹均违规，2026-10 评测 vod-3/vod-4 实测）
 * 约束 2：builder 内容基线是"单个 Text 直接描述"——Text 默认播报能力即可满足；
 *         禁止"容器 accessibilityGroup(true) + 子 Text 叠 accessibilityText"组合——
 *         合并文本只拼子组件通用文本，子无障碍文本被丢弃（2026-10 评测实测，vod-5）
 */

// ========== F 类基线：Canvas 折线图可读（API 11+，输出前先查 build-profile 三字段 ≥ 11） ==========
@Entry
@Component
struct TrendChartPage {
  private context: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));

  @Builder
  chartAccessibilityNode() {
    Text('折线图：最近 7 天数据呈上升趋势，峰值 92，今日 81')   // 单个 Text 直述，默认播报即可，不叠加无障碍属性
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height(240)
      .onReady(() => {
        // ...原有绘制逻辑保持不变（辅助工具不读绘制内容）
        this.drawTrend();
      })
      .accessibilityVirtualNode(this.chartAccessibilityNode)   // 方法引用直传，禁用 lambda/对象包裹
  }

  drawTrend() {
    // 原有绘制实现
  }
}

// ========== 分粒度虚拟节点（有结构的数据）：多个 Text 各自聚焦、默认播报 ==========
// 容器仅做布局承载；不加 accessibilityGroup(true)（加了会触发合并文本规则，见文末反例）
@Builder
dashboardAccessibilityNode() {
  Column() {
    Text('仪表盘总览：当前时速 60 公里每小时，限速 80')
    Text('区间均值：最近 5 分钟均值 58')
  }
}

// ========== 可交互自绘区域（配合自定义动作，API 12+） ==========
// 有显示文本的 Text 默认播报即可，无需 accessibilityText；仅无文本组件才补
@Builder
boardAccessibilityNode() {
  Text('E2 格，白方马，可走 D4/F3/G1')
    .accessibilityCustomActions([
      {
        name: '移动到 D4',
        action: 'move',
        onAction: () => this.moveTo('D4')
      }
    ])
}

// ========== 反例（禁止输出，vod-5）：组合并文本丢弃子无障碍文本 ==========
// @Builder wrongNode() {
//   Column() {
//     Text('仪表盘')                                         // 合并文本只拼子组件通用文本'仪表盘'
//       .accessibilityText('仪表盘：当前转速 2450 转每分钟')   // ← 被丢弃，播报只剩'仪表盘'
//   }
//   accessibilityGroup(true)                                 // 容器无自身文本时触发合并规则
// }
// 根因：父组件启用分组且自身无通用文本、未设 accessibilityText 时，合并文本默认拼接子组件
// 通用文本，不使用子组件的无障碍文本。
// 正解 1（基线）：builder 内单个 Text 直述完整描述（见 TrendChartPage）。
// 正解 2（确需分组且保留子无障碍文本）：
//   accessibilityGroup(true, { accessibilityPreferred: true })
//   （深度遍历子节点时优先取其无障碍文本；较新参数，下限版本以官方文档为准，输出前核对）
