# 综合应用页面骨架案例集

## 功能点典型使用场景对比

| 页面骨架类型 | 典型使用场景 | 核心能力 | 不适用场景 |
|------------|------------|---------|-----------|
| 垂类App基础骨架（Navigation+断点+Tabs） | 资讯/社交/电商App，手机底部Tab↔平板侧边栏 | 页面栈管理+多设备适配+响应式布局 | 单页面无导航的简单应用 |
| 地图导航综合页面（Stack层叠+浮动面板） | 地图导航App，全屏地图+浮动控件+底部抽屉 | 层叠布局+独立浮层显隐+手势拖拽 | 标准线性排列的内容页面 |

---

## 场景一：构建资讯/社交/电商垂类App基础页面骨架，多设备动态适配

**场景示例描述**：构建资讯/社交/电商等垂类App的基础页面骨架，需要综合考虑顶部搜索栏（Search+Row）、内容区域、底部多页签TabBar的布局组合，并根据设备类型（手机/平板/折叠屏）动态调整页面结构（如手机端单栏+底部Tab，平板端侧边栏+内容区双栏/三栏布局）。

**解决方案**：使用 Navigation 作为根容器，结合断点系统（WidthBreakpoint/HeightBreakpoint），内部使用 Row/Column 构建导航栏和内容区，内容区根据不同的垂类选择不同的响应式布局（如 GridRow、List、WaterFlow 等），底部使用 Tabs 或自定义 TabBar 组件。综合构成要点：Navigation 提供页面栈管理 + 断点提供设备适配 + Row/Column 提供基础布局 + 内容区响应式布局 + Tabs 提供底部导航，多种组件协同构建完整的垂类应用基础骨架。

