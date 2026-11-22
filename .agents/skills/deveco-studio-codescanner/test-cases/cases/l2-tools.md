# L2 知识库工具测试用例

> 层对象：scripts/extract-rules.js 输入输出行为
> 质量属性：脚本可执行性（输入→输出可判定）
> 编号规则：TC-L2-<序号>
> 说明：解析类脚本（parse-sarif / parse-log / analyze-results）已随需求设计去除，本层仅保留规则提取工具。

---

## TC-L2-01 extract-rules.js 提取数量（P1）

- 前置：部署根目录（26.0.1.272）或规则 JSON 副本
- 步骤：`node scripts/extract-rules.js <deployRoot>`
- 预期：stdout 含 C++ 27 条分组表 + ArkTS 23 条分组表；`--out` 写文件后 stderr 提示写入路径
- 对应遗留问题：规则文档随部署版本更新的校验手段
