# 功能性测试用例

本文件是默认门禁主集，共46例，侧重独立性能机制及必要的反误报边界。每例独立执行，仅把“输入”交给被测模型。

判定围绕建议是否有代码/业务依据、机制与版本是否正确、是否保持相关语义，以及验证方法是否能解释当前目标。未实测的变化写为预期，不编造接口、耗时或收益。有发现时只输出相关问题与验证，正常写法及无关覆盖表留在内部；无明确问题时简短说明范围。

功能语义可在建议或代码中体现，输入明确要求功能测试时才判操作清单。需要代码整改且信息充分时，检查是否给出可定位的最小diff或可替换代码，必要字段、方法和调用处衔接完整；不强制同时给两种形式或复制整个ETS，无需修改或信息不足时不为凑代码追加整改。验证只要求当前目标下适用的方法，两种均适用时中性并列供选择，不要求所有Trace事件、教程和固定措辞。下列每例列出本例目标与条件；“或”“可”列出的方案按实际选择判定，只检查所采用路径的前提与正确性，不要求枚举全部替代路线。合理等价方案按相同目标判定，主动说错机制、遗漏目标问题、虚构接口/实测或破坏语义仍失败；未要求的背景段落和交互不单独作为失败理由。

---


### 测试用例：FUNC-REUSE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component、transition

#### 输入

API26、状态管理V1。同一父组件中反复点击“切换记录”，组件频繁创建、销毁，切换响应慢。请减少重复创建、销毁的开销，保留现有交互和内容更新。