```typescript
// === 断点状态：宽/高断点均需 @Watch（折叠屏展开↔折叠时宽高同时变化）===
@StorageProp('currentWidthBreakpoint') @Watch('onBreakpointChange')
currentWidthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
@StorageProp('currentHeightBreakpoint') @Watch('onBreakpointChange')
currentHeightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_LG;

// === BreakpointType: 字体尺寸、图标尺寸、内容边距、列表列数按断点缩放 ===
private titleFont: BreakpointType<number> = new BreakpointType(18, 20, 24);
private contentPadding: BreakpointType<number> = new BreakpointType(16, 24, 48);
private listLanes: BreakpointType<number> = new BreakpointType(1, 2, 3);
private flowColumns: BreakpointType<number> = new BreakpointType(2, 3, 4);

// === 断点回调：双向完整映射 ===
onBreakpointChange(): void {
  this.isSmallScreen = this.currentWidthBp === WidthBreakpoint.WIDTH_SM ||
    this.currentWidthBp === WidthBreakpoint.WIDTH_XS;
  this.isLargeScreen = this.currentWidthBp === WidthBreakpoint.WIDTH_LG ||
    this.currentWidthBp === WidthBreakpoint.WIDTH_XL;
  // 小方形屏 = 横向sm + 纵向md
  this.isSmallSquareScreen = this.currentWidthBp === WidthBreakpoint.WIDTH_SM &&
    this.currentHeightBp === HeightBreakpoint.HEIGHT_MD;
}

build() {
  // Navigation 根容器：提供页面栈管理
  Navigation(this.pathStack) {
    Column() {
      // 顶部导航栏：小方形屏紧凑布局 / 大屏标题+搜索聚合 / 手机竖屏分行
      this.TopBar()

      // Tabs：底部导航(sm) ↔ 侧边导航(lg)（挪移布局）
      Tabs({
        barPosition: this.isLargeScreen ? BarPosition.Start : BarPosition.End,
        index: this.currentTab
      }) {
        TabContent() { this.NewsContent() }     // List + lanes 重复布局
          .tabBar(this.TabBarBuilder('首页', 0))
        TabContent() { this.ProductContent() }   // GridRow 栅格布局
          .tabBar(this.TabBarBuilder('商品', 1))
        TabContent() { this.SocialContent() }    // WaterFlow 瀑布流布局
          .tabBar(this.TabBarBuilder('社区', 2))
      }
      .vertical(this.isLargeScreen)              // 大屏侧边导航纵向排列
      .barWidth(this.isLargeScreen ? 96 : '100%')
      .barHeight(this.isLargeScreen ? '100%' : 56)
      .barMode(this.isLargeScreen ? BarMode.Scrollable : BarMode.Fixed,
        { nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER })
      .layoutWeight(1)
    }
  }
  .mode(NavigationMode.Stack)
  .hideTitleBar(true)
  .navDestination(this.PageMap)
}

// === 顶部导航栏：按设备形态切换布局 ===
@Builder TopBar() {
  if (this.isSmallSquareScreen) {
    // 小方形屏：搜索框→图标，标题栏紧凑
    Row() {
      Text('资讯').fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
      Text('🔍').fontSize(20).onClick(() => {})
    }.width('100%').height(44).padding({ left: 12, right: 12 })
  } else if (this.isLargeScreen) {
    // 大屏：标题+搜索框同行聚合
    Row() {
      Text('资讯').fontSize(this.titleFont.getValue(this.currentWidthBp))
        .fontWeight(FontWeight.Bold).margin({ right: 24 })
      Search({ placeholder: '搜索资讯、商品、用户...' }).layoutWeight(1).height(36)
    }.width('100%').height(56).padding({ left: 24, right: 24 })
  } else {
    // 手机竖屏：标题和搜索框分行
    // ...
  }
}

// === 首页内容：List + lanes 重复布局，轮播作为 ListItemGroup header ===
@Builder NewsContent() {
  List({ space: this.listSpace.getValue(this.currentWidthBp) }) {
    ListItemGroup({ header: this.CarouselHeader }) {
      ForEach(this.getNewsItems(), (item: NewsItem, index: number) => {
        ListItem() {
          Row() {
            Column({ space: 4 }) {
              Text(item.title).fontSize(this.bodyFont.getValue(this.currentWidthBp))
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              // ...来源、时间
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Image(this.getImage(index)).width(80).height(60)
              .objectFit(ImageFit.Cover).borderRadius(4)
          }.width('100%').padding(12)
          .onClick(() => { this.pathStack.pushPath({ name: 'newsDetail' }); })
        }
      })
    }
  }
  .lanes(this.listLanes.getValue(this.currentWidthBp),
    this.listSpace.getValue(this.currentWidthBp))
  // ...
}

// === 商品内容：GridRow + GridCol 栅格布局 ===
@Builder ProductContent() {
  Scroll() {
    GridRow({ columns: { sm: 4, md: 6, lg: 12 }, gutter: { x: 12, y: 12 } }) {
      ForEach(this.getProducts(), (item: ProductItem, index: number) => {
        GridCol({ span: { sm: 2, md: 2, lg: 3 } }) {
          Column({ space: 8 }) {
            Image(this.getImage(index)).width('100%').aspectRatio(1).objectFit(ImageFit.Cover)
            Text(item.name).fontSize(this.bodyFont.getValue(this.currentWidthBp)).maxLines(1)
            // ...价格、标签
          }.width('100%').padding(8)
        }
      })
    }
  }
  // ...
}

// === 社区内容：WaterFlow 瀑布流布局 ===
@Builder SocialContent() {
  WaterFlow() {
    ForEach(this.getSocialPosts(), (item: SocialPost, index: number) => {
      FlowItem() {
        Column({ space: 8 }) {
          // ...用户信息、内容文本、配图、点赞
        }.width('100%').padding(12)
      }
    })
  }
  .columnsTemplate(`repeat(${this.flowColumns.getValue(this.currentWidthBp)}, 1fr)`)
  // ...
}
```

### WidthBreakpoint 枚举

