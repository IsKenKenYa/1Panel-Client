/**
 * 示例：接续中页面栈迁移（Navigation 路由）
 *
 * 用途：把源端的完整导航栈（页面名 + 入参 + 每页状态）序列化后迁移到目标端，
 *       目标端按序重建导航栈，用户停留在迁移前的同一层页面。
 *
 * 关键前提（见 references/constraints-and-prereqs.md）：
 *   - Router 路由：系统自动恢复页面栈（仅 Router 支持，onCreate/onNewWant 完成前
 *     同步调用 restoreWindowStage 触发），本示例可选（用于自定义状态）
 *   - Navigation 路由：系统【不】恢复页面栈，必须：
 *       ① 源端 onContinue 里设置 SUPPORT_CONTINUE_PAGE_STACK_KEY = false
 *       ② 目标端 onCreate/onNewWant 暂存快照并同步调用 restoreWindowStage()，
 *          在 onWindowStageRestore 中 loadContent 根页后，由根页消费快照触发
 *          rebuild（冷启动 aboutToAppear / 热启动 @StorageProp+@Watch）
 *
 * ⚠️ 约束：不修改项目现有路由方式。绝不可为了"省事"把 Navigation 改成 Router。
 *
 * 使用方式：复制到项目 common/ 下；Ability 与根页面接线示例见文件末尾注释块。
 *
 * 配套文件：
 *   - Router 路由示例：assets/examples/RouterContinuity.ets
 *   - Ability 接线：assets/templates/EntryAbility.ets
 *   - 方案说明：references/navigation-continuity.md
 */

// ---------- 1. 导航栈数据结构 ----------

/** 导航栈中的一个页面（自底向顶） */
export interface NavStackEntry {
  /** 页面名：Navigation 的 route name（或 Router 的页面路径） */
  pageName: string;
  /** 页面入参：必须是 JSON 可序列化数据（禁止函数/类实例等非序列化对象） */
  params: Record<string, Object | undefined>;
  /** 该页面的交互状态快照 JSON（可选；由 PageState 模型产出，见 UIProgress.ets） */
  stateJson: string | undefined;
}

/** 一次迁移的导航栈快照 */
export interface NavStackSnapshot {
  /** 栈内全部页面 */
  entries: Array<NavStackEntry>;
  /** 用户当前停留的层级（0 起始）；目标端重建后停在同一层 */
  currentIndex: number;
}

// ---------- 2. 编解码 ----------

export class NavStackCodec {
  static serialize(snapshot: NavStackSnapshot): string {
    return JSON.stringify(snapshot);
  }

  static deserialize(json: string): NavStackSnapshot | undefined {
    try {
      return JSON.parse(json) as NavStackSnapshot;
    } catch (e) {
      return undefined;
    }
  }
}

// ---------- 3. 导航栈重建（Navigation 路由） ----------

export class NavStackRebuilder {
  /**
   * 按快照重建 Navigation 导航栈。
   * ⚠️ getPathStack() 快照**不含 NavBar 根页**（NavPathStack 只管理
   * NavDestination，官方口径见 api-reference §3-B.1）：entries[0] 是第一个
   * 真实子页，而 loadContent 加载的是包含 Navigation 的根页面——二者不是
   * 同一页。必须重建**全部** entry，不跳过任何层（历史上误传 rootLoaded=true
   * 跳过 entries[0]，导致迁移后丢失第一层子页）。
   * @param pathStack 根页面持有的 NavPathStack（ArkUI 内置类型）
   * @param snapshot  迁移来的导航栈快照
   */
  static rebuild(pathStack: NavPathStack, snapshot: NavStackSnapshot): void {
    const endIndex: number = Math.min(snapshot.currentIndex, snapshot.entries.length - 1);

    for (let i = 0; i <= endIndex; i++) {
      const entry: NavStackEntry = snapshot.entries[i];
      // 实时态随本实例入参传递（per-instance，不落共享 live key——防同页名
      // 后续实例读到旧值串染；消费端 onReady 接管见 navigation-continuity §4.1）
      const params: Record<string, Object | undefined> = entry.params;
      if (entry.stateJson !== undefined) {
        params['liveState'] = entry.stateJson;
      }
      pathStack.pushPathByName(entry.pageName, params, false);
    }
  }
}

// ---------- 4. 接入示例 ----------

