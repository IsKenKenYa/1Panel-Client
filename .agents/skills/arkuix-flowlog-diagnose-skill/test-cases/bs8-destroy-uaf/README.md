# B-S8 验证工程：销毁路径压力（屏障/UAF 风险场景）

## 场景
高频路由进出（push HeavyPage → 快速 back）+ onDisappear 3 秒慢任务 → 销毁屏障/竞态压力。

## 工程要点
- Index：按钮 push HeavyPage；HeavyPage：onDisappear 同步 3 秒慢任务
- 自动化：tap 进入 → 1 秒后 back（不等慢消失完成，制造销毁竞态窗口）×3 轮

## 验证结果（2026-10 实证，如实记录）

### ✅ 达成：销毁链锚点日志完整可查
```
AceContainerSG::Destroy start
AceContainerSG::Destroy pipelineContext_ end    ← 屏障完成
AceContainerSG::Destroy frontend start/end
Destroy Frontend on JS thread
AceContainerSG::Destroy end
Wait UI thread... / Wait JS thread...
```
skill 维度①销毁段锚点（test-case B-S8 的 start/end/Wait 系列）实测全部可见——
**skill 可据此判断销毁流程完整性**：链完整→排除销毁 UAF；断链（start 无 end）→ UAF 嫌疑。

### ❌ 未达成：UAF crash 本身未触发
3 轮压力 + 3 秒慢 onDisappear，进程存活无 crash。
**真实 UAF 需框架并发缺陷配合**——应用层用例只能造压力条件，无法稳定复现 test-case B-S8 的"start 无 end + crash"模式。
（这正是 skill 的价值：正常压测下链完整→排除；若真有框架缺陷，断链日志即证据）

## 复现
```powershell
ace build apk --debug
adb install -r <apk>; adb shell am start -n com.example.bs8_uaf/.EntryEntryAbilityActivity
# 自动化压力（tap进→1s后back×3）：
for($i=0;$i -lt 3;$i++){ adb shell input tap 540 1100; sleep 1; adb shell input keyevent 4; sleep 1 }
# 抓 logcat 看 AceContainerSG::Destroy 链
```
