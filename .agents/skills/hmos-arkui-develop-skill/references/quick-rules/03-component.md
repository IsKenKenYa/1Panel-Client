# 3. 自定义组件与命名约束

## 规则

### 组件基本约束

| 规则 | 说明 | 错误码 |
|------|------|--------|
| `struct` 无继承 | 自定义组件基于 struct，**不能有继承关系** | — |
| 禁止名称冲突 | 自定义组件名、类名、函数名**不得与系统组件名重复**（`Button`/`Text`/`Image` 等） | — |
| 单一 `@Entry` | 单个 UI 页面仅允许一个 `@Entry` 装饰的组件 | — |
| `@Component` 与 `@ComponentV2` 互斥 | 不能同时装饰同一个 struct | — |
| 创建组件不需要 `new` | `Column()`、`Text('x')`；只有控制器类用 `new`（`new NavPathStack()`） | — |
| 成员函数/变量不建议 `static` | 仅能从组件内部访问，静态声明无意义 | — |
| V1 不支持静态代码块 | `@Component` 或 `@CustomDialog` 中 `static {}` 不执行（API 22 起告警） | — |
| `@Component`（V1）禁 getter accessor | 编译转换会丢弃 getter，可能造成运行时崩溃；改用普通成员方法（`@ComponentV2` 不受此限） | — |
| 生命周期钩子不能 `private` | `aboutToAppear`、`aboutToDisappear` 等生命周期方法**不能标记为 `private`** | — |
| 成员属性名禁止与链式方法重名 | 见下方"保留名"清单 | **10505001** |
| 跨文件 interface/class 必须重名校验 | 同一 hap 全局作用域，通用名跨文件碰撞 → `arkts-no-decl-merging` | **arkts-no-decl-merging** |

### 成员变量名禁止与 CustomComponent 链式方法/通用属性重名

`@State/@Prop/@Local` 等成员名**禁止**使用以下（会与基类链式方法签名冲突，触发 `10505001`）：

`id`、`width`、`height`、`margin`、`padding`、`offset`、`position`、`border`、`borderRadius`、`backgroundColor`、`brightness`、`direction`、`value`、`scale`、`rotate`、`opacity`、`visibility`、`zIndex`、`size`、`layoutWeight`、`aspectRatio`、`flexBasis`、`flexGrow`、`flexShrink`、`alignSelf`、`justifyContent`、`alignItems`、`alignContent`、`borderWidth`、`borderColor`、`borderStyle`、`borderImage`、`foregroundColor`、`colorFilter`、`clip`、`gradient`、`blur`、`shadow`、`transform`、`markAnchor`、`translate`、`clickEffect`、`hoverEffect`、`draggable`、`enabled`、`tabIndex`（所有通用属性名 + CustomComponent 基类属性均为禁区）

命名约定：用业务前缀（`current/slide/item/bg/screen/my` 等）消歧义，如 `currentValue` 而非 `value`。

### 跨文件 interface/class 重名 → `arkts-no-decl-merging`（CRITICAL）

ArkTS 把同一 hap 内**所有页面**编译进**共享全局作用域**。多个页面文件在顶层声明同名 `interface`/`class`，会被判定为"声明合并"而报错。**碰撞发生在文件之间，本文件内看不到。** 命名之前需要避免重名存在。

## 框架保留字全表

自定义组件中定义的方法/变量若与下表重名，会导致运行时异常。凡列出的，一律改用不同名字。