```ts
class RecordMetrics {
  static creates: number = 0;
  static reuses: number = 0;
}
@Component
struct RecordTile {
  @State title: string = '';
  @State detail: string = '';
  @State expanded: boolean = true;
  private labels: string[] = ['编号', '主题', '内容', '状态', '来源', '分类', '备注', '关联'];
  aboutToAppear(): void { RecordMetrics.creates++; }
  build() {
    Column({ space: 4 }) {
      Text(this.title).id('record-title')
      Text(this.detail).id('record-detail')
      Button(this.expanded ? '折叠' : '展开').id('record-expand')
        .onClick(() => { this.expanded = !this.expanded; })
      if (this.expanded) {
        ForEach(this.labels, (label: string) => {
          Row({ space: 8 }) { Text(label); Text(this.title); Text(this.detail) }
        }, (label: string) => label)
      }
    }
  }
}
@Entry
@Component
struct RecordPage {
  @State show: boolean = true;
  @State title: string = '记录0';
  @State detail: string = '详情0';
  @State snapshot: string = '';
  private sequence: number = 0;
  aboutToAppear(): void { RecordMetrics.creates = 0; RecordMetrics.reuses = 0; }
  toggle(): void {
    if (this.show) {
      this.show = false;
    } else {
      this.sequence++;
      this.title = '记录' + this.sequence.toString();
      this.detail = '详情' + this.sequence.toString();
      this.show = true;
    }
  }
  build() {
    Column({ space: 10 }) {
      Button('切换记录').id('record-toggle').onClick(() => { this.toggle(); })
      Button('读取计数').id('record-snapshot').onClick(() => {
        this.snapshot = 'creates=' + RecordMetrics.creates.toString()
          + ';reuses=' + RecordMetrics.reuses.toString();
      })
      Text(this.snapshot).id('record-metrics')
      if (this.show) {
        RecordTile({ title: this.title, detail: this.detail })
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** RecordPage 的 if 反复移除、显示相同结构的 RecordTile，每次重新创建组件；子组件仍需保留展开交互。
- **修改建议：** 为 RecordTile 添加 @Reusable，在 aboutToReuse 更新 title/detail 并恢复 expanded=true，使用默认复用分组；保留嵌套内容和展开/折叠行为。
- **收益与验证：** 同顺序隐藏、等待、显示新记录，读取 RecordMetrics 比较创建/复用次数；预期后续创建减少、复用增加。

---


### 测试用例：FUNC-WORK-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component、scroll

#### 输入

状态管理V1，固定800项数据，每项 notes 含50个数。列表取数和构建时反复复制、序列化，滑动开销较大。请减少重复计算，保留完整文本和整批更新。

```ts
class NoteRow {
  id: string = '';
  title: string = '';
  notes: number[] = [];
}
class NotesSource implements IDataSource {
  private rows: NoteRow[] = [];
  private listeners: DataChangeListener[] = [];
  constructor() {
    for (let i: number = 0; i < 800; i++) {
      const row: NoteRow = new NoteRow();
      row.id = 'id' + i.toString();
      row.title = '标题' + i.toString();
      for (let j: number = 0; j < 50; j++) { row.notes.push(j); }
      this.rows.push(row);
    }
  }
  totalCount(): number { return this.rows.length; }
  getData(index: number): NoteRow {
    const copied: NoteRow[] = this.rows.map((r: NoteRow): NoteRow => {
      const v: NoteRow = new NoteRow();
      v.id = r.id;
      v.title = r.title;
      v.notes = r.notes.slice();
      return v;
    });
    return copied[index];
  }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) { this.listeners.push(listener); }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index: number = this.listeners.indexOf(listener);
    if (index >= 0) { this.listeners.splice(index, 1); }
  }
}
@Entry
@Component
struct NotesPage {
  private source: NotesSource = new NotesSource();
  build() {
    Column() {
      List() {
        LazyForEach(this.source, (row: NoteRow) => {
          ListItem() { Text(JSON.stringify(row.notes)).fontSize(12) }
        }, (row: NoteRow) => JSON.stringify(row))
      }.width('100%').height(400).cachedCount(1)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** NotesSource.getData 每次复制整表，key 和文本回调重复序列化，增加取数及构建开销。
- **修改建议：** 数据更新时准备显示文本，getData 按索引取数据，key 使用唯一 id，保留完整文本及更新同步。
- **收益与验证：** 在 getData、key 和文本计算处打点；同数据、同滚动路径比较累计 Duration，预期复制和序列化耗时减少。

---


### 测试用例：FUNC-START-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：startup

#### 输入

状态管理V1。首页首屏约显示10条，但固定列表被全量创建，启动创建开销大。请减少首屏外的创建工作，保留全部内容和滚动范围。

```ts
@Entry
@Component
struct LongListPage {
  private items: string[] = [];
  aboutToAppear(): void {
    for (let i: number = 0; i < 1000; i++) { this.items.push('item' + i.toString()); }
  }
  build() {
    Column() {
      List() {
        ForEach(this.items, (item: string) => {
          ListItem() { Text(item).height(40) }
        }, (item: string) => item)
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** LongListPage 用 ForEach 创建完整列表，而首屏只需约10项，额外条目增加启动创建工作。
- **修改建议：** 改为 LazyForEach，提供完整 IDataSource 方法和稳定 key；按可见范围及条目成本选择 cachedCount；保留全部内容、滚动范围和数据通知。
- **收益与验证：** 同数据和缓存条件启动，统计构建至首帧结束的目标 Create[ListItem] 数量，预期初始创建减少；滚动检查内容完整。

---


### 测试用例：FUNC-LIFECYCLE-002

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：startup、transition

#### 输入

API12、状态管理V1。首页 aboutToAppear 使用 async/await 执行统计计算，进入时同步工作较多。统计结果不影响首屏，请减少计算开销，保留两项结果和离页后的失效处理。

```ts
@Entry
@Component
struct AsyncStatsPage {
  @State beforeAwait: number = 0;
  @State afterAwait: number = 0;
  private active: boolean = true;
  private sumValues(): number {
    let total: number = 0;
    for (let i: number = 0; i < 10000000; i++) { total += Math.sqrt(i); }
    return total;
  }
  private prepareValue(): Promise<number> {
    const total: number = this.sumValues();
    return Promise.resolve(total);
  }
  async aboutToAppear(): Promise<void> {
    this.beforeAwait = this.sumValues();
    const prepared: number = await this.prepareValue();
    if (this.active) {
      this.afterAwait = prepared + this.sumValues();
    }
  }
  aboutToDisappear(): void { this.active = false; }
  build() {
    Column({ space: 10 }) {
      Text('统计面板入口')
      Text(this.beforeAwait.toString())
      Text(this.afterAwait.toString())
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** aboutToAppear 首句及 prepareValue 内的计算在 await 挂起前同步执行，续体又计算一次；async/Promise.resolve 均未把计算移出 UI 线程。
- **修改建议：** 对不变数据计算一次并复用；需要后台执行时采用适用 TaskPool/Worker；保持 beforeAwait 为一份结果、afterAwait 为两倍结果，离页后停止提交。
- **收益与验证：** 分别包围三处 sumValues 打点，同数据比较次数、Duration及线程；预期重复计算减少，后台方案减少UI线程计算。

---


### 测试用例：FUNC-REPEAT-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component、scroll

#### 输入

API12、状态管理V2。500项固定数据，每项 payload 含40个数，id 唯一不变。Repeat 的 key 反复序列化整对象，请减少滚动中的 key 计算，保留内容和数据更新。

```ts
class CatalogRow {
  id: string = '';
  title: string = '';
  payload: number[] = [];
}
@Entry
@ComponentV2
struct RepeatKeyPage {
  @Local rows: CatalogRow[] = [];
  aboutToAppear(): void {
    const next: CatalogRow[] = [];
    for (let i: number = 0; i < 500; i++) {
      const row: CatalogRow = new CatalogRow();
      row.id = 'id-' + i.toString();
      row.title = '条目' + i.toString();
      for (let j: number = 0; j < 40; j++) { row.payload.push(j); }
      next.push(row);
    }
    this.rows = next;
  }
  build() {
    Column() {
      List() {
        Repeat<CatalogRow>(this.rows)
          .each((ri: RepeatItem<CatalogRow>) => {
            ListItem() { Text(ri.item.title).fontSize(12) }
          })
          .key((row: CatalogRow) => JSON.stringify(row))
          .virtualScroll({ totalCount: this.rows.length })
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** Repeat.key 对500项对象执行 JSON.stringify，重复处理 payload，且内容变化会改变 key；现有 V2 each+virtualScroll 组合合法。
- **修改建议：** key 改为稳定唯一 id，保留 RepeatItem 的当前项响应绑定及原虚拟滚动方式；同ID替换、重排后内容与点击身份保持正确。
- **收益与验证：** 在 key 回调打点，同数据和滚动路径比较累计 Duration；预期序列化成本减少，同ID更新和重排后显示正确。

---


### 测试用例：FUNC-REUSE-003

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component、transition

#### 输入

同一父组件反复显示新记录，组件结构相同，但每条唯一ID都使用不同复用分组，旧记录不再回访。请减少重复创建，保留标题和详情更新。

```ts
@Reusable
@Component
struct RecordTile {
  @State title: string = '';
  @State detail: string = '';
  private labels: string[] = ['编号', '主题', '内容', '状态', '来源', '分类', '备注', '关联'];
  aboutToReuse(params: Record<string, string>): void {
    this.title = params.title;
    this.detail = params.detail;
  }
  build() {
    Column({ space: 4 }) {
      Text(this.title)
      Text(this.detail)
      ForEach(this.labels, (label: string) => {
        Row({ space: 8 }) { Text(label); Text(this.title); Text(this.detail) }
      }, (label: string) => label)
    }
  }
}
@Entry
@Component
struct RecordPage {
  @State show: boolean = true;
  @State recordId: string = 'record-0';
  @State title: string = '记录0';
  @State detail: string = '详情0';
  private sequence: number = 0;
  toggle(): void {
    if (this.show) {
      this.show = false;
    } else {
      this.sequence++;
      this.recordId = 'record-' + this.sequence.toString();
      this.title = '记录' + this.sequence.toString();
      this.detail = '详情' + this.sequence.toString();
      this.show = true;
    }
  }
  build() {
    Column({ space: 10 }) {
      Button('切换记录').onClick(() => { this.toggle(); })
      if (this.show) {
        RecordTile({ title: this.title, detail: this.detail }).reuseId(this.recordId)
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** RecordTile 按每条不再回访的唯一记录ID设置 reuseId，使相同结构的新记录无法使用前一组已回收实例。
- **修改建议：** 移除按记录ID设置的 reuseId，使用默认组或固定结构标识，保留 @Reusable；继续同步 title/detail，保留原状态和交互。
- **收益与验证：** 在创建和 aboutToReuse 中计数，同顺序显示新ID记录；预期后续创建减少、复用增加。

---


### 测试用例：FUNC-FRAME-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、Stage/V1。按钮通过 onFrame 逐帧驱动0↔200vp、1000ms匀速位移，回调没有其他业务。请减少逐帧开销并给最小修改代码，保留动画期间禁点、完成状态和销毁处理。

```ts
import { FrameCallback, UIContext } from '@kit.ArkUI';

class MoveFrameTask extends FrameCallback {
  private firstFrameTime: number = -1;
  private active: boolean = true;
  private context: UIContext;
  private onProgress: (progress: number) => void;

  constructor(context: UIContext, onProgress: (progress: number) => void) {
    super();
    this.context = context;
    this.onProgress = onProgress;
  }

  onFrame(frameTimeInNano: number): void {
    if (!this.active) { return; }
    if (this.firstFrameTime < 0) { this.firstFrameTime = frameTimeInNano; }
    const elapsedMs: number = (frameTimeInNano - this.firstFrameTime) / 1000000;
    const progress: number = Math.min(elapsedMs / 1000, 1);
    if (progress >= 1) { this.active = false; }
    this.onProgress(progress);
    if (this.active) {
      this.context.postFrameCallback(this);
    }
  }

  cancel(): void {
    this.active = false;
  }
}

@Entry
@Component
struct FrameMovePage {
  @State offsetX: number = 0;
  @State running: boolean = false;
  private task: MoveFrameTask | undefined = undefined;

  private play(): void {
    if (this.running) { return; }
    const fromX: number = this.offsetX;
    const toX: number = fromX === 0 ? 200 : 0;
    this.running = true;
    const context: UIContext = this.getUIContext();
    this.task = new MoveFrameTask(context, (progress: number): void => {
      this.offsetX = fromX + (toX - fromX) * progress;
      if (progress >= 1) {
        this.running = false;
        this.task = undefined;
      }
    });
    context.postFrameCallback(this.task);
  }

  aboutToDisappear(): void {
    this.task?.cancel();
    this.task = undefined;
  }

  build() {
    Column({ space: 16 }) {
      Button('移动到另一端').id('frame-move-start')
        .enabled(!this.running)
        .onClick(() => { this.play(); })
      Row() {
        Text('方块')
          .width(40).height(40)
          .backgroundColor('#007DFF').fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .translate({ x: this.offsetX })
      }.width(240).height(40)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** MoveFrameTask.onFrame 通过再次 postFrameCallback 形成有限动画任务链，逐帧计算进度并写 offsetX；没有必须逐帧执行的业务工作。
- **修改建议：** 给出 UIContext.animateTo 最小替换代码，一次提交目标 offsetX，使用1000ms和 Curve.Linear；保留0/200vp往返、动画期间禁点、完成后恢复按钮及销毁失效。
- **收益与验证：** 在原 onFrame 更新段打点；同参数比较完整动画窗口的回调次数和UI工作，预期手动逐帧工作减少、往返效果保持。

---



### 测试用例：FUNC-BUILDERNODE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component

#### 输入

API12、Stage/V1、同一UIContext。点击“更新文案”时，相同Text子树反复销毁重建。页面一直使用同一控制器，请减少更新开销，保留文案更新和离页释放。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class CaptionParams {
  caption: string = '';

  constructor(caption: string) {
    this.caption = caption;
  }
}

@Builder
function captionContent(data: CaptionParams) {
  Text(data.caption).fontSize(20)
}

class CaptionController extends NodeController {
  private node: BuilderNode<[CaptionParams]> | null = null;
  private caption: string = '初始文案';

  makeNode(context: UIContext): FrameNode | null {
    this.node?.dispose();
    this.node = new BuilderNode<[CaptionParams]>(context);
    this.node.build(wrapBuilder<[CaptionParams]>(captionContent), new CaptionParams(this.caption));
    return this.node.getFrameNode();
  }

  setCaption(caption: string): void {
    this.caption = caption;
    this.rebuild();
  }

  release(): void {
    this.node?.dispose();
    this.node = null;
  }
}

@Entry
@Component
struct CaptionPage {
  private controller: CaptionController = new CaptionController();
  private sequence: number = 0;

  private changeCaption(): void {
    this.sequence++;
    this.controller.setCaption('文案' + this.sequence.toString());
  }

  aboutToDisappear(): void {
    this.controller.release();
  }

  build() {
    Column({ space: 12 }) {
      Text('BuilderNode 文案更新示例')
      Button('更新文案').id('caption-update')
        .onClick(() => { this.changeCaption(); })
      NodeContainer(this.controller)
        .id('caption-container')
        .width('100%')
        .height(64)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** changeCaption→setCaption→rebuild→makeNode 路径对同一 Text 子树反复 dispose/new/build，文案变化产生不必要重建。
- **修改建议：** 给出缓存节点和 update 文案的最小diff或可替换实现，必要字段及 makeNode/setCaption 衔接完整；保留 release/dispose、首次创建前的文案和后续更新。
- **收益与验证：** 包围 setCaption 打点，同样点击比较 Duration 及 new/build/update/dispose 次数；预期后续只更新节点。

---


### 测试用例：FUNC-GLOBAL-REUSE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component、transition

#### 输入

API12、V1、同一UIContext，SDK不支持API26全局复用池。左右父组件切换后旧父销毁，已有 @Reusable 的200行 SharedCard 仍重复创建。请减少跨父切换的创建开销，保留两个父组件的状态、生命周期和内容更新。

```ts
@Component
struct ParentLeft {
  @State clicks: number = 0;
  build() {
    Column() {
      Button(this.clicks.toString()).onClick(() => { this.clicks++; })
      SharedCard({ title: '左侧' })
    }
  }
}
@Component
struct ParentRight {
  @State clicks: number = 0;
  build() {
    Column() {
      Button(this.clicks.toString()).onClick(() => { this.clicks++; })
      SharedCard({ title: '右侧' })
    }
  }
}
@Reusable
@Component
struct SharedCard {
  @Prop title: string = '';
  private rows: number[] = [];
  aboutToAppear(): void {
    for (let i = 0; i < 200; i++) { this.rows.push(i); }
  }
  build() {
    Column() {
      ForEach(this.rows, (row: number) => {
        Row() { Text(this.title); Text(row.toString()) }
      }, (row: number) => row.toString())
    }
  }
}
@Entry
@Component
struct SwitchParentPage {
  @State left: boolean = true;
  build() {
    Column() {
      Button('切换父组件').onClick(() => { this.left = !this.left; })
      if (this.left) { ParentLeft() } else { ParentRight() }
    }
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** ParentLeft/ParentRight 切换后旧父销毁，其局部缓存不能交给另一个父组件，已有 @Reusable 仍会重复创建 SharedCard。
- **修改建议：** API12使用 BuilderNode/NodeController 保存并转交节点：按类型、结构和 UIContext 查找，解除旧挂载、更新参数和事件后挂到新容器，限制数量并最终释放；根组件采用受支持结构；保留两个父组件职责、当前数据和旧任务失效。
- **收益与验证：** 记录 new/build/update/dispose 次数，按同样顺序左右切换并等待更新；预期后续新建减少、缓存数量受限。

---


### 测试用例：FUNC-STARTUP-IMAGE-LAYOUT-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：startup

#### 输入

API12、状态管理V1。首页显示3张1024×512本地PNG，已知比例2:1、显示宽200vp，加载完成后条目尺寸变化。请减少加载和布局开销；图片允许异步出现，但显示位置需稳定。

```ts
@Component
struct StartupPhoto {
  @Prop source: Resource = $r('app.media.startupPhoto0');
  @State imageHeight: number = 40;
  build() {
    Column() {
      Image(this.source).syncLoad(true).width(200).height(this.imageHeight)
        .onComplete(() => { this.imageHeight = 100; })
      Text('图片说明').height(24)
    }.width(200).height(this.imageHeight + 24)
  }
}
@Entry
@Component
struct StartupPhotoPage {
  private photos: Resource[] = [
    $r('app.media.startupPhoto0'), $r('app.media.startupPhoto1'), $r('app.media.startupPhoto2')
  ];
  build() {
    Column() {
      ForEach(this.photos, (source: Resource) => { StartupPhoto({ source: source }) })
    }
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** StartupPhoto 的三张图片使用 syncLoad(true)，且 onComplete 将高度从40改为100，分别增加同步加载工作和完成后的尺寸变化。
- **修改建议：** 使用默认异步加载，初始图片尺寸设200×100vp，含24vp说明的 Column 高124vp；移除完成回调中的高度修改；图片和说明完整显示、加载前后位置稳定。
- **收益与验证：** 同图片和缓存条件启动，检查尺寸及加载完成后的 Measure/Layout；预期同步加载工作减少，图片和条目尺寸不再变化。

---


### 测试用例：FUNC-STARTUP-PREBUILD-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：startup、transition

#### 输入

API12、V1、同一UIContext。引导内容稳定显示期间有准备时间，但点击进入首页后才构建固定栏目，进入等待较长。首页已确定且构建无业务副作用，请利用准备时间，保留快速进入回退和离页释放。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class StartupHomeParams {
  labels: string[] = [];
  constructor(labels: string[]) {
    this.labels = labels;
  }
}
@Builder
function startupHomeContent(data: StartupHomeParams) {
  Column({ space: 8 }) {
    Text('首页').fontSize(24)
    ForEach(data.labels, (label: string) => {
      Row({ space: 8 }) { Text(label); Text('状态'); Text('说明') }
    }, (label: string) => label)
  }.width('100%')
}
class StartupHomeController extends NodeController {
  private node: BuilderNode<[StartupHomeParams]> | null = null;
  prepare(context: UIContext, labels: string[]): void {
    if (this.node === null) {
      this.node = new BuilderNode<[StartupHomeParams]>(context);
      this.node.build(wrapBuilder<[StartupHomeParams]>(startupHomeContent),
        new StartupHomeParams(labels));
    }
  }
  makeNode(context: UIContext): FrameNode | null {
    return this.node?.getFrameNode() ?? null;
  }
  release(): void {
    this.node?.dispose();
    this.node = null;
  }
}
@Entry
@Component
struct StartupPrebuildPage {
  private controller: StartupHomeController = new StartupHomeController();
  private labels: string[] = ['栏目1', '栏目2', '栏目3', '栏目4', '栏目5', '栏目6', '栏目7', '栏目8'];
  @State showHome: boolean = false;
  enterHome(): void {
    this.controller.prepare(this.getUIContext(), this.labels);
    this.showHome = true;
  }
  aboutToDisappear(): void { this.controller.release(); }
  build() {
    Column({ space: 12 }) {
      if (this.showHome) {
        NodeContainer(this.controller).width('100%').height(420)
      } else {
        Text('启动引导内容')
        Button('进入首页').onClick(() => { this.enterHome(); })
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** enterHome 才调用 prepare/new/build，首页子树的创建落在进入动作之后；已存在前置内容稳定显示后的准备时间。
- **修改建议：** 在前置内容稳定显示后，通过有效 UIContext 提前 prepare，进入时挂载已有节点；准备未完成时正常回退；保留单节点缓存、参数更新、快速进入/放弃和最终释放，额外占用缓存内存。
- **收益与验证：** 包围 node.build 打点并标记 enterHome；同操作比较构建时刻、进入等待及内存，预期构建前移、进入等待减少。

---


### 测试用例：FUNC-PROP-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component

#### 输入

API12、状态管理V1。点击“刷新数据”整体替换 packet，子组件只显示 caption，却接收完整大对象。请减少传参复制开销，保留父侧数据准备和父到子同步。

```ts
class PacketData {
  caption: string;
  samples: number[] = [];
  constructor(caption: string) {
    this.caption = caption;
    for (let i: number = 0; i < 20000; i++) { this.samples.push(i); }
  }
}
@Component
struct PacketView {
  @Prop packet: PacketData = new PacketData('');
  build() { Text(this.packet.caption) }
}
@Entry
@Component
struct PacketPage {
  @State packet: PacketData = new PacketData('第一条');
  private version: number = 0;
  build() {
    Column({ space: 10 }) {
      Text('数据流页面')
      PacketView({ packet: this.packet })
      Button('刷新数据').onClick(() => {
        this.version++;
        this.packet = new PacketData('第' + this.version.toString() + '条');
      })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** PacketView 只读 caption，却通过 @Prop 接收含20000项 samples 的对象，向子组件传递了无关数据并产生相应复制工作；父侧构造 samples 是正常准备。
- **修改建议：** 子组件改为只接收 @Prop caption，父侧传 packet.caption；保留父到子更新，父组件继续保存完整 packet/samples。
- **收益与验证：** 数据构造与 packet 赋值分别打点；同数据和点击次数比较更新帧及 @Prop 复制路径CPU工作，预期子组件复制减少。

---


### 测试用例：FUNC-AREA-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component

#### 输入

API12、状态管理V1。组件在 onAreaChange 中回写自身宽度，请检查由此产生的重复布局，保留内容和当前宽度显示。

```ts
@Entry
@Component
struct AreaFeedbackPage {
  @State boxWidth: number = 200;
  build() {
    Column({ space: 10 }) {
      Text('区域反馈示例').fontSize(16)
      Column() {
        Text('内容')
      }
      .width(this.boxWidth)
      .height(80)
      .onAreaChange((oldArea: Area, newArea: Area) => {
        this.boxWidth = Number(newArea.width) + 1;
      })
      Text(this.boxWidth.toString())
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** onAreaChange 把测得宽度加1回写到自身 .width，形成尺寸反馈并反复触发布局。
- **修改建议：** 将显示用测量值与布局输入分开，或采用声明式宽度约束；保留当前宽度展示和原内容，使用API12支持的接口。
- **收益与验证：** 在 onAreaChange 打点计数，同尺寸操作比较目标 Measure/Layout；预期持续反馈消失，正常尺寸变化仍更新显示。

---


### 测试用例：FUNC-REUSE-005

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component、transition

#### 输入

API12、状态管理V1。同一父组件反复切换图表和摘要，每次先隐藏、等待更新后再显示另一结构。父组件和缓存持续保留、容量足够且无需保存编辑状态，请减少不同子树之间的拆建开销。

```ts
@Component
struct ChartChild {
  build() {
    Row({ space: 8 }) {
      Text('图表1').padding(8)
      Text('图表2').padding(8)
    }
  }
}
@Component
struct TextChild {
  build() { Text('摘要内容').padding(8) }
}
@Reusable
@Component
struct InfoCard {
  @State title: string = '';
  @State withChart: boolean = false;
  aboutToReuse(params: Record<string, Object>): void {
    this.title = params.title as string;
    this.withChart = params.withChart as boolean;
  }
  build() {
    Column({ space: 4 }) {
      Text(this.title)
      if (this.withChart) {
        ChartChild()
      } else {
        TextChild()
      }
    }
  }
}
@Entry
@Component
struct StructureSwitchPage {
  @State show: boolean = true;
  @State withChart: boolean = true;
  showNext(): void {
    if (!this.show) {
      this.withChart = !this.withChart;
      this.show = true;
    }
  }
  build() {
    Column({ space: 10 }) {
      Button('隐藏当前组件').onClick(() => { this.show = false; })
      Button('显示另一种结构').onClick(() => { this.showNext(); })
      if (this.show) {
        if (this.withChart) {
          InfoCard({ title: '图表视图', withChart: true })
        } else {
          InfoCard({ title: '摘要视图', withChart: false })
        }
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** InfoCard 在 ChartChild/TextChild 两种不同子树之间使用同一默认分组，跨结构复用产生子组件拆建。
- **修改建议：** 按图表/摘要两种固定结构设置不同 reuseId，保留 @Reusable 和 title/withChart 同步；保持先隐藏再显示的操作及当前内容。
- **收益与验证：** 记录两种子组件的创建/销毁次数，同顺序隐藏、等待、切换结构；预期后续同结构复用时拆建减少。

---


### 测试用例：FUNC-STARTUP-HIDDEN-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：startup

#### 输入

API12、状态管理V1。首页初始隐藏帮助面板，但面板仍有创建开销；用户极少打开，无需保留实例、状态或位置。请减少启动时的不必要创建。

```ts
@Component
struct HelpPanel {
  private items: string[] = [];
  aboutToAppear(): void {
    for (let i: number = 0; i < 1000; i++) { this.items.push('帮助条目' + i.toString()); }
  }
  build() {
    Column() {
      ForEach(this.items, (item: string) => { Text(item).fontSize(12) }, (item: string) => item)
    }
  }
}
@Entry
@Component
struct HelpPage {
  @State show: boolean = false;
  build() {
    Column({ space: 10 }) {
      Text('首页')
      Button('帮助').onClick(() => { this.show = !this.show; })
      HelpPanel().visibility(this.show ? Visibility.Visible : Visibility.None)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** HelpPage 初始 show=false，但 visibility 隐藏的 HelpPanel 仍有初始化和创建工作；业务极少打开且无需保留实例。
- **修改建议：** 改为 if(this.show) 按需创建 HelpPanel；首次打开时才承担创建成本，关闭后局部状态销毁，原内容和打开操作保持。
- **收益与验证：** 记录 HelpPanel 初始化次数；同样以 show=false 启动，比较页面加载和首帧工作，预期打开帮助前不初始化。

---


### 测试用例：FUNC-STARTUP-LAYOUT-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：startup、scroll

#### 输入

API12、状态管理V1。首页标题和按钮被多层容器包裹，请减少无独立职责的布局层级，保留现有显示和点击行为。

```ts
@Entry
@Component
struct NestedTitlePage {
  build() {
    Column() {
      Column() {
        Column() {
          Text('标题').fontSize(24)
          Button('刷新')
        }
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** NestedTitlePage 多层 Column 包装同一标题和按钮，其中没有独立尺寸、对齐、视觉或事件职责的容器增加创建和布局工作。
- **修改建议：** 逐层确认职责后删除多余容器，将必要属性放到保留节点；保持尺寸适配、文字、对齐和按钮点击范围。
- **收益与验证：** 同页面启动，按目标节点ID比较 Create/Measure/Layout 次数及耗时；预期多余容器工作减少，布局和点击保持。

---


### 测试用例：FUNC-SCROLL-REUSE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

API12、状态管理V1。1000条固定且唯一的数据，往返滚动时复杂条目反复创建。请减少创建开销，保留展开交互、新条目初始展开和标题更新，并给出含数据源、列表调用及条目更新的最小代码。

```ts
@Component
struct Item {
  @State title: string = '';
  @State expanded: boolean = true;
  private labels: string[] = ['编号', '主题', '内容', '状态', '来源', '分类', '备注', '关联'];
  build() {
    Column() {
      Text(this.title)
      Button(this.expanded ? '折叠' : '展开')
        .onClick(() => { this.expanded = !this.expanded; })
      if (this.expanded) {
        ForEach(this.labels, (label: string) => {
          Row() { Text(label); Text(this.title) }
        }, (label: string) => label)
      }
    }
  }
}

@Entry
@Component
struct Page {
  private data: string[] = []
  aboutToAppear(): void {
    for (let i = 0; i < 1000; i++) { this.data.push(`Item ${i}`) }
  }
  build() {
    Column() {
      List() {
        ForEach(this.data, (item: string) => {
          ListItem() { Item({ title: item }) }
        }, (item: string, index: number) => JSON.stringify({ name: item, idx: index }))
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** Page 对1000项使用 ForEach，Item 有自己的展开交互且会反复离开、进入显示范围，全量创建和重复实例创建增加滑动工作。
- **修改建议：** 给出 V1 LazyForEach 最小正例，包含 IDataSource 四方法、稳定字符串 key、@Reusable 及 aboutToReuse 更新 title/expanded=true；保留嵌套内容与展开交互。
- **收益与验证：** 在 Item 创建和 aboutToReuse 中计数，同路径往返滚动；预期创建减少、复用增加，标题及初始展开状态正确。

---


### 测试用例：FUNC-SCROLL-LAZY-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

Grid有500个图片条目，滑动时图片来不及显示，出现白块。请优化资源准备和缓存，减少图片等待。

```ts
class MyData { name: string = ''; imageUrl: string = '' }

class NoPrefetchDS implements IDataSource {
  private arr: MyData[] = []
  constructor() {
    for (let i = 0; i < 500; i++) {
      const d = new MyData()
      d.name = `Item ${i}`
      d.imageUrl = `https://example.com/img${i}.png`
      this.arr.push(d)
    }
  }
  totalCount(): number { return this.arr.length }
  getData(index: number): MyData { return this.arr[index] }
  registerDataChangeListener(l: DataChangeListener): void {}
  unregisterDataChangeListener(l: DataChangeListener): void {}
}

@Entry
@Component
struct Page {
  private ds: NoPrefetchDS = new NoPrefetchDS()
  build() {
    Column() {
      Grid() {
        LazyForEach(this.ds, (item: MyData) => {
          GridItem() {
            Column() {
              Image(item.imageUrl).width(80).height(80)
              Text(item.name).fontSize(12)
            }
          }
        }, (item: MyData, index: number) => index.toString())
      }.columnsTemplate('1fr 1fr 1fr').cachedCount(1)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** Grid 已使用 LazyForEach，但图片资源未提前准备，快速滑动时资源不能及时显示而出现白块。
- **修改建议：** 按目标版本采用 IDataSourcePrefetching.prefetch 或可见范围驱动的等价预取，并让条目实际使用准备好的资源；限制缓存范围，处理重复请求、失败及过期结果。
- **收益与验证：** 记录图片请求/就绪时刻，同缓存状态和滚动路径比较白块次数、持续时间及内存，预期图片等待减少。

---


### 测试用例：FUNC-SCROLL-CALLBACK-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

API版本未提供，状态管理V1。列表滑动卡顿，onDidScroll 中有日志和计算。请减少高频回调开销，保留必要显示和交互。

```ts
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Page {
  @State scrollOffset: number = 0
  @State displayText: string = ''
  private items: string[] = []
  aboutToAppear(): void {
    for (let i = 0; i < 200; i++) { this.items.push(`Item ${i}`) }
  }
  build() {
    Column() {
      Text(this.displayText).fontSize(this.calcFontSize())
      List() {
        ForEach(this.items, (item: string) => {
          ListItem() { Text(item).height(40) }
        }, (item: string) => item)
      }
      .width('100%').height(400)
      .onDidScroll(() => {
        this.scrollOffset++
        hilog.info(0x0000, 'ScrollTag', 'scroll offset %{public}d', this.scrollOffset)
        let result = 0
        for (let i = 0; i < 1000; i++) { result += i }
        this.displayText = `scrolled ${this.scrollOffset} times, result ${result}`
      })
      .onAreaChange(() => {})
    }.width('100%').padding(16)
  }
  calcFontSize(): number {
    return this.scrollOffset > 50 ? 20 : 14
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** onDidScroll 中的调试日志和对不变数据的重复循环可精简，空 onAreaChange 监听可删除；calcFontSize 只是 O(1) 阈值判断，不能仅因每次刷新调用就认定耗时。scrollOffset 参与字号计算，不是与 UI 无关的统计。
- **修改建议：** 删除调试日志和空监听，将不变的循环结果提前计算；保留 displayText 与第 51 次回调起字号为 20 的行为。scrollOffset 可保留 @State；改普通字段时须把字号等派生值同步到可观测状态，或明确证明原有响应链仍完整，不能直接删除其 UI 更新职责。
- **收益与验证：** 在 onDidScroll 的实际处理区间打点，同数据和滚动路径比较单次及累计 Duration；预期日志及重复循环工作减少，不要求廉价字号判断的调用次数下降，核对第 50/51 次回调前后的字号与显示文本。

---


### 测试用例：FUNC-SCROLL-FLEX-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

状态管理V1。列表项使用 Flex 分配空间，滑动时帧率低。请检查测量和布局开销，保持原有空间分配及对齐。

```ts
@Entry
@Component
struct Page {
  private items: string[] = []
  aboutToAppear(): void {
    for (let i = 0; i < 100; i++) { this.items.push(`Item ${i}`) }
  }
  build() {
    Column() {
      List() {
        ForEach(this.items, (item: string) => {
          ListItem() {
            Flex({ direction: FlexDirection.Row }) {
              Text(item).fontSize(14)
              Text('label').fontSize(12).flexGrow(1)
            }
          }
        }, (item: string) => item)
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** 列表项通过 Flex 和 flexGrow/flexShrink 分配空间，需结合其直接子项判断测量成本；当前无复杂换行或对齐需求。
- **修改建议：** 评估等价的 Row/Column+layoutWeight，或按实际约束调整伸缩配置；保持空间分配、对齐和必要布局能力。
- **收益与验证：** 同数据和滚动路径，按目标行及直接子项ID比较 Measure/Layout 次数和耗时；预期测量工作减少，空间分配保持。

---


### 测试用例：FUNC-SCROLL-V2-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

API12+、状态管理V2。1000项列表在进入和滚动时创建开销较大，请按需创建并复用条目，保留内容、数据身份和交互。

```ts
@ComponentV2
struct Item { title: string = ''; build() { Text(this.title) } }

@Entry
@ComponentV2
struct Page {
  @Local data: Array<string> = []
  aboutToAppear(): void {
    for (let i = 0; i < 1000; i++) { this.data.push(`Item ${i}`) }
  }
  build() {
    Column() {
      List() {
        ForEach(this.data, (item: string) => {
          ListItem() { Item({ title: item }) }
        }, (item: string) => item)
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** V2 页面用 ForEach 展示1000项，未按显示范围限制初始创建；目标API12支持 Repeat 虚拟滚动。
- **修改建议：** 优先使用 Repeat.each(...).virtualScroll()，保持 RepeatItem 响应绑定和条目参数同步；也接受通知及参数同步完整的 LazyForEach；保留数据、稳定身份和当前项事件。
- **收益与验证：** 记录条目创建次数，同窗口、缓存和滚动路径比较首次及后续新增创建；预期按需创建，条目内容和点击身份正确。

---


### 测试用例：FUNC-TRANS-01

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition

#### 输入


````text
API12、状态管理V1。Swiper有10个复杂页，固定数据已就绪，页面没有网络或额外重计算。连续向后翻页时，相邻页首次进入不流畅，请优化页面准备时机，保留全部页面。

class PageSource implements IDataSource {
  private ids: number[] = [];
  private listeners: DataChangeListener[] = [];
  constructor(count: number) {
    for (let i = 0; i < count; i++) { this.ids.push(i); }
  }
  totalCount(): number { return this.ids.length; }
  getData(index: number): number { return this.ids[index]; }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) { this.listeners.push(listener); }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) { this.listeners.splice(index, 1); }
  }
}

// 复杂展示页：Column + Grid + 48 个 GridItem/Text，单页约 100 个基础布局节点。
@Component
struct HeavyPage {
  @State pageId: number = 0;
  private cells: number[] = [];
  aboutToAppear(): void {
    for (let i = 0; i < 48; i++) { this.cells.push(i); }
  }
  build() {
    Column({ space: 8 }) {
      Text('第 ' + this.pageId + ' 页').fontSize(20)
      Grid() {
        ForEach(this.cells, (cell: number) => {
          GridItem() { Text('块 ' + cell).fontSize(12) }
        }, (cell: number) => cell.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}

@Entry
@Component
struct Gallery {
  private pages: PageSource = new PageSource(10);
  build() {
    Swiper() {
      LazyForEach(this.pages, (id: number) => {
        HeavyPage({ pageId: id })
      }, (id: number) => id.toString())
    }
    .loop(false)
    .cachedCount(0)
    .width('100%')
    .height('100%')
  }
}
````

#### 预期输出

**验证标准**：

- **问题分析：** Gallery 使用 LazyForEach，但 Swiper 显式 cachedCount(0)，复杂相邻页直到翻入时才准备，创建工作集中于翻页过程。
- **修改建议：** 给出增加有限邻页准备的最小diff或可替换代码，按单页成本和翻页范围选择；保留页面生成方式并说明缓存内存代价。
- **收益与验证：** 记录 HeavyPage 创建时刻，同翻页顺序比较准备/翻页窗口的 ReceiveVsync 和内存；预期翻入时集中创建减少。

---


### 测试用例：FUNC-TRANS-03

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition

#### 输入


````text
API12、状态管理V1。图库往返翻页会重复读取、解码相同图片，父级未提前准备，子页销毁时释放PixelMap。图片不变且允许缓存少量近期资源，请减少入场等待，明确共享后的释放责任。

import { image } from '@kit.ImageKit';

// 应用提供的异步读取与解码：每次调用都重新生成 PixelMap，无共享缓存。
async function decodePhoto(id: number): Promise<image.PixelMap> {
  const size: number = 64;
  const colors: Uint8Array = new Uint8Array(size * size * 4);
  for (let i = 0; i < colors.length; i += 4) {
    colors[i] = 120;
    colors[i + 1] = (64 + id * 24) % 256;
    colors[i + 2] = 96;
    colors[i + 3] = 255;
  }
  return image.createPixelMap(colors.buffer as ArrayBuffer, { size: { width: size, height: size } });
}

class PhotoSource implements IDataSource {
  private ids: number[] = [];
  private listeners: DataChangeListener[] = [];
  constructor(count: number) {
    for (let i = 0; i < count; i++) { this.ids.push(i); }
  }
  totalCount(): number { return this.ids.length; }
  getData(index: number): number { return this.ids[index]; }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) { this.listeners.push(listener); }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) { this.listeners.splice(index, 1); }
  }
}

@Component
struct PhotoPage {
  photoId: number = 0;
  @State bitmap: image.PixelMap | undefined = undefined;
  private requestId: number = 0;

  aboutToAppear(): void {
    const request = ++this.requestId;
    decodePhoto(this.photoId).then((value: image.PixelMap) => {
      if (request !== this.requestId) {
        value.release();
        return;
      }
      this.bitmap = value;
    }).catch(() => {});
  }
  aboutToDisappear(): void {
    this.requestId++;
    this.bitmap?.release();
  }
  build() {
    Image(this.bitmap).width('100%').height('100%')
  }
}

// 父级：仅承载翻页，未为后续图片做任何准备。
@Entry
@Component
struct PhotoGalleryPage {
  private photos: PhotoSource = new PhotoSource(6);
  build() {
    Swiper() {
      LazyForEach(this.photos, (id: number) => {
        PhotoPage({ photoId: id })
      }, (id: number) => id.toString())
    }
    .loop(false)
    .cachedCount(1)
    .width('100%')
    .height('100%')
  }
}
````

#### 预期输出

**验证标准**：

- **问题分析：** PhotoPage 到 aboutToAppear 才调用 decodePhoto，相邻页没有提前可用资源，翻入时仍需等待图片准备。
- **修改建议：** 在 Swiper.onAnimationStart 按将进入的页面提前发起资源准备，PhotoPage 优先读取对应缓存；限制缓存，保留失败、过期及未准备完成时的正常加载路径。
- **收益与验证：** 记录 decodePhoto 请求/完成时刻，同图片及缓存条件往返翻页；比较入场等待和内存，预期资源提前就绪。

---


### 测试用例：FUNC-TRANS-04

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition、component

#### 输入


````text
API12、状态管理V1。进入新 NavDestination 时一次提交6个复杂首屏条目，入场工作集中。数据已就绪且 append 通知正确，业务允许先显示2条和稳定占位，请分散创建开销，保留顺序、最终数量和点击行为。

class Product {
  id: string = '';
  title: string = '';
  tag: string = '';
  constructor(id: string, title: string, tag: string) {
    this.id = id;
    this.title = title;
    this.tag = tag;
  }
}

const PRODUCT_DATA: Product[] = [
  new Product('p-1', '商品一', '新品'),
  new Product('p-2', '商品二', '热卖'),
  new Product('p-3', '商品三', '新品'),
  new Product('p-4', '商品四', '特惠'),
  new Product('p-5', '商品五', '热卖'),
  new Product('p-6', '商品六', '新品')
];

// 复杂商品卡片。
@Component
struct ItemView {
  item: Product = new Product('', '', '');
  build() {
    Column({ space: 8 }) {
      Stack() { Text('商品图').fontSize(24) }
        .width('100%').height(96).backgroundColor('#EDF2F7').borderRadius(8)
      Row({ space: 8 }) {
        Text(this.item.title).fontSize(16)
        Blank()
        Text(this.item.tag).fontSize(12)
      }.width('100%')
      Row({ space: 8 }) {
        Text('编号 ' + this.item.id).fontSize(12)
        Blank()
        Text('加入购物车').fontSize(12)
      }.width('100%')
    }
    .padding(8)
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
  }
}

// 完整 IDataSource：append 追加数据并对每个新增下标发出增量通知。
class ProductSource implements IDataSource {
  private items: Product[] = [];
  private listeners: DataChangeListener[] = [];
  totalCount(): number { return this.items.length; }
  getData(index: number): Product { return this.items[index]; }
  append(items: Product[]): void {
    const start: number = this.items.length;
    this.items = this.items.concat(items);
    for (let i = 0; i < items.length; i++) {
      this.listeners.forEach((listener: DataChangeListener) => { listener.onDataAdd(start + i); });
    }
  }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) { this.listeners.push(listener); }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) { this.listeners.splice(index, 1); }
  }
}

@Component
struct ProductPage {
  private products: ProductSource = new ProductSource();
  aboutToAppear(): void {
    this.products.append(PRODUCT_DATA);
  }
  build() {
    NavDestination() {
      WaterFlow() {
        LazyForEach(this.products, (item: Product) => {
          FlowItem() { ItemView({ item: item }) }
        }, (item: Product) => item.id)
      }
      .columnsTemplate('1fr 1fr')
      .width('100%')
      .height('100%')
    }
  }
}

// 已显示的商品页宿主通过NavPathStack.pushPathByName进入此NavDestination；进入条件和数据均已就绪。
````

#### 预期输出

**验证标准**：

- **问题分析：** ProductPage 进入时整批提交6个复杂首屏条目，创建和布局集中于关键入场窗口；业务允许逐步展示。
- **修改建议：** 在稳定占位基础上分批提交，或将部分创建错开关键入场阶段；选择 DisplaySync 时正确启动、停止和解除回调；保持顺序、最终数量、点击身份及重入时旧任务失效。
- **收益与验证：** 在 append 处打点并记录批量，同数据定位各批更新帧；预期入场单帧创建更分散，同时记录完整内容就绪时间。

---


### 测试用例：FUNC-TRANS-07

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition、component

#### 输入


````text
API26、Stage/V1。TabSwitchPage持续存在，按推荐→关注→收藏→推荐切换，每次等动画结束。各页数据固定、卡片布局相同，已有 @Reusable 和相同 reuseId 仍重复创建。请优化跨页复用，保持现有缓存设置、内容更新及新记录默认不选中。

class TabInfo {
  id: number = 0;
  title: string = '';
  constructor(id: number, title: string) {
    this.id = id;
    this.title = title;
  }
}

class TabSource implements IDataSource {
  private data: TabInfo[] = [
    new TabInfo(0, '推荐'),
    new TabInfo(1, '关注'),
    new TabInfo(2, '收藏')
  ];
  totalCount(): number { return this.data.length; }
  getData(index: number): TabInfo { return this.data[index]; }
  registerDataChangeListener(_listener: DataChangeListener): void {}
  unregisterDataChangeListener(_listener: DataChangeListener): void {}
}

class ProductInfo {
  id: number = 0;
  title: string = '';
  constructor(id: number, title: string) {
    this.id = id;
    this.title = title;
  }
}

class ProductSource implements IDataSource {
  private data: ProductInfo[] = [];
  constructor() {
    for (let i = 0; i < 12; i++) {
      this.data.push(new ProductInfo(i, '商品 ' + i));
    }
  }
  totalCount(): number { return this.data.length; }
  getData(index: number): ProductInfo { return this.data[index]; }
  registerDataChangeListener(_listener: DataChangeListener): void {}
  unregisterDataChangeListener(_listener: DataChangeListener): void {}
}

class CardStats {
  static creates: number = 0;
  static reuses: number = 0;
  static recycles: number = 0;
}

@Reusable
@Component
struct ReusableProductCard {
  @State sourceTab: string = '';
  @State productId: number = 0;
  @State productTitle: string = '';
  @State selected: boolean = false;

  aboutToAppear(): void { CardStats.creates++; }
  aboutToRecycle(): void { CardStats.recycles++; }
  aboutToReuse(params: Record<string, Object>): void {
    CardStats.reuses++;
    this.sourceTab = params.sourceTab as string;
    this.productId = params.productId as number;
    this.productTitle = params.productTitle as string;
    this.selected = false;
  }
  build() {
    Column({ space: 4 }) {
      Row() {
        Text(this.sourceTab).fontSize(12)
        Blank()
        Text('编号 ' + this.productId).fontSize(12)
      }.width('100%')
      Stack() {
        Text('商品展示区').fontSize(14)
      }
      .width('100%')
      .height(64)
      .backgroundColor('#EDF2F7')
      Text(this.productTitle).fontSize(16)
      Row() {
        Text('同款布局').fontSize(12)
        Blank()
        Button(this.selected ? '已选' : '选择')
          .height(28)
          .onClick(() => { this.selected = !this.selected; })
      }.width('100%')
    }
    .padding(8)
    .width('100%')
    .height('100%')
    .border({ width: 1, color: '#D8DEE9' })
    .borderRadius(8)
  }
}

@Component
struct ProductTabPage {
  // 推荐、关注、收藏分别创建本组件的不同实例；未配置全局池时，各实例的局部池独立。
  @Prop tabTitle: string = '';
  private products: ProductSource = new ProductSource();

  build() {
    WaterFlow() {
      LazyForEach(this.products, (item: ProductInfo) => {
        FlowItem() {
          ReusableProductCard({
            sourceTab: this.tabTitle,
            productId: item.id,
            productTitle: item.title
          }).reuseId('product-card') // 相同 reuseId 不会使不同页签的局部池共享。
        }
        .width('100%')
        .height(168)
      }, (item: ProductInfo) => item.id.toString())
    }
    .columnsTemplate('1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .width('100%')
    .height('100%')
  }
}

@Entry
@Component
struct TabSwitchPage {
  @State activeIndex: number = 0;
  private tabs: TabSource = new TabSource();
  private swiper: SwiperController = new SwiperController();

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Button('推荐').onClick(() => { this.swiper.changeIndex(0, true); })
        Button('关注').onClick(() => { this.swiper.changeIndex(1, true); })
        Button('收藏').onClick(() => { this.swiper.changeIndex(2, true); })
      }.height(40)
      Text('当前页签：' + this.tabs.getData(this.activeIndex).title)
      Swiper(this.swiper) {
        LazyForEach(this.tabs, (tab: TabInfo) => {
          ProductTabPage({ tabTitle: tab.title })
        }, (tab: TabInfo) => tab.id.toString())
      }
      .loop(false)
      .cachedCount(0)
      .duration(400)
      .onChange((index: number) => { this.activeIndex = index; })
      .width('100%')
      .layoutWeight(1)
      Button('查看计数').onClick(() => {
        console.info('creates=' + CardStats.creates +
          ', reuses=' + CardStats.reuses +
          ', recycles=' + CardStats.recycles);
      })
    }
    .padding(12)
    .width('100%')
    .height('100%')
  }
}
````

#### 预期输出

**验证标准**：

- **问题分析：** 各 ProductTabPage 的局部复用缓存独立，旧父销毁后新页重复创建同类卡片；相同组件名和 reuseId 不会建立跨页共享。
- **修改建议：** API26优先在持续存在的 TabSwitchPage 配置 reusePool/poolAccepts 接纳 ReusableProductCard 并限制缓存；也接受完整 BuilderNode 保存、解挂、更新、转交和释放方案；保留页签释放规则、当前记录状态及退场动画占用。
- **收益与验证：** 固定缓存设置，按推荐→关注→收藏→推荐切换；动画结束后比较 CardStats 和缓存数量，预期后续创建减少、记录状态正确。

---


### 测试用例：FUNC-TRANS-09

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition、component

#### 输入


````text
API12、状态管理V1。同一宿主在240/360vp两种内容间切换时，Footer跟着移动。设计允许内容区域固定400vp，请限制布局影响范围，保留正文、工具栏及300ms过渡。

@Component
struct ListBody {
  private items: string[] = ['商品 A', '商品 B', '商品 C'];

  build() {
    Column({ space: 12 }) {
      Text('商品列表').fontSize(24)
      ForEach(this.items, (item: string) => {
        Text(item).width('90%').height(44).backgroundColor('#FFFFFF')
      }, (item: string) => item)
    }
    .width('100%').height(240).backgroundColor('#EAF2FF')
  }
}

@Component
struct DetailBody {
  build() {
    Column({ space: 16 }) {
      Text('商品 A 详情').fontSize(24)
      Text('这里展示商品介绍、规格和配送信息。').fontSize(18)
      Text('详情内容比列表页更高，但设计预留区域始终为 400vp。')
    }
    .width('100%').height(360).padding(16).backgroundColor('#FFF3E0')
  }
}

@Component
struct Footer {
  build() {
    Column({ space: 8 }) {
      Text('公共工具栏').fontSize(18)
      Row({ space: 12 }) {
        Button('客服')
        Button('帮助')
      }
    }
    .width('100%').padding(12).backgroundColor('#F1F3F5')
  }
}

@Entry
@Component
struct PageHost {
  @State page: number = 0;

  build() {
    Column({ space: 12 }) {
      Text('列表内容页 ↔ 详情内容页').fontSize(20)
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.page === 0) {
          ListBody().transition(TransitionEffect.OPACITY)
        } else {
          DetailBody().transition(TransitionEffect.OPACITY)
        }
      }
      .width('100%') // Bad：高度随 240/360vp 子内容变化。
      Footer()
      Button('切换页面').onClick(() => {
        this.getUIContext().animateTo({ duration: 300 }, () => {
          this.page = this.page === 0 ? 1 : 0;
        });
      })
    }
    .width('100%').height('100%')
  }
}
````

#### 预期输出

**验证标准**：

- **问题分析：** PageHost 内容在240/360vp间切换，宿主高度随之变化，推动 Footer 并把布局工作传到外部；业务允许稳定400vp区域。
- **修改建议：** 为承载内容的宿主设置稳定400vp约束，保留内部自适应；正文完整、对齐、动画和点击行为保持。
- **收益与验证：** 在 page 赋值处打点，同样切换内容，比较 Footer 位置及外部节点 Measure/Layout；预期位置稳定、额外布局减少。

---


### 测试用例：FUNC-TRANS-10

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition、startup

#### 输入


````text
API12、状态管理V1。点击商品后，要等异步正文返回才进入详情，首次反馈慢。进入条件已通过，允许先显示标题、返回操作和骨架，请提前反馈，保留返回、失败重试及过期结果保护。

class DetailData {
  id: number = 0;
  title: string = '';
  body: string = '';
  constructor(id: number, title: string, body: string) {
    this.id = id;
    this.title = title;
    this.body = body;
  }
}

function requestDetail(id: number): Promise<DetailData> {
  return new Promise<DetailData>((resolve) => {
    setTimeout(() => {
      resolve(new DetailData(id, '商品 ' + id, '商品介绍、规格和配送说明。'));
    }, 300);
  });
}

@Entry
@Component
struct DetailTransitionPage {
  @State showDetail: boolean = false;
  @State detail: DetailData = new DetailData(0, '', '');
  @State error: string = '';
  private requestId: number = 0;

  aboutToDisappear(): void {
    this.requestId++;
  }

  async enter(id: number): Promise<void> {
    const request = ++this.requestId;
    this.error = '';
    try {
      const value = await requestDetail(id);
      if (request !== this.requestId) { return; }
      this.detail = value;
      // Bad：等异步数据返回，才开始切换到详情。
      this.getUIContext().animateTo({ duration: 250 }, () => {
        this.showDetail = true;
      });
    } catch {
      if (request === this.requestId) { this.error = '加载失败，请重试'; }
    }
  }

  leave(): void {
    this.requestId++;
    this.getUIContext().animateTo({ duration: 250 }, () => {
      this.showDetail = false;
    });
  }

  onBackPress(): boolean {
    if (this.showDetail) {
      this.leave();
      return true;
    }
    return false;
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 16 }) {
        if (this.showDetail) {
          Button('返回列表').onClick(() => this.leave())
        }
        Text(this.showDetail ? '商品详情' : '商品列表').fontSize(24)
      }
      .width('100%').height(56)
      Stack({ alignContent: Alignment.TopStart }) {
        if (!this.showDetail) {
          Column({ space: 16 }) {
            Button('查看商品 A').onClick(() => { this.enter(1); })
            Button('查看商品 B').onClick(() => { this.enter(2); })
            if (this.error !== '') {
              Text(this.error).fontColor('#B00020')
            }
          }
          .width('100%').height(360).transition(TransitionEffect.OPACITY)
        } else {
          Column({ space: 16 }) {
            Text(this.detail.title).fontSize(24).height(40)
            Text(this.detail.body).fontSize(18).height(160)
          }
          .width('100%').height(360).transition(TransitionEffect.OPACITY)
        }
      }
      .width('100%').height(360)
    }
    .width('100%').height('100%').padding(16)
  }
}
````

#### 预期输出

**验证标准**：

- **问题分析：** enter 等 requestDetail 返回才设置 showDetail，使不依赖正文的标题、返回操作和详情框架也等待；请求本身是异步等待。
- **修改建议：** 先展示详情框架和骨架，请求完成后更新正文；保留返回、失败/重试、请求身份及过期结果保护；同样原则适用于首页关键与非关键内容。
- **收益与验证：** 同请求延迟记录点击、框架可见和正文可见时刻；预期首次反馈提前，并核对返回、失败和重试。

---


### 测试用例：FUNC-ANIM-CLOSURE-002

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。点击后卡片高度和透明度做300ms过渡，文本允许等动画结束后追加。请优化当前动画写法，保留点击触发、过渡效果和最终内容。

```ts
@Entry
@Component
struct ExpandableCard {
  @State cardHeight: number = 100;
  @State cardOpacity: number = 1;
  @State message: string = 'Card Content';
  build() {
    Column() {
      Button(this.message)
        .width('100%')
        .height(this.cardHeight)
        .opacity(this.cardOpacity)
    }
    .onClick(() => {
      this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.cardOpacity = 0.8;
        this.cardHeight = 300;
        this.message += '1';
      })
    })
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** message不参与高度和透明度插值，却在动画启动时更新文本；本例允许延后，可将这部分文本刷新移出动画阶段。
- **修改建议：** 给出最小diff或可替换回调，将message追加移到onFinish，动画闭包仅保留cardHeight/cardOpacity；保留点击、300ms过渡和最终文本，说明文本改为结束后更新。
- **收益与验证：** 同初始内容点击一次，记录触发、onFinish及文本更新时间并录屏；预期文本刷新移到动画结束后，过渡与终态正确，不宣称总耗时必然下降。

---


### 测试用例：FUNC-ANIM-CUSTOM-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。进度条用16ms定时器逐帧更新，期望约60fps平滑增长。请减少应用逐帧开销，保留开始、完成到100%及清理行为。

```ts
@Entry
@Component
struct LoadingBarPage {
  @State progress: number = 0;
  private timer: number = -1;
  build() {
    Column({ space: 16 }) {
      Text('加载中')
        .width(this.progress + '%')
        .height(20)
        .backgroundColor('#42A5F5')
      Button('开始').onClick(() => {
        if (this.timer !== -1) { clearInterval(this.timer); }
        this.progress = 0;
        this.timer = setInterval(() => {
          if (this.progress < 100) {
            this.progress += 2;
          } else {
            clearInterval(this.timer);
            this.timer = -1;
          }
        }, 16);
      })
    }.width('100%').padding(16)
  }
  aboutToDisappear(): void {
    if (this.timer !== -1) { clearInterval(this.timer); this.timer = -1; }
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** LoadingBarPage 用16ms定时器反复增加 progress，应用承担逐帧计算和状态提交；已有完成条件及销毁清理。
- **修改建议：** 改用 animation/animateTo 或适用 animator 驱动系统过渡；保留点击开始、到100%完成、再次触发和销毁清理。
- **收益与验证：** 在定时回调打点，同参数比较启动至完成窗口的回调次数和UI工作；预期手动逐帧工作减少，进度平滑到100%。

---


### 测试用例：FUNC-ANIM-TAB-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation、transition

#### 输入

API12、状态管理V1。从Tab1切到Tab2后，Tab1已不可见。请检查旋转动画是否仍产生刷新，给出最小修改代码，保留原转速、切回后的播放和清理。

```ts
@Component
struct SpinningIcon {
  @State angle: number = 0;
  private timer: number = -1;
  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.angle = (this.angle + 6) % 360;
    }, 50);
  }
  build() {
    Column() {
      Text('旋转')
        .fontSize(20)
        .rotate({ angle: this.angle })
    }
  }
}

@Entry
@Component
struct TabRefreshPage {
  @State currentTab: number = 0;
  build() {
    Column({ space: 10 }) {
      Tabs() {
        TabContent() {
          SpinningIcon()
        }.tabBar('Tab1')
        TabContent() {
          Text('Tab2 内容')
        }.tabBar('Tab2')
      }
      .onChange((index: number) => {
        this.currentTab = index;
      })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** Tab1 不可见后定时器仍修改 angle，且没有销毁清理；currentTab 未连接动画控停。
- **修改建议：** 给出实际Tab停启和销毁清理代码，保留120°/s旋转及返回恢复；替换驱动时保证有效启动，不能仅删定时器就认定动画已暂停。
- **收益与验证：** 同顺序进入、切Tab、返回和退出，观察最终驱动的回调或实际动画；预期不可见时停止、返回恢复、销毁后无残留，已删除的定时器始终零回调。

---


### 测试用例：FUNC-ANIM-DURATION-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。横幅按设计使用5000ms慢速渐变和持续循环，请核对当前配置是否需要调整，保留既定展示效果。

```ts
@Entry
@Component
struct BannerPage {
  @State opacity: number = 1.0;
  build() {
    Column({ space: 16 }) {
      Text('横幅')
        .fontSize(24)
        .opacity(this.opacity)
        .animation({ duration: 5000, curve: Curve.Linear, iterations: -1 })
      Button('切换').onClick(() => {
        this.opacity = this.opacity === 1.0 ? 0.3 : 1.0;
      })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** Banner 的5000ms、iterations:-1用于明确要求的慢速循环渐变，已有合法 .animation，当前参数不构成缺陷。
- **修改建议：** 保留配置，建议开发者结合当前展示意图核实体验；当前代码无需增加实现替换或假设的后台处理。
- **收益与验证：** 点击并观察5秒渐变和循环效果，符合既定展示意图即可保留。

---


### 测试用例：FUNC-ANIM-RENDERGROUP-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation、component

#### 输入

API12、状态管理V1。网格有60个图标，每个带整体scale点击动画，内部label固定不变。请检查是否可减少重复绘制，保留视觉和点击效果。

```ts
@Component
struct IconItem {
  private label: string = '';
  @State scale: number = 1.0;
  build() {
    Column() {
      Text(this.label)
        .fontSize(14)
    }
    .width(72)
    .height(72)
    .backgroundColor('#F5F5F5')
    .scale({ x: this.scale, y: this.scale })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .onClick(() => {
      this.scale = this.scale === 1.0 ? 1.1 : 1.0;
    })
  }
}

@Entry
@Component
struct IconGridPage {
  private items: string[] = [];
  aboutToAppear(): void {
    for (let i = 0; i < 60; i++) {
      this.items.push('项 ' + i.toString());
    }
  }
  build() {
    Column() {
      Grid() {
        ForEach(this.items, (item: string) => {
          GridItem() {
            IconItem({ label: item })
          }
        }, (item: string) => item)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .height('100%')
    }.width('100%').padding(8)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** IconItem 的固定内容随容器整体 scale，子内容稳定且无独立动画，可评估 renderGroup 减少重复绘制；60项不是强制启用阈值。
- **修改建议：** 在承受整体变换的固定内容容器评估 renderGroup，目标API12可用；保留原 .animation、文字、布局与点击，增加绘制缓存的内存代价。
- **收益与验证：** 同设备和点击顺序比较动画窗口的绘制工作及缓存内存；预期重复绘制减少，据实测决定是否采用。

---


### 测试用例：FUNC-ANIM-LAYOUT-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。点击后按钮放大，但文字字号必须保持。请评估动画的布局开销，给出效果等价的方案。

```ts
@Entry
@Component
struct ExpandButtonPage {
  @State btnWidth: number = 100;
  @State btnHeight: number = 40;
  build() {
    Column({ space: 16 }) {
      Button('展开')
        .width(this.btnWidth)
        .height(this.btnHeight)
        .onClick(() => {
          this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
            this.btnWidth = 200;
            this.btnHeight = 80;
          });
        })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** 按钮 width/height 动画有布局成本，但按钮含文字且业务要求字号保持，整体 scale 会改变文字效果。
- **修改建议：** 保留布局动画，或将可缩放背景与独立文字层分开；保持字号、点击区域、触发和最终尺寸。
- **收益与验证：** 点击录屏检查字号和过渡；采用分层方案时，同窗口比较目标 Measure/Layout，预期减少布局工作且效果等价。

---


### 测试用例：FUNC-ANIM-TRANSITION-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation、transition

#### 输入

API12、状态管理V1，TransitionEffect可用。按钮控制Toast淡入淡出，请减少显隐触发时的状态更新和回调开销，保持原时序及布局。

```ts
@Entry
@Component
struct ToastOverlayPage {
  @State toastOpacity: number = 0;
  @State toastVisibility: Visibility = Visibility.None;
  build() {
    Column({ space: 16 }) {
      Text('Toast Message')
        .opacity(this.toastOpacity)
        .visibility(this.toastVisibility)
      Button('显示').onClick(() => { this.showToast(); })
      Button('隐藏').onClick(() => { this.hideToast(); })
    }.width('100%').padding(16)
  }
  showToast(): void {
    this.toastVisibility = Visibility.Visible;
    this.getUIContext()?.animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
      this.toastOpacity = 1;
    });
  }
  hideToast(): void {
    this.getUIContext()?.animateTo({
      duration: 200,
      curve: Curve.EaseIn,
      onFinish: () => {
        this.toastVisibility = Visibility.None;
      }
    }, () => {
      this.toastOpacity = 0;
    });
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** showToast/hideToast 使用 opacity、visibility 状态和 onFinish 控制显隐，触发时包含额外状态提交及回调注册。
- **修改建议：** 在条件展示语义适用时改用 transition+TransitionEffect，API12支持；保持淡入淡出时机、隐藏后占位与销毁行为。
- **收益与验证：** 包围整个显隐事件打点，同样操作比较同步 Duration，并录屏核对200ms效果；预期触发工作减少。

---


### 测试用例：FUNC-ANIM-MERGE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。点击后卡片同时旋转、淡出，两个animateTo参数相同。请减少重复调用，保持原动画效果。

```ts
@Entry
@Component
struct CardFlipPage {
  @State rotateY: number = 0;
  @State opacity: number = 1;
  build() {
    Column({ space: 16 }) {
      Text('Card')
        .fontSize(24)
        .rotate({ y: 1, angle: this.rotateY })
        .opacity(this.opacity)
    }
    .width(200)
    .height(200)
    .padding(16)
    .onClick(() => {
      this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
        this.rotateY = 180;
      });
      this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
        this.opacity = 0.5;
      });
    })
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** CardFlipPage 在同一点击内用相同400ms参数调用两次 animateTo，产生重复的同步调用和状态捕获。
- **修改建议：** 合并为一次 animateTo，同时提交 rotateY/opacity；保留旋转、淡出、曲线、时长及触发顺序。
- **收益与验证：** 包围整个点击事件打点，同状态比较 Duration；预期同步提交工作减少，旋转和淡出效果保持。

---


### 测试用例：FUNC-ANIM-REDUNDANT-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation、scroll

#### 输入

API24、状态管理V1。APNG条目离屏后仍在 cachedCount(1) 范围存活。库提供 controller.pause/play，tick 在暂停时提前返回，请减少不可见期间的解码绘制，保留回屏恢复和释放。

```ts
import { apng, ApngController } from '@ohos/apng';

class ApngDataSource implements IDataSource {
  private controllers: ApngController[] = [];
  totalCount(): number { return this.controllers.length; }
  getData(index: number): ApngController { return this.controllers[index]; }
  registerDataChangeListener(_: DataChangeListener): void {}
  unregisterDataChangeListener(_: DataChangeListener): void {}
}

@Entry
@Component
struct AnimationList {
  private dataSource: ApngDataSource = new ApngDataSource();
  aboutToAppear(): void {
    for (let i = 0; i < 50; i++) {
      this.dataSource.controllers.push(new ApngController());
    }
  }
  build() {
    List({ space: 10 }) {
      LazyForEach(this.dataSource, (item: ApngController) => {
        ListItem() {
          apng({ src: $r('app.media.stack'), controller: item })
            .width(340).height(240)
        }
      }, (item: ApngController) => item.uuid)
    }.width('100%').height('100%').cachedCount(1)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** APNG条目离屏后仍在 cachedCount 范围存活，tick 继续解码和绘制，产生不可见期间的工作。
- **修改建议：** 通过真实 ApngController.pause/play 按可见性暂停、恢复，保留库内部销毁释放；条目实例和布局保持，回屏恢复播放。
- **收益与验证：** 同滑动路径和缓存设置，比较不可见窗口的实际绘制次数及 ReceiveVsync 累计 Duration；预期离屏工作减少、回屏恢复。

---


### 测试用例：FUNC-ANIM-TRACE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

我的自定义动画播放时每帧都卡，请分析性能问题。

#### 预期输出

**验证标准**：

- **问题分析：** 用户只提供“自定义动画每帧卡”的症状，尚无代码、目标版本或触发条件，不能定位具体性能机制。
- **修改建议：** 索取动画相关代码或授权路径、目标版本，以及开始、持续和结束的复现动作，再按实现选择规则。
- **收益与验证：** 补齐代码和复现动作后确定观察点；本例尚未执行验证。

---


### 测试用例：FUNC-LOCAL-STATE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component

#### 输入

API18+、状态管理V2。同一父组件切换两名联系人，切回后备注输入丢失。请按联系人保存、恢复编辑内容，保持标题和部门同步，并给出功能回归步骤。

```ts
@ReusableV2
@ComponentV2
struct ContactTileV2 {
  @Param title: string = '';
  @Param subtitle: string = '';
  @Local localValue: string = '';
  build() {
    Column({ space: 4 }) {
      Text(this.title)
      Text(this.subtitle)
      TextInput({ text: this.localValue })
        .onChange((value: string) => { this.localValue = value; })
    }
  }
}
@Entry
@ComponentV2
struct ContactListPage {
  @Local show: boolean = true;
  @Local currentTitle: string = '联系人A';
  @Local currentSubtitle: string = '部门A';
  switchContact(): void {
    if (this.show) { this.show = false; } else {
      this.currentTitle = this.currentTitle === '联系人A' ? '联系人B' : '联系人A';
      this.currentSubtitle = this.currentSubtitle === '部门A' ? '部门B' : '部门A';
      this.show = true;
    }
  }
  build() {
    Column({ space: 10 }) {
      Button('切换联系人').onClick(() => { this.switchContact(); })
      if (this.show) {
        ContactTileV2({ title: this.currentTitle, subtitle: this.currentSubtitle })
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** ContactTileV2 的输入仅保存在 @Local localValue，真实复用会按初值重置，销毁重建也无法按联系人恢复；这是状态保存问题。
- **修改建议：** 按稳定 contactId 在父组件或数据模型保存编辑值，经 @Param 传入、@Event 写回；保留输入、标题/部门同步和A/B数据隔离，使用V2正确的复用规则。
- **收益与验证：** 每次先隐藏、等待UI更新，再显示另一人；按A输入a→B输入b→A→B操作，检查a/b及标题部门分别恢复。

---


### 测试用例：FUNC-SCROLL-REUSABLEV2-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

API18+、状态管理V2。同一父组件反复隐藏、显示80行面板，创建开销较大。面板需保留展开交互，每次显示新记录时初始展开，请优化外层面板复用并更新标题。

```ts
@ComponentV2
struct DetailPanel {
  @Local expanded: boolean = true;
  private rows: number[] = this.makeRows();
  private makeRows(): number[] {
    const rows: number[] = [];
    for (let i: number = 0; i < 80; i++) { rows.push(i); }
    return rows;
  }
  @Param title: string = ''
  build() {
    Column({ space: 4 }) {
      Text(this.title).fontSize(16)
      Button(this.expanded ? '折叠' : '展开').onClick(() => { this.expanded = !this.expanded; })
      if (this.expanded) {
        ForEach(this.rows, (row: number) => { Row() { Text(this.title); Text(row.toString()); Text('详情内容') } })
      }
    }
  }
}

@Entry
@ComponentV2
struct Page {
  @Local showDetail: boolean = false
  @Local currentTitle: string = '面板A'
  build() {
    Column({ space: 10 }) {
      Button('切换').onClick(() => {
        this.showDetail = !this.showDetail
        this.currentTitle = this.currentTitle === '面板A' ? '面板B' : '面板A'
      })
      Scroll() {
        Column({ space: 12 }) {
          if (this.showDetail) {
            DetailPanel({ title: this.currentTitle })
          }
        }.width('100%')
      }.width('100%').height(400).scrollBar(BarState.Off)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** 同一父组件反复移除、显示带80行内容的 DetailPanel，内部按需创建不能替代外层实例复用；面板需要自身展开交互。
- **修改建议：** API18+评估 @ReusableV2，利用 @Param 新参数初始化及 @Local 按初值重置，保留默认结构分组；每次显示新标题且初始展开，展开交互保留。
- **收益与验证：** 在面板初始化和复用回调计数，同顺序隐藏/显示；预期后续创建减少、标题和初始展开状态正确。

---


### 测试用例：FUNC-TRANS-02

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：transition

#### 输入


````text
API12、状态管理V1。Swiper有20个复杂页，数据固定且无IO，通常只翻相邻1～2页，但准备阶段集中创建、内存偏高。请优化缓存范围，保留全部内容及访问顺序。

class PageSource implements IDataSource {
  private ids: number[] = [];
  private listeners: DataChangeListener[] = [];
  constructor(count: number) {
    for (let i = 0; i < count; i++) { this.ids.push(i); }
  }
  totalCount(): number { return this.ids.length; }
  getData(index: number): number { return this.ids[index]; }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) { this.listeners.push(listener); }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) { this.listeners.splice(index, 1); }
  }
}

// 复杂展示页：Column + Grid + 48 个 GridItem/Text，单页约 100 个基础布局节点。
@Component
struct HeavyPage {
  @State pageId: number = 0;
  private cells: number[] = [];
  aboutToAppear(): void {
    for (let i = 0; i < 48; i++) { this.cells.push(i); }
  }
  build() {
    Column({ space: 8 }) {
      Text('第 ' + this.pageId + ' 页').fontSize(20)
      Grid() {
        ForEach(this.cells, (cell: number) => {
          GridItem() { Text('块 ' + cell).fontSize(12) }
        }, (cell: number) => cell.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}

@Entry
@Component
struct Gallery {
  private pages: PageSource = new PageSource(20);
  build() {
    Swiper() {
      LazyForEach(this.pages, (id: number) => {
        HeavyPage({ pageId: id })
      }, (id: number) => id.toString())
    }
    .loop(false)
    .cachedCount(10)
    .width('100%')
    .height('100%')
  }
}
````

#### 预期输出

**验证标准**：

- **问题分析：** Gallery 的较大 cachedCount 使较多复杂 HeavyPage 提前创建并保留，增加准备工作和存活内存。
- **修改建议：** 按实际翻页范围收敛缓存数量，保留 LazyForEach 生成方式和完整内容；缓存缩小后需核对快速翻页时资源是否及时就绪。
- **收益与验证：** 记录 HeavyPage 创建及存活数，同顺序翻页比较准备工作和内存；预期驻留减少，快速翻页体验保持。

---


### 测试用例：FUNC-ANIM-CLOSURE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。点击展开后卡片直接变宽，没有要求的平滑过渡。请修正动画效果，保留原触发和最终宽度。

```ts
@Entry
@Component
struct ExpandableCardPage {
  @State cardWidth: number = 200;
  build() {
    Column({ space: 16 }) {
      Text('卡片')
        .width(this.cardWidth)
        .height(100)
        .backgroundColor('#EEEEEE')
        .textAlign(TextAlign.Center)
      Button('展开').onClick(() => {
        this.cardWidth = 400;
      })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** 展开按钮直接把 cardWidth 从200改为400，且无相应动画驱动，不能满足平滑展开要求；这是效果问题。
- **修改建议：** 使用 UIContext.animateTo 或正确绑定 width 的 .animation；保留点击展开和最终宽400，API12可使用上下文明确的合法接口。
- **收益与验证：** 点击展开并录屏，检查宽度平滑过渡到400，保持原触发行为。

---


### 测试用例：FUNC-ANIM-ITERATIONS-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation

#### 输入

API12、状态管理V1。点击后圆点尺寸直接跳变，没有要求的800ms过渡。请检查动画配置，保持原触发和目标状态。

```ts
@Entry
@Component
struct LoadingDotPage {
  @State scale: number = 1.0;
  build() {
    Column({ space: 16 }) {
      Text('●')
        .fontSize(40)
        .scale({ x: this.scale, y: this.scale })
        .animation({ duration: 800, iterations: 0, curve: Curve.EaseInOut })
      Button('切换').onClick(() => {
        this.scale = this.scale === 1.0 ? 1.5 : 1.0;
      })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** .animation 配置 iterations:0，点击后 scale 直接跳变，未播放要求的800ms过渡；这是动画不执行的功能问题。
- **修改建议：** 按播放一次的需求改为 iterations:1；业务要求持续循环时才采用-1；保留按钮触发和目标 scale。
- **收益与验证：** 点击并录屏，检查800ms过渡、循环方式和终态，预期恢复设计要求的动画。

---


### 测试用例：FUNC-ANIM-FLING-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：animation、scroll

#### 输入

API12、状态管理V1。列表初始在顶部，按钮用于向下模拟低初速惯性滑动，不要求精确停靠。请核对方向和体验，保持原交互意图。

```ts
@Entry
@Component
struct ListFlingPage {
  private items: string[] = [];
  scrollerForList: Scroller = new Scroller();
  aboutToAppear(): void {
    for (let i = 0; i < 200; i++) { this.items.push('item' + i.toString()); }
  }
  build() {
    Column({ space: 16 }) {
      Button('向下惯性滑动')
        .onClick(() => {
          this.scrollerForList.fling(-100);
        })
      List({ space: 20, initialIndex: 0, scroller: this.scrollerForList }) {
        ForEach(this.items, (item: string) => {
          ListItem() { Text(item).height(40) }
        }, (item: string) => item)
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** Scroller.fling(-100) 是向底部的合法初速，符合列表初始在顶部、向下惯性滑动的意图，单位为vp/s。
- **修改建议：** 保留方向，建议开发者核实初速与实际滑动体验；业务仍是惯性滚动，不改成精确位置/索引跳转。
- **收益与验证：** 列表回到顶部后点击，记录方向、持续时间和停止位置；同设备检查向下惯性滑动体验，符合设计即可保留。

---


### 测试用例：FUNC-STATE-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component

#### 输入

API12、状态管理V1。点击 step 只更新 value，unit不变。请减少无关状态更新，保留数值和单位显示。

```ts
class MeterData { value: number = 0; unit: string = 'kg'; }
@Entry
@Component
struct MeterPage {
  @State meter: MeterData = new MeterData();
  build() {
    Column({ space: 10 }) {
      Text(this.meter.value.toString())
      Text(this.meter.unit)
      Button('step').onClick(() => { this.meter.value++; })
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** MeterPage 修改 meter.value，而普通V1对象同时关联 value/unit 读取，可能产生 unit 的无关更新。
- **修改建议：** 给出最小diff或可替换代码，优先用 @Track 覆盖全部UI读取字段或等价拆分状态，保留数值更新及单位显示；若选择V2，配套迁移组件、状态和模型装饰器。
- **收益与验证：** 在 value++ 前后打点，同样点击比较目标 CustomNodeUpdate 和 ReceiveVsync Duration；预期 unit 无关更新减少。

---


### 测试用例：FUNC-SCROLL-LAYOUT-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：scroll

#### 输入

状态管理V1。列表滚动帧率低，条目包含多层布局，请减少无独立职责的容器，保持内容、尺寸适配和点击行为。

```ts
@Entry
@Component
struct Page {
  private items: string[] = []
  aboutToAppear(): void {
    for (let i = 0; i < 100; i++) { this.items.push(`Item ${i}`) }
  }
  build() {
    Column() {
      List() {
        ForEach(this.items, (item: string) => {
          ListItem() {
            Stack() {
              Flex({ direction: FlexDirection.Row }) {
                Stack() {
                  Column() {
                    Row() {
                      Text(item).fontSize(14)
                      Text('label').fontSize(12).flexGrow(1)
                    }
                  }
                }
              }
            }
          }
        }, (item: string) => item)
      }.width('100%').height(400)
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** 列表项的 Stack→Flex→Stack→Column→Row 中存在可核实的多余容器；flexGrow 在内层Row的Text上，不能据此认定外层Flex重复测量。
- **修改建议：** 删除没有独立尺寸、对齐、背景、裁剪或事件职责的包装层，将必要属性保留到等价节点；保持文字、尺寸适配、点击和滚动行为。
- **收益与验证：** 同数据和滚动路径，按目标子树ID比较 Create/Measure/Layout 次数与耗时；预期多余容器工作减少，显示和点击保持。

---

### 测试用例：FUNC-BUILDER-001

**skill**：hmos-arkui-performance-analysis
**类型**：functional（功能验证）
**类别**：component

#### 输入

API12、状态管理V1。行情约每秒刷新，if反复创建、销毁6个纯展示StatChip。请降低组件封装开销，保留可复用UI描述、数据更新和交互；隐藏时仍须销毁，不改为节点常驻或实例缓存。

```ts
@Component
struct StatChip {
  @Prop label: string = '';
  @Prop value: string = '';
  build() {
    Row({ space: 6 }) {
      Text(this.label).fontSize(12).fontColor('#666666')
      Text(this.value).fontSize(12).fontColor('#007DFF')
    }
    .padding({ left: 10, right: 10 }).height(30)
    .borderRadius(15).backgroundColor('#F1F3F5')
  }
}
@Entry
@Component
struct StockBoardPage {
  @State show: boolean = true;
  @State tick: number = 0;
  private chips: string[][] = [['涨跌', '+0.8%'], ['最高', '12.40'], ['最低', '12.10'], ['成交量', '2.1万手'], ['成交额', '3560万'], ['换手', '1.7%']];
  build() {
    Column({ space: 12 }) {
      Button('刷新行情').id('board-refresh').onClick(() => {
        this.tick++;
        this.show = !this.show;
      })
      if (this.show) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.chips, (c: string[]) => {
            StatChip({ label: c[0], value: c[1] })
          }, (c: string[]) => c[0])
        }
      }
    }.width('100%').padding(16)
  }
}
```

#### 预期输出

**验证标准**：

- **问题分析：** 行情刷新切换 if，反复创建6个无独立状态或资源职责的 StatChip，产生纯展示自定义组件的实例开销；业务要求保留创建、移除流程。
- **修改建议：** 保留 if 和可复用UI描述封装，将 StatChip 改为 @Builder 传 label/value；保持数据/key、文案、换行布局及事件，隐藏时仍移除标签。
- **收益与验证：** 按同刷新顺序统计 StatChip 创建次数，预期包装实例创建消失；刷新处打点可定位更新帧比较 Duration。
