# DMA 劣化案例模式（XComponent SurfaceBuffer 未释放 / cachedCount 缓存图片数量过多）

## 一、不可见 XComponent SurfaceBuffer 未释放

### 案例模式描述

应用使用 XComponent（视频播放、相机预览、渲染画布等场景）持有 NativeImage/Surface，其 BufferQueue 中的 SurfaceBuffer 由 gralloc 分配 **DMA 内存**。当 XComponent 不可见（页面被覆盖/组件隐藏/应用退后台）但未正确释放 surface 时，buffer 队列中驻留的 SurfaceBuffer 无法归还 DMA heap，表现为：

- DMA（Graph）总量增长（SurfaceBuffer 底层为 DMA buffer）；
- `libbuffer_handle.z.so`（SurfaceBuffer 句柄管理库）占用增长（存活 SurfaceBuffer 对象增多）。

这类劣化本质是**不可见 XComponent 的 SurfaceBuffer 滞留**，属释放逻辑缺陷，而非分配量合理增长。

### 匹配规则

1. **`libbuffer_handle.z.so` 劣化**：步骤 2 对比（汇总表层级结构「系统SDK → Graphics Surface → libbuffer_handle.z.so」占用增长，或 Top10 劣化 SO 中出现该 SO）或步骤 5 smaps 对比（`diff_smaps.py`）中该 so `delta_pss > 0`。
2. **调用栈含有 `ReadSurfaceBufferImpl` 关键帧**：步骤 4 native heap 差分结果（聚类树/差分树 JSON、火焰图）中，劣化调用栈包含 `ReadSurfaceBufferImpl` 关键帧（SurfaceBuffer 读取路径；匹配时对帧名模糊匹配，db 符号表位于 `data_dict` 表）。
3. **源码检查 XComponent 释放逻辑异常**：结合源码工程检查 XComponent 生命周期——不可见或销毁时是否停止渲染并释放 surface。检查要点：
   - 页面 `onShown`/`onHidden`/`aboutToDisappear` 中是否停止渲染并释放 XComponent 持有的 surface；
   - `XComponentController` 是否在组件销毁时正确解绑/清理（模块级长期持有会抬高基线，见 `arkts-heap-workflow.md` 常驻原生句柄规则）；
   - native 侧 `OnSurfaceDestroyed`/销毁回调中是否清理 buffer 队列、destroy surface。

三条规则同时命中即确认：劣化源于不可见 XComponent 的 SurfaceBuffer 未释放，DMA 内存增长。规则 3 未发现释放逻辑缺陷时，仅凭规则 1/2 不得下此结论（可能是合理的可见渲染增长），8.1 根因列写「未匹配案例库，需人工核查」。

### 问题代码

典型反模式（源码检查时按上列检查要点逐项核对）：

- XComponent 所在页面隐藏/被覆盖后仍持续渲染，surface 未释放，BufferQueue 中已分配的 SurfaceBuffer 一直驻留；
- native 侧只实现了 `OnSurfaceCreated`/`OnSurfaceChanged`，未实现或未在 `OnSurfaceDestroyed` 中归还 buffer、销毁 surface；
- `XComponentController` 被模块级单例长期持有，组件销毁后 controller 仍锚定旧 surface，阻止 SurfaceBuffer 释放。

## 二、cachedCount 缓存图片数量过多

### 案例模式描述

应用在 List/Grid/WaterFlow/Swiper 等滚动容器上配置 `.cachedCount(n)`（预加载区域属性，控制可视区域外提前加载/缓存的节点数量）。当容器列表项为图片（Image）且 cachedCount 新增或调大时，预加载区域内的大量图片节点被提前创建并**解码为 pixelmap 常驻 DMA**，表现为：

- `libhdi.so`（实际 so 名 `libhdi.z.so`，系统 HDI 设备接口框架库，匹配时对 so 名模糊匹配涵盖两种写法）占用增长（Top10 劣化 SO，图形 buffer 经 HDI/gralloc 分配路径增多）；
- DMA（Graph）内存增长，图片类 buffer（buf_type `pixelmap`）**数量**较旧版增加。

这类劣化本质是**预加载区域驻留的已解码图片数量过多**，属配置型数量增长，而非业务图片资源的合理增长。

### 匹配规则

> **输入**：对比报告第四章「Top10 劣化 SO」表 + 第五章 DMA 对比分析（总览对账 + Top10 图片/资源劣化）+ 两版 `<版本>/analysis/dma_detail.xlsx`（`DMA_by_image` sheet）+ A/B 两版应用源码工程（做版本 diff）。

1. **Top10 劣化 `libhdi.so`（数据规则）**：对比报告第四章 Top10 劣化 SO 表中出现 `libhdi.so`（`libhdi.z.so`）行，且「差值(MB)」列 > 0。
2. **报告 DMA 内存增加（数据规则）**：对比报告第五章 DMA 总览中 Graph(DMA) 总量差值 > 0（合计差值 > 0.5 MB 时第五章必有 Top10 图片明细），且三方对账一致（topdown `Graph` 行 ≡ 汇总表 `libdmabufheap.z.so`/DMA 行 ≡ `dma_detail` 合计）。
3. **dma_detail.xlsx 图片数量增加（数据规则）**：对比两版 `analysis/dma_detail.xlsx` 的 `DMA_by_image` sheet，图片类 buffer（buf_type 为 `pixelmap` 等）**数量较旧版增加**——新出现的图片 buf_name 行（如 `srcImageSize-...-mimetype-png`）、或同 buf_name 条目数增加。辅证：第五章 DMA 总览「缓冲区个数」列差值为正、5.1 Top10 表中出现图片类正差值项。
4. **源码 diff 新增 cachedCount（核查规则）**：对比 A/B 两版源码 diff，发现**新增**的 `.cachedCount(...)` 配置——List/Grid/WaterFlow/Swiper 等容器的预加载区域属性新配置，或已有配置数值调大（LazyForEach 场景的容器 `.cachedCount()` 与 Repeat 的 template `cachedCount` 两者控制对象不同，但都会驻留图片节点，均计入）。检查要点：
   - diff 中逐个定位新增/调大的 `.cachedCount(` 调用点，记录 `文件:行号` 与数值；
   - 核对所在容器：列表项是否含 Image 大图（图片列表/瀑布流）、cachedCount 数值是否远超一屏节点数；
   - 降级说明：仅单版源码可得、无法做版本 diff 时，本规则按「无法判定」处理，案例按未匹配降级（见 `optimization-workflow.md` 1.2）。

四条规则同时命中即确认：劣化源于 cachedCount 新增/调大致预加载区域驻留的已解码图片数量过多。规则 4 未发现新增 cachedCount 时，仅凭规则 1/2/3 不得下此结论（DMA 图片增长可能来自业务图片正常增多），8.1 根因列写「未匹配案例库，需人工核查」。

### 问题代码

典型反模式（源码检查时按上列检查要点逐项核对）：

```typescript
// 反模式：图片瀑布流 cachedCount 远超一屏数量，预加载区域解码大量图片常驻 DMA
WaterFlow() {
  LazyForEach(this.dataSource, (item) => {
    FlowItem() {
      Image(item.url) // 列表项为大图
    }
  }, (item) => item.id)
}
.cachedCount(20) // 一屏仅 6~9 项，预加载区域驻留大量已解码 pixelmap
```

- 图片列表新增 `.cachedCount(10+)`，预加载区域内每个 Image 都触发解码并缓存，图片 buffer 数量与 DMA 总量同步上涨；
- Repeat 多模板场景 template `cachedCount` 统一设置过大，各模板缓存池均驻留图片节点。