| 枚举值 | 宽度范围 | 设备类型 |
|--------|---------|---------|
| `WIDTH_XS` | < 600vp | 小手机、折叠态内屏 |
| `WIDTH_SM` | 600–840vp | 手机竖屏 |
| `WIDTH_MD` | 840–1200vp | 折叠屏展开、小平板 |
| `WIDTH_LG` | 1200–1600vp | 平板横屏、2in1 |
| `WIDTH_XL` | ≥ 1600vp | 大屏设备 |

### HeightBreakpoint 枚举

| 枚举值 | 高度范围 | 设备类型 |
|--------|---------|---------|
| `HEIGHT_SM` | < 320vp | 折叠态横屏 |
| `HEIGHT_MD` | 320–600vp | 手机横屏、小方形屏 |
| `HEIGHT_LG` | 600–840vp | 手机竖屏 |
| `HEIGHT_XL` | ≥ 840vp | 平板、大屏 |

### NavigationMode 枚举

| 枚举值 | 行为 | 适用场景 |
|--------|------|---------|
| `Stack` | 页面栈推入式导航 | 手机端单栏 |
| `Split` | 分栏式导航（左列表+右详情） | 平板/大屏 |
| `Auto` | 根据宽度自动切换 Stack/Split | 跨设备适配 |

### BarPosition 枚举

| 枚举值 | 位置 | 适用场景 |
|--------|------|---------|
| `Start` | 侧边（垂直布局时左侧） | 大屏侧边导航 |
| `End` | 底部（水平布局时底部） | 手机底部导航 |

### BarMode 枚举

| 枚举值 | 行为 | 适用场景 |
|--------|------|---------|
| `Fixed` | 固定宽度，不滚动 | 手机端少量Tab |
| `Scrollable` | 可滚动，Tab宽度自适应 | 大屏多Tab侧边导航 |
| `Auto` | 根据内容自动选择 | 通用 |

### LayoutStyle 枚举（nonScrollableLayoutStyle）

| 枚举值 | 布局方式 |
|--------|---------|
| `ALWAYS_CENTER` | 始终居中 |
| `SPACE_BETWEEN_OR_CENTER` | 间距不足时居中，足够时均匀分布 |
| `AVERAGE_INTERVAL` | 平均间距分布 |

### BreakpointType 用法

| 方法 | 作用 | 示例 |
|------|-----|------|
| `new BreakpointType(sm, md, lg)` | 按断点定义不同值 | `new BreakpointType(18, 20, 24)` |
| `getValue(breakpoint)` | 获取当前断点对应的值 | `this.titleFont.getValue(this.currentWidthBp)` |

### ImageFit 枚举

| 枚举值 | 填充方式 |
|--------|---------|
| `Contain` | 等比缩放，完整显示在容器内 |
| `Cover` | 等比缩放，填满容器，可能裁剪 |
| `Fill` | 拉伸填满容器，可能变形 |
| `None` | 原始大小，不缩放 |
| `ScaleDown` | 等比缩放，不超出原始大小 |

### TextOverflow 枚举

| 枚举值 | 行为 |
|--------|------|
| `Ellipsis` | 超出部分以省略号显示 |
| `Clip` | 超出部分直接裁剪 |
| `None` | 不处理溢出 |

### 场景一 禁止写法

| 禁止写法 | 后果 | 正确做法 |
|---------|------|---------|
| 使用 `router.pushUrl` / `router.replaceUrl` 代替 Navigation + NavPathStack | 页面栈与 NavDestination 路由表割裂,无法统一管理,返回链路不可控 | 使用 `Navigation(this.pathStack)` + `pathStack.pushPath({ name: ... })` + `.navDestination(this.PageMap)` 注册路由表 |
| 不监听断点变化,硬编码设备类型判断(如 `if (deviceType === 'phone')`) | 无法适配折叠屏展开/折叠、平板旋转等动态形态切换 | 使用 `@StorageProp('currentWidthBreakpoint')` + `@StorageProp('currentHeightBreakpoint')` + `@Watch('onBreakpointChange')` 双向映射宽高断点 |
| 不使用 BreakpointType,硬编码字体/边距/列数(如 `fontSize(18)` 固定值) | 断点切换时尺寸不随设备形态变化,大屏字体过小或小屏过大 | 使用 `new BreakpointType(sm, md, lg)` 定义差异化值,通过 `getValue(this.currentWidthBp)` 动态取值 |
| Tabs 不配置 `barPosition` / `vertical` 切换 | 大屏仍显示底部导航,未实现侧边导航挪移,浪费横向空间 | 按 `this.isLargeScreen` 切换 `barPosition(BarPosition.Start/End)` + `vertical(true/false)` |

