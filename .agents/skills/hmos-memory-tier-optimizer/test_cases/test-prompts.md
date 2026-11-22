# 测试提示词
"内存优化"、"低端机内存"、"内存分档"、"内存超标"、"PSS 过高"、"内存前后对比"、"cachedCount"、"图片内存"、"Web 预加载"、"内存泄漏"

## 基础功能测试
标准输入可以为：请使用 hmos-memory-tier-optimizer skill，采集应用 com.xxx.xxx 的内存数据并分析低端机内存瓶颈，给出分档优化方案

### 测试场景 1：[内存分档优化触发测试]
**提示词** 低端机内存超标怎么降

**预期输出**：
Agent 将自动命中 hmos-memory-tier-optimizer skill 技能

### 测试场景 2：[完整闭环测试]
**提示词** 帮我优化这个应用的内存，做个 before/after 对比

**预期输出**：
Agent 将自动命中 hmos-memory-tier-optimizer skill，并按 7 步工作流（采集→分析→确认→修改审查→构建安装→复测→patch报告）推进
