# 触发验证测试用例

---

### 测试用例：TRIGGER-001

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

帮我分析这个崩溃日志（内容如下）：
Reason:Signal SIGSEGV(SEGV_MAPERR)@0x000000000000000c
#00 pc 00000000000c60e0 /data/storage/el1/bundle/libs/arm64/libimsdk.so(ECSConnection::unRefRequest+60)
#01 pc 000000000038633c /data/storage/el1/bundle/libs/arm64/libimsdk.so

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-002

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

我的应用卡死没响应，这是冻屏日志（内容如下）：
Reason:THREAD_BLOCK_6S
Timestamp:2026-06-05 11:15:07.841
Pid:19655 Uid:10265 ProcessName:com.example.freezetest
MSG:main thread blocked
Tid:19655, Name:mohangmain
#00 pc 00000000000cb5f4 /system/lib/ld-musl-aarch64.so.1

Tid:19660, Name:RenderThread
#00 pc 00000000000ab1f4 /system/lib/librender.so

#### 预期输出

**应触发**：是

---

### 测试用例：TRIGGER-003

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

点击应用就闪退，没有日志

#### 预期输出

**应触发**：是（症状口述入口，进入采集流程）

---

### 测试用例：TRIGGER-004

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

工程能构建也不会崩溃，但冷启动一直白屏，应用没退出。不要先复现，直接定位。

#### 预期输出

**应触发**：是（非崩溃型白屏 source-first 路径）

**评测环境适配**（仅限无脚本执行能力、无工程源码的隔离评测沙箱）：**先做环境判定**——对
输入中引用的工程路径（如有）尝试读取，若不可读或不存在（沙箱内通常如此），**立即**停止一切
文件读取与检索，以会话内白屏分诊结论（非崩溃型白屏存活判定）+ source-first 检视顺序要点
清单（main_pages.json / loadContent / Navigation / hideNavBar / navDestination）收尾即视为
达标；**不得**对同一/相近路径反复重试或变换路径穷举试读，不得在会话内渲染完整 Analyzer
章节，保持会话简洁。

---

### 测试用例：TRIGGER-005

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

DevEco 里我的 ArkTS 代码编译报错了：Property 'name' does not exist on type，帮我修一下

#### 预期输出

**应触发**：否（一般编译错误，不属故障分析）

---

### 测试用例：TRIGGER-006

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

我的应用内存泄漏越来越严重，帮忙分析一下

#### 预期输出

**应触发**：否（内存泄漏/OOM 性能问题，不属三类故障）

---

### 测试用例：TRIGGER-007

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

分析下这段日志：09-21 14:23:31.831 14337 14363 I A0fefe/JSAPP hilog 流水内容

#### 预期输出

**应触发**：是（故障日志分析请求；技能加载后由识别脚本判 out_of_scope 拒答，触发层面仍为"是"）

---

### 测试用例：TRIGGER-008

**skill**：hmos-dfx-analyzer
**类型**：trigger（触发验证）

#### 输入

帮我在设置页面加一个深色模式开关

#### 预期输出

**应触发**：否（常规功能开发）