---

## 场景二：构建地图导航类App综合页面，层叠浮层+抽屉面板+手势交互

**场景示例描述**：构建地图导航类App的综合页面，需要同时处理全屏地图（底层）+ 浮动面板（POI详情）+ 交互控制按钮（定位、缩放、图层切换）的复杂层叠布局，各浮层需要独立控制显隐和位置。

**解决方案**：使用 Stack 作为根容器，地图组件占满全屏作为底层，详情面板使用 Column + List + RelativeContainer 构建并通过 alignContent 实现底部抽屉的效果，控制按钮组使用 Row + Column 排列并通过 alignContent 定位在右上角，各浮层通过状态变量独立控制显隐。综合构成要点：Stack 提供层叠能力 + zIndex 提供层级控制 + Column/Row/List/RelativeContainer 提供各浮层内部布局，多种组件协同构建复杂的地图导航交互界面。

```typescript
@State showLayerControl: boolean = false;  // 图层面板显隐
@State showTopBar: boolean = true;          // 顶部栏显隐
@State currentZoom: number = 17;            // 地图缩放级别
@State drawerHeight: number = 120;          // 抽屉高度
@State mapOffsetX: number = 0;              // 地图平移X
@State mapOffsetY: number = 0;              // 地图平移Y
@State mapScale: number = 2.3;              // 地图缩放比例

// === 安全区域获取 ===
private fetchSafeArea() {
  const uiContext = this.getUIContext();
  const context = uiContext.getHostContext();
  window.getLastWindow(context).then((win: window.Window) => {
    const avoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    this.statusBarHeight = uiContext.px2vp(avoidArea.leftRect.height);
    this.navBarHeight = uiContext.px2vp(avoidArea.leftRect.height);
    // ...
  });
}

// === 底层：地图占满全屏，支持滑动+缩放手势 ===
@Builder MapBackground() {
  Stack() {
    Image($r('app.media.maps'))
      .width('100%').height('100%').objectFit(ImageFit.Cover)
      .scale({ x: this.mapScale, y: this.mapScale })
      .translate({ x: this.mapOffsetX, y: this.mapOffsetY })
  }
  .width('100%').height('100%').zIndex(0)
  .gesture(
    // 互斥手势组：单指拖动 或 双指缩放
    GestureGroup(GestureMode.Exclusive,
      PanGesture()
        .onActionStart(() => { this.mapStartX = this.mapOffsetX; this.mapStartY = this.mapOffsetY; })
        .onActionUpdate((event: GestureEvent) => {
          this.mapOffsetX = this.mapStartX + event.offsetX;
          this.mapOffsetY = this.mapStartY + event.offsetY;
        }),
      PinchGesture({ fingers: 2 })
        .onActionUpdate((event: GestureEvent) => {
          this.mapScale = Math.max(0.5, Math.min(3.0, event.scale));
        })
    )
  )
}

// === 顶部导航栏：浮动层，毛玻璃材质 ===
@Builder TopNavBar() {
  Row({ space: 12 }) {
    Button('←').width(36).height(36)
      .backgroundColor(Color.Transparent)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
      .onClick(() => { router.back(); })
    Text('地图导航').fontSize(18).fontWeight(FontWeight.Bold).layoutWeight(1)
    // ...
  }
  .width('100%')
  .padding({ left: 12, right: 12, top: this.statusBarHeight, bottom: 10 })
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
}

// === 控制按钮组：缩放+图层+定位，通过外层 alignContent 定位右下角 ===
@Builder ControlButtonGroup() {
  Column({ space: 10 }) {
    // 缩放按钮组：纵向排列 + / -
    Column({ space: 10 }) {
      Button('+').width(44).height(44).backgroundColor(Color.White)
        .onClick(() => { if (this.currentZoom < 20) { this.currentZoom++; } })
      Button('-').width(44).height(44).backgroundColor(Color.White)
        .onClick(() => { if (this.currentZoom > 1) { this.currentZoom--; } })
    }
    // 图层 / 定位按钮：横向排列
    Row({ space: 10 }) {
      Button(this.showLayerControl ? '✕' : '☰').width(44).height(44)
        .onClick(() => { this.showLayerControl = !this.showLayerControl; })
      Button('◎').width(44).height(44).fontColor('#0A59F7')
    }
  }
}

// === 底部抽屉面板：拖拽手柄+Tabs（路线/POI详情），整体响应拖拽手势 ===
@Builder DrawerPanel() {
  Column() {
    // 拖拽手柄
    Row() {
      Column().width(40).height(4).backgroundColor('#CCCCCC').borderRadius(2)
    }.width('100%').height(44).justifyContent(FlexAlign.Center)

    // Tabs 悬浮页签：路线 / POI 详情
    Tabs({ index: this.drawerTabIdx, controller: this.tabController }) {
      TabContent() { Scroll() { Column() { this.RouteContent() } } }
        .tabBar(new SubTabBarStyle('路线').selectedMode(SelectedMode.BOARD).board({ borderRadius: 80 }))
      TabContent() { Scroll() { Column() { this.PoiDetailContent() } } }
        .tabBar(new SubTabBarStyle('详情').selectedMode(SelectedMode.BOARD).board({ borderRadius: 80 }))
    }
    .barPosition(BarPosition.End).barMode(BarMode.Fixed).barOverlap(true).barHeight(48)
    .barFloatingStyle({ barBottomMargin: this.navBarHeight + 8 })
  }
  .width('100%').height(this.drawerHeight)
  .backgroundColor(Color.White)
  .borderRadius({ topLeft: 16, topRight: 16 })
  .parallelGesture(
    PanGesture()
      .onActionStart(() => { this.dragStartHeight = this.drawerHeight; })
      .onActionUpdate((event: GestureEvent) => {
        this.drawerHeight = Math.max(this.collapsedHeight,
          Math.min(this.expandedHeight, this.dragStartHeight - event.offsetY));
      })
      .onActionEnd((event: GestureEvent) => {
        const detents = [this.collapsedHeight, this.midHeight, this.expandedHeight];
        // 快速滑动：按方向跳档；慢速拖拽：吸附最近档位
        let target: number;
        if (Math.abs(event.velocityY) > 1000) {
          // ...快速滑动跳档逻辑
        } else {
          // ...慢速拖拽吸附逻辑
        }
        animateTo({ duration: 250, curve: Curve.EaseOut }, () => {
          this.drawerHeight = target;
        });
      })
  )
}

// === POI 详情：RelativeContainer 构建复杂元素布局 ===
@Builder PoiDetailContent() {
  RelativeContainer() {
    Text(this.pois[this.selectedPoiIdx].name).id('poiName')
      .fontSize(18).fontWeight(FontWeight.Bold)
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
    Text(`评分: ★★★★☆ ${this.pois[this.selectedPoiIdx].rating}分`).id('rating')
      .alignRules({ top: { anchor: 'poiName', align: VerticalAlign.Bottom }, /* ... */ })
    // ...距离、地址、操作按钮
  }.width('100%')
}

build() {
  // 根容器：Stack 层叠，地图占满全屏作为底层
  Stack() {
    // 底层：地图
    this.MapBackground()

    // 顶部导航栏（顶部对齐）
    if (this.showTopBar) {
      Stack() { this.TopNavBar() }
        .width('100%').height('100%')
        .alignContent(Alignment.Top)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(2)
    }

    // 图层选择面板（右下角控制按钮上方）
    if (this.showLayerControl) {
      Stack() { this.LayerPanelContent() }
        .width('100%').height('100%')
        .alignContent(Alignment.BottomEnd)
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(9)
    }

    // 控制按钮组（右下角）
    Stack() { this.ControlButtonGroup() }
      .width('100%').height('100%')
      .alignContent(Alignment.BottomEnd)
      .opacity(/* 窄屏随抽屉展开渐隐 */)
      .hitTestBehavior(HitTestMode.Transparent)
      .zIndex(10)

    // 底部抽屉面板（底部对齐）
    Stack() {
      Stack() { this.DrawerPanel() }
        .width(this.drawerWidthPercent).height('100%')
        .alignContent(Alignment.Bottom)
        .expandSafeArea([SafeAreaType.SYSTEM])
    }
    .width('100%').height('100%')
    .alignContent(Alignment.BottomStart)
    .hitTestBehavior(HitTestMode.Transparent)
    .zIndex(7)
  }
  .width('100%').height('100%')
  .onAreaChange((_, newValue: Area) => {
    this.screenHeight = Number(newValue.height);
    this.midHeight = this.screenHeight * 0.5;
    this.expandedHeight = this.screenHeight * 0.9;
    // 系统断点判断抽屉宽度：sm 100% / md 50% / lg 33.33%
    const bp = this.getUIContext().getWindowWidthBreakpoint();
    if (bp === WidthBreakpoint.WIDTH_LG) {
      this.drawerWidthPercent = '33.33%';
    } else if (bp === WidthBreakpoint.WIDTH_MD) {
      this.drawerWidthPercent = '50%';
    } else {
      this.drawerWidthPercent = '100%';
    }
  })
}
```