/*
 * 【源端 EntryAbility.ets】onContinue 中生成快照并写入 wantParam：
 *
 *   import { AbilityConstant, UIAbility, wantConstant } from '@kit.AbilityKit';
 *   import { NavStackCodec } from '../common/NavStackSnapshot';
 *
 *   onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
 *     // ① 禁用系统页面栈迁移（Navigation 不支持自动恢复）
 *     wantParam[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY] = false;
 *     // ② 快照由根页面通过 AppStorage 提供
 *     const json = AppStorage.get<string>('currentNavStack');
 *     if (json !== undefined) {
 *       wantParam['navStack'] = json;
 *     }
 *     return AbilityConstant.OnContinueResult.AGREE;
 *   }
 *
 * 【根页面 Index.ets】持有 pathStack，负责采集与重建：
 *
 *   @Entry
 *   @Component
 *   struct Index {
 *     pathStack: NavPathStack = new NavPathStack();
 *
 *     // 源端：didShow 单一钩子采集（API 12+，签名见 api-reference §3-B.2）——
 *     // 任何页面展示（push/replace/系统返回 pop）统一触发，勿在每个 push 点各改一处
 *     private setupSnapshotHook(): void {
 *       this.pathStack.setInterception({
 *         didShow: () => this.refreshSnapshot(),
 *       } as NavigationInterception);
 *     }
 *
 *     private refreshSnapshot(): void {
 *       // getPathStack（API 名与"栈不含根页"口径见 api-reference §3-B.1）
 *       const infos = this.pathStack.getPathStack();
 *       const entries: Array<NavStackEntry> = [];
 *       infos.forEach((info: NavPathInfo, index: number) => {
 *         entries.push({
 *           pageName: info.name,
 *           params: info.param as Record<string, Object | undefined> ?? {},
 *           // 实时态只合并顶层实例（上报与 onReady 接管见 navigation-continuity §4.1）
 *           stateJson: index === infos.length - 1
 *             ? AppStorage.get<string>('live_' + info.name) : undefined,
 *         });
 *       });
 *       AppStorage.setOrCreate('currentNavStack',
 *         NavStackCodec.serialize({
 *           entries: entries,
 *           currentIndex: this.pathStack.size() - 1,
 *         }));
 *     }
 *
 *     // 热启动联动：@StorageProp 单向同步 + @Watch 感知快照到达
 *     // （singleton 已运行时 aboutToAppear 不会再触发；module.md 约定必测热启动）
 *     @StorageProp('migratedNavStack') @Watch('onNavStackArrived')
 *     migratedNavStack: string = '';
 *
 *     onNavStackArrived(): void {
 *       // ⚠️ 先捕获本地副本、再清空 AppStorage——@StorageProp 单向同步会把
 *       //    成员刷成空串，先清后读必翻车；空串守卫防清空回触发的重入
 *       const json: string = this.migratedNavStack;
 *       AppStorage.setOrCreate('migratedNavStack', '');
 *       if (json === '') {
 *         return;
 *       }
 *       const snapshot = NavStackCodec.deserialize(json);
 *       if (snapshot !== undefined) {
 *         // 丢弃目标端本机会话栈属产品语义，须在方案/报告中向用户说明
 *         this.pathStack.clear();
 *         NavStackRebuilder.rebuild(this.pathStack, snapshot);
 *       }
 *     }
 *
 *     aboutToAppear(): void {
 *       this.setupSnapshotHook(); // 源端：didShow 单钩采集
 *       // 目标端冷启动：消费迁移快照重建导航栈（消费即清，防重复重建）
 *       const json = AppStorage.get<string>('migratedNavStack');
 *       if (json !== undefined && json !== '') {
 *         AppStorage.setOrCreate('migratedNavStack', '');
 *         const snapshot = NavStackCodec.deserialize(json);
 *         if (snapshot !== undefined) {
 *           NavStackRebuilder.rebuild(this.pathStack, snapshot);
 *         }
 *       }
 *     }
 *
 *     build() {
 *       Navigation(this.pathStack) { // 首页 UI }
 *     }
 *   }
 *
 * 【目标端 EntryAbility.ets】onCreate 暂存快照并同步调用 restoreWindowStage()，
 *   onWindowStageRestore 中 loadContent 根页（⚠️ want 只在 onCreate/onNewWant 中可读）：
 *
 *   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     this.restoreOnContinuation(want, launchParam);
 *   }
 *
 *   onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     this.restoreOnContinuation(want, launchParam); // 热启动同分支
 *   }
 *
 *   private restoreOnContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     if (launchParam.launchReason !== AbilityConstant.LaunchReason.CONTINUATION) {
 *       return;
 *     }
 *     const json = want.parameters?.['navStack'] as string;
 *     if (json !== undefined) {
 *       // 冷启动根页 aboutToAppear 消费；热启动根页 @StorageProp+@Watch 感知
 *       // （联动接线见上方【根页面 Index.ets】块 / navigation-continuity §3.6）
 *       AppStorage.setOrCreate('migratedNavStack', json);
 *     }
 *     // 官方按需迁移页面栈示例：在 onCreate/onNewWant 执行完成前同步调用
 *     // （可抛异常：try/catch 兜底，见模板 EntryAbility.ets / api-reference §3.2）
 *     try {
 *       this.context.restoreWindowStage(new LocalStorage());
 *     } catch (err) {
 *       hilog.error(0x0000, 'EntryAbility', 'restoreWindowStage failed: %{public}s',
 *         JSON.stringify(err));
 *     }
 *   }
 *
 *   onWindowStageRestore(windowStage: window.WindowStage): void {
 *     // 页面栈迁移已禁用：手动加载根页，由根页消费快照触发 rebuild
 *     // （冷启动 aboutToAppear / 热启动 @Watch，见上方根页接线块）
 *     windowStage.loadContent('pages/Index');
 *   }
 *
 * 【Router 路由应用】系统自动恢复页面栈，无需手动重建；
 *   仅需把自定义状态写入 wantParam，在 onCreate/onNewWant 恢复。
 */
