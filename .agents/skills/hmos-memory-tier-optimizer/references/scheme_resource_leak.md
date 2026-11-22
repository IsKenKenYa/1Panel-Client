# 方案三：资源泄漏修复

**适用场景**：Timer 未清理、文件描述符泄漏、Native 内存未释放、线程泄漏。

**方案原理**：资源泄漏是内存持续增长的常见原因。通过在组件/Ability 生命周期中正确释放资源，防止内存无限增长。

## 泄漏类型及修复方式

### 1. Timer 泄漏

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范

// ❌ 泄漏：未清理定时器
aboutToAppear() {
  setInterval(() => { this.pollData(); }, 5000);
}

// ✅ 修复：保存 timerID 并在 aboutToDisappear 中清理
private pollTimerId: number = -1;

aboutToAppear() {
  this.pollTimerId = setInterval(() => { this.pollData(); }, 5000);
}

aboutToDisappear() {
  if (this.pollTimerId !== -1) {
    clearInterval(this.pollTimerId);
    this.pollTimerId = -1;
  }
}
```

### 2. 文件描述符泄漏

```typescript
// ❌ 泄漏：未关闭文件描述符
let fd: number = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY).fd;
let content: string = fileIo.readSync(fd, buf);
// 忘记 closeSync(fd)

// ✅ 修复：确保 finally 块中关闭
let fd: number = -1;
try {
  fd = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY).fd;
  let content: string = fileIo.readSync(fd, buf);
} finally {
  if (fd >= 0) {
    fileIo.closeSync(fd);
  }
}
```

### 3. Native 内存泄漏

```typescript
// ❌ 泄漏：malloc 后未 free
let ptr: object = nativeModule.alloc(size);
// 忘记释放

// ✅ 修复：确保 malloc/free 配对，使用 try-finally
let ptr: object | null = null;
try {
  ptr = nativeModule.alloc(size);
  // 使用 ptr
} finally {
  if (ptr !== null) {
    nativeModule.free(ptr);
  }
}
```

### 4. 线程泄漏

```typescript
// ❌ 泄漏：Worker 线程未 terminate
let worker: worker.ThreadWorker = new worker.ThreadWorker('workers/my_worker.js');
// 忘记 worker.terminate()

// ✅ 修复：在不使用时 terminate
private workerInstance: worker.ThreadWorker | null = null;

aboutToDisappear() {
  if (this.workerInstance !== null) {
    this.workerInstance.terminate();
    this.workerInstance = null;
  }
}
```

## 设备分档策略

资源泄漏修复不依赖设备分档，所有设备均需修复。但在分析时可根据设备分档调整泄漏容忍度：

| 设备分档 | 泄漏容忍度 | 说明 |
|---------|-----------|------|
| low | 零容忍 | 低内存设备上泄漏影响更大 |
| medium | 零容忍 | 标准要求 |
| high | 零容忍 | 虽然内存充足但泄漏终将导致 OOM |

## 泄漏定位代码扫描模式

| 泄漏类型 | 搜索关键词 | 定位文件方式 | 确认方式 |
|----------|-----------|-------------|----------|
| Timer | `setInterval`, `setTimeout` | 搜索结果所在文件 | 检查同文件 `aboutToDisappear` 或 `onDestroy` 中是否有清理 |
| FD | `openSync`, `open(` (fileIo) | 搜索结果所在文件 | 检查同函数 `finally` 或后续是否有 `closeSync/close` |
| Worker | `ThreadWorker`, `worker.` | 搜索结果所在文件 | 检查 `aboutToDisappear` 中是否有 `terminate` |
| Native | `alloc`, `malloc` (native 模块) | 搜索 .ets + .cpp 文件 | 检查是否有对应的 `free`/`dealloc` |

## 注意事项

- 资源泄漏修复不依赖设备分档，所有设备均需修复
- 修复后应重新采集 meminfo 验证 PSS 是否停止增长
- 如果存在多次 PSS 采样数据，可计算修复前的增长斜率，与修复后对比