### Alignment 枚举（Stack alignContent）

| 枚举值 | 对齐位置 |
|--------|---------|
| `TopStart` | 左上角 |
| `Top` | 顶部居中 |
| `TopEnd` | 右上角 |
| `Start` | 左侧居中 |
| `Center` | 正中 |
| `End` | 右侧居中 |
| `BottomStart` | 左下角 |
| `Bottom` | 底部居中 |
| `BottomEnd` | 右下角 |

### HitTestMode 枚举

| 枚举值 | 行为 | 适用场景 |
|--------|------|---------|
| `Default` | 默认，自身和子节点都参与触摸测试 | 普通可交互区域 |
| `Block` | 自身不响应触摸，阻止子节点和下层接收事件 | 完全屏蔽区域 |
| `Transparent` | 自身不响应触摸，但子节点和下层可接收事件 | 浮层透传容器 |
| `None` | 自身和子节点都不参与触摸测试 | 纯装饰区域 |

### SafeAreaType 枚举

| 枚举值 | 安全区域类型 | 适用场景 |
|--------|------------|---------|
| `SYSTEM` | 状态栏、导航栏等系统区域 | 顶部栏避开状态栏 |
| `CUTOUT` | 刘海屏、打孔屏区域 | 避开刘海遮挡 |
| `KEYBOARD` | 软键盘区域 | 输入框避开键盘 |

