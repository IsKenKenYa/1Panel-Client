/**
 * 示例：原生 UI 页面接续（UI 浏览类）
 *
 * 用途：展示原生 UI 页面（列表、详情、Tab 页面）的接续实现模式。
 *   包含 PageState 状态模型框架 + 页面侧实现 + Ability 接线。
 *
 * 核心组件：
 *   1. PageState 接口 —— 单个页面的可迁移状态快照
 *   2. PageStateHandler 接口 —— 页面需实现的导出/恢复能力
 *   3. PageStateCodec —— PageState ↔ JSON 编解码（用于 want.parameters 通道）
 *   4. PageStateRegistry —— 全局注册表，Ability 与页面解耦
 *
 * ⚠️ 初始值保护原则：
 *   因 Tabs 懒加载等机制，部分组件可能从未创建（handler 未注册）。
 *   为防止 payload 中默认值覆盖组件本地初始值：
 *   - exportAll：未从 handler 获得的字段保持 undefined
 *   - restoreState：仅覆盖 !== undefined 的字段
 *
 * 使用方式：把本文件中的框架代码复制到项目的 common/ 或 utils/ 下，
 *   按页面数量实现 PageStateHandler 并注册。
 *
 * 配套文件：
 *   - Ability 接线：assets/templates/EntryAbility.ets
 *   - 方案说明：references/ui-progress-continuity.md
 */

// ---------- 1. 状态模型 ----------

/**
 * 单个页面的可迁移状态快照。
 * payload 中的 key 使用语义化命名：scrollOffset / inputText / cursorPosition / tabIndex 等
 */
export interface PageState {
  /** 页面唯一标识，与注册表 key 一致 */
  pageId: string;
  /** 状态模型版本号：结构变更时递增，目标端据此做兼容解析 */
  version: number;
  /** 业务状态字段（必须是 JSON 可序列化数据） */
  payload: Record<string, Object | undefined>;
}

// ---------- 2. 页面侧实现接口 ----------

/** 页面需实现的接续能力：导出 / 恢复 */
export interface PageStateHandler {
  /** 导出当前交互状态（滚动位置、输入内容、Tab 索引等） */
  exportState(): PageState;

  /** 恢复状态：幂等，重复调用不应产生副作用 */
  restoreState(state: PageState): void;
}

// ---------- 3. 编解码 ----------

/** PageState ↔ JSON 字符串互转；用于 want.parameters 通道 */
export class PageStateCodec {
  static serialize(states: Array<PageState>): string {
    return JSON.stringify(states);
  }

  static deserialize(json: string): Array<PageState> | undefined {
    try {
      return JSON.parse(json) as Array<PageState>;
    } catch (e) {
      return undefined;
    }
  }
}

// ---------- 4. 注册表（Ability 与页面解耦） ----------

/**
 * 全局页面状态注册表。
 * 页面在 aboutToAppear 时 register，aboutToDisappear 时 unregister；
 * Ability 只与注册表交互，不感知具体页面。
 */
export class PageStateRegistry {
  private static instanceValue: PageStateRegistry | undefined = undefined;

  static getInstance(): PageStateRegistry {
    if (PageStateRegistry.instanceValue === undefined) {
      PageStateRegistry.instanceValue = new PageStateRegistry();
    }
    return PageStateRegistry.instanceValue;
  }

  private handlers: Map<string, PageStateHandler> = new Map<string, PageStateHandler>();

  register(pageId: string, handler: PageStateHandler): void {
    this.handlers.set(pageId, handler);
  }

  unregister(pageId: string): void {
    this.handlers.delete(pageId);
  }

  /** 源端调用：导出所有已注册页面的状态 */
  exportAll(): Array<PageState> {
    const states: Array<PageState> = [];
    this.handlers.forEach((handler: PageStateHandler) => {
      states.push(handler.exportState());
    });
    return states;
  }

  /** 目标端调用：按 pageId 逐页恢复状态（未注册的页面静默跳过） */
  restoreAll(states: Array<PageState>): void {
    states.forEach((state: PageState) => {
      const handler: PageStateHandler | undefined = this.handlers.get(state.pageId);
      if (handler !== undefined) {
        handler.restoreState(state);
      }
    });
  }
}

// ---------- 5. 页面接入示例 ----------

/*
 * 【页面 Index.ets】实现 PageStateHandler 并注册：
 *
 *   @Entry
 *   @Component
 *   struct Index implements PageStateHandler {
 *     private scroller: Scroller = new Scroller();
 *     @State inputText: string = '';
 *
 *     aboutToAppear(): void {
 *       PageStateRegistry.getInstance().register('page_index', this);
 *       // 迁移恢复：读 AppStorage 中的快照并恢复
 *       const json = AppStorage.get<string>('migratedPageStates');
 *       if (json !== undefined) {
 *         const states = PageStateCodec.deserialize(json);
 *         if (states !== undefined) {
 *           PageStateRegistry.getInstance().restoreAll(states);
 *         }
 *       }
 *     }
 *
 *     aboutToDisappear(): void {
 *       PageStateRegistry.getInstance().unregister('page_index');
 *     }
 *
 *     exportState(): PageState {
 *       return {
 *         pageId: 'page_index',
 *         version: 1,
 *         payload: {
 *           // ⚠️ 用 scroller.currentOffset().yOffset 采集确定性累计位置
 *           // 不要直接用 onDidScroll 回调参数（可能是每帧增量）
 *           'scrollOffset': this.scroller.currentOffset().yOffset,
 *           'inputText': this.inputText,
 *         },
 *       };
 *     }
 *
 *     restoreState(state: PageState): void {
 *       const offset = state.payload['scrollOffset'] as number | undefined;
 *       if (offset !== undefined) {
 *         // ⚠️ 需延迟到布局完成后执行 scrollTo：
 *         // aboutToAppear 中 Scroll 尚未完成布局，setTimeout(0) 会被静默忽略
 *         setTimeout(() => {
 *           this.scroller.scrollTo({ xOffset: 0, yOffset: offset });
 *         }, 50);
 *       }
 *       // ⚠️ 仅覆盖非 undefined 字段，保护组件本地初始值（懒加载 Tab 保护）
 *       const text = state.payload['inputText'] as string | undefined;
 *       if (text !== undefined) {
 *         this.inputText = text;
 *       }
 *     }
 *
 *     build() { // ...页面 UI... }
 *   }
 */