| 保留字 | 保留字 | 保留字 | 保留字 |
|---|---|---|---|
| isRenderInProgress | isInitialRenderDone | runReuse_ | paramsGenerator_ |
| watchedProps | recycleManager_ | hasBeenRecycled_ | preventRecursiveRecycle_ |
| delayRecycleNodeRerender | delayRecycleNodeRerenderDeep | defaultConsume_ | reconnectConsume_ |
| providedVars_ | dirtyElementIdsNeedsUpdateSynchronously_ | localStoragebackStore_ | ownObservedPropertiesStore__ |
| obtainOwnObservedProperties | getlocalStorage_ | setlocalStorage_ | getisViewV2 |
| aboutToBeDeleted | aboutToBeDeletedInternal | purgeDeleteElmtId | purgeVariableDependenciesOnElmtIdOwnFunc |
| debugInfoStateVars | initAllowComponentFreeze | setActiveInternal | onActiveInternal |
| onInactiveInternal | purgeVariableDependenciesOnElmtId | initialRender | rerender |
| updateRecycleElmtId | updateStateVars | initialRenderView | UpdateElement |
| delayCompleteRerender | flushDelayCompleteRerender | forceRerenderNode | collectElementsNeedToUpdateSynchronously |
| viewPropertyHasChanged | uiNodeNeedUpdateV2 | performDelayedUpdate | declareWatch |
| addProvidedVar | findProvidePU__ | initializeConsume | reconnectToConsume |
| disconnectedConsume | markElemenDirtyById | updateDirtyElements | observeComponentCreation |
| observeComponentCreation2 | getOrCreateRecycleManager | getRecycleManager | hasRecycleManager |
| initRecycleManager | rebuildUpdateFunc | observeRecycleComponentCreation | aboutToReuseInternal |
| stopRecursiveRecycle | aboutToRecycleInternal | recycleSelf | isRecycled |
| UpdateLazyForEachElements | createStorageLink | createStorageProp | createLocalStorageLink |
| createLocalStorageProp | debugInfoView | debugInfoViewInternal | debugInfoDirtyDescendantElementIds |
| __mkRepeatAPI | reuseOrCreateNewComponent | dirtDescendantElementIds_ | monitorIdsDelayedUpdate |
| monitorIdsDelayedUpdateForAddMonitor_ | computedIdsDelayedUpdate | recyclePoolV2_ | resetStateVarsOnReuse |
| aboutToReuseInternals | resetMonitorsOnReuse | resetComputed | resetConsumer |
| initParam | updateParam | resetParam | getViewV2ChildById |
| addDelayedMonitorIdsForAddMonitor | addDelayedComputedIds | inactiveComponents_ | compareNumber |
| currentlyRenderedElmtIdStack_ | dirtRetakenElementIds_ | parent_ | renderingPaused |
| isDeleting_ | isCompFreezeAllowed_ | prebuildFuncQueues | propertyChangedFuncQueues |
| extraInfo_ | __isBlockRecycleOrReuse__ | elmtIdsDelayedUpdate_ | prebuildPhase_ |
| isPrebuilding_ | prebuildingElmtId_ | doRecycle | doReuse |
| nativeViewPartialUpdate | create | createRecycle | markNeedUpdate |
| syncInstanceId | restoreInstanceId | getInstanceId | markStatic |
| finishUpdateFunc | setCardId | getCardId | elmtIdExists |
| isLazyItemRender | isFirstRender | findChildByIdForPreview | resetRecycleCustomNode |
| queryNavDestinationInfo | queryNavigationInfo | queryRouterPageInfo | getUIContext |
| sendStateInfo | getUniqueId | setIsV2 | getDialogController |
| allowReusableV2Descendant | id__ | updateId | scheduleDelayedUpdate |
| setParent | getParent | removeChild | addChild |
| isDeleting | setDeleting | setDeleteStatusRecursively | setActiveCount |
| getChildViewV2ForElmtId | debugInfoRegisteredElmtIds | debugInfoElmtIds | dumpStateVars |
| isViewActive | dumpReport | forceCompleteRerender | __ClearAllRecycle__PUV2ViewBase__Internal |
| hasNodeUpdateFunc | pauseRendering | restoreRendering | forEachUpdateFunction |
| getNodeById | getCurrentlyRenderedElmtId | debugInfoViewHierarchy | debugInfoUpdateFuncByElmtId |
| debugInfoInactiveComponents | findViewInHierarchy | onDumpInfo | printDFXHeader |
| processOnDumpCommands | traverseChildDoRecycleOrReuse | processPropertyChangedFuncQueue | setPrebuildPhase |
| isNeedBuildPrebuildCmd | prebuildComponent | isEnablePrebuildInMultiFrame | ifElseBranchUpdateFunctionDirtyRetaken |
| onDumpInspector | activeCount_ | isView_ | childrenWeakrefMap_ |
| builderNodeWeakrefMap_ | updateFuncByElmtId | id_ | shareLocalStorage_ |
| __parentViewBuildNode__ | __enableBuilderNodeConsume__ | __elmtId2Repeat___ | arkThemeScopeManager |
| setArkThemeScopeManager | onWillApplyThemeInternally | getShareLocalStorage | setShareLocalStorage |
| propagateToChildren | propagateToChildrenToConnected | propagateToChildrenToDisconnected | addChildBuilderNode |
| setParentBuilderNode__ | removeChildBuilderNode | clearChildBuilderNode | getChildById |
| purgeDeletedElmtIds | updateStateVarsOfChildByElmtId | createOrGetNode | ifElseBranchUpdateFunction |

> 高频禁区：`rerender/aboutToAppear/aboutToDisappear/aboutToReuse/aboutToRecycle/initialRender/updateStateVars/getUIContext/observeComponentCreation/create/setParent/getParent/addChild/removeChild/markNeedUpdate/forceRerenderNode/findProvidePU__/isViewV2/localStorage_/id__/elmtIdsDelayedUpdate/recycleManager_` 等。`getUIContext` 本身也是保留名，不要 shadow。

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `struct Button {}` | `struct MyButton {}` | 与系统组件名冲突 |
| `@State value: string = ''` | `@State currentValue: string = ''` | 与 `.value()` 冲突 → 10505001 |
| `@State direction: number = 0` | `@State moveDirection: number = 0` | 与 `.direction` 冲突 |
| `@State position: number = 0` | `@State slotPosition: number = 0` | 与 `.position` 冲突 |
| 变量命名 `rerender` | `rerenderValue` | 与框架保留字冲突 |

## 参考

- 容器直接子组件约束见 [16-layout](12-layout.md)
- 成员变量命名与链式方法冲突（错误码 10505001）