### SafeAreaEdge 枚举

| 枚举值 | 边缘方向 |
|--------|---------|
| `TOP` | 顶部边缘 |
| `BOTTOM` | 底部边缘 |
| `LEFT` | 左侧边缘 |
| `RIGHT` | 右侧边缘 |
| `ALL` | 所有边缘 |

### BlurStyle 枚举

| 枚举值 | 毛玻璃效果 | 适用场景 |
|--------|----------|---------|
| `BACKGROUND_THIN` | 背景轻薄模糊 | 顶部栏在地图上 |
| `BACKGROUND_REGULAR` | 背景常规模糊 | 卡片背景 |
| `BACKGROUND_THICK` | 背景厚重模糊 | 弹窗背景 |
| `BACKGROUND_ULTRA_THICK` | 背景超厚模糊 | 强调区域 |
| `COMPONENT_THIN` | 组件轻薄模糊 | 按钮在地图上 |
| `COMPONENT_REGULAR` | 组件常规模糊 | 控件背景 |
| `COMPONENT_THICK` | 组件厚重模糊 | 强调控件 |
| `COMPONENT_ULTRA_THICK` | 组件超厚模糊 | 重点控件 |

### GestureMode 枚举（GestureGroup）

| 枚举值 | 行为 | 适用场景 |
|--------|------|---------|
| `Sequence` | 序列手势，按顺序依次识别 | 多步骤复合手势 |
| `Parallel` | 并行手势，同时识别所有手势 | 多手势同时生效 |
| `Exclusive` | 互斥手势，仅识别最先触发的手势 | 拖拽与缩放二选一 |

### SelectedMode 枚举（SubTabBarStyle）

| 枚举值 | 选中样式 | 适用场景 |
|--------|---------|---------|
| `INDICATOR` | 底部指示器 | 常规页签 |
| `BOARD` | 边框包裹 | 抽屉页签 |
| `LABEL` | 标签高亮 | 标签式页签 |

### Curve 枚举（animateTo 动画曲线）

| 枚举值 | 曲线效果 | 适用场景 |
|--------|---------|---------|
| `Linear` | 匀速线性 | 进度条 |
| `Ease` | 先快后慢 | 通用过渡 |
| `EaseIn` | 缓入（先慢后快） | 从静止启动 |
| `EaseOut` | 缓出（先快后慢） | 减速停止 |
| `EaseInOut` | 缓入缓出 | 抽屉吸附 |
| `FastOutSlowIn` | 快出慢入 | Material 风格 |
| `LinearOutSlowIn` | 线性出慢入 | 展开 |
| `FastLinearInSlowOut` | 快线入慢出 | 收起 |

### AvoidAreaType 枚举（window.getWindowAvoidArea）

| 枚举值 | 避让区域 | 适用场景 |
|--------|---------|---------|
| `TYPE_SYSTEM` | 状态栏、导航栏 | 获取安全区高度 |
| `TYPE_CUTOUT` | 刘海/打孔区域 | 避开刘海 |
| `TYPE_SYSTEM_INDICATOR` | 系统指示条 | 避开手势指示条 |
| `TYPE_KEYBOARD` | 软键盘区域 | 避开键盘 |

### 场景二 禁止写法

| 禁止写法 | 后果 | 正确做法 |
|---------|------|---------|
| 使用 Column + 绝对定位(`position`/`offset`)代替 Stack 层叠 | 无法使用 `alignContent` 对齐浮层、无法用 `zIndex` 控制层级、浮层覆盖关系混乱 | 使用 `Stack` 根容器 + `alignContent(Alignment.Top/BottomEnd/...)` 定位浮层 + `zIndex(n)` 控制层级 |
| 不使用 `GestureGroup(GestureMode.Exclusive, ...)` 互斥手势组 | 单指拖动与双指缩放同时触发,手势冲突导致地图平移和缩放互相干扰 | 使用 `GestureGroup(GestureMode.Exclusive, PanGesture(...), PinchGesture(...))` 互斥识别,仅响应最先触发的手势 |
| 浮层容器不设 `hitTestBehavior(HitTestMode.Transparent)` | 浮层占满全屏遮挡地图,地图无法接收触摸事件,用户无法拖动/缩放地图 | 浮层外层 `Stack` 设置 `hitTestBehavior(HitTestMode.Transparent)` 实现事件透传,子节点仍可交互 |
| 抽屉 `onActionEnd` 不使用 `animateTo` 直接设置 `drawerHeight` | 高度跳变无平滑过渡,用户体验生硬 | 使用 `animateTo({ duration: 250, curve: Curve.EaseOut }, () => { this.drawerHeight = target; })` 实现吸附动画 |
| 顶部栏不使用 `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])` | 顶部栏被状态栏遮挡,内容下沉,与地图重叠区域不自然 | 使用 `expandSafeArea` 适配状态栏 + `padding({ top: this.statusBarHeight })` 避开状态栏高度 |
