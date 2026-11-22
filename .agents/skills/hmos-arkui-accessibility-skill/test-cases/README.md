# 评测执行说明（test-cases README）

## 前置条件

1. DevEco Studio（含 hvigor 构建链）；
2. 本 Skill 已安装到评测用 Agent 环境（SKILL.md + references + templates 同步到位）；
3. 评测工程模板：普通 ArkTS 工程（API 版本可按用例"环境构造"列调整 build-profile.json5 三字段：
   `compileSdkVersion` / `compatibleSdkVersion` / `targetSdkVersion`）。

## 执行步骤

```bash
# 1. 结构自检（无需 IDE，任意环境，在 skill 根目录执行）
python3 test-cases/check_skill.py

# 2. 逐用例执行（B01~B20，见 cases-b01-b20.md）
#    a. 按用例"环境构造"准备工程与目标文件
#    b. 将"开发者 Prompt"输入装配了本 Skill 的 Agent
#    c. 记录 Skill 输出（方案/代码/追问）
#    d. 输出含代码时拷入工程执行 hvigor 构建，记录编译结果
#       hvigorw assembleHap --mode module -p product=default
#    e. 按"可验证预期"逐项核对，记录通过项数

# 3. 汇总指标并回填 report-template.md
```

## 指标定义

| 指标 | 口径 | 通过标准 |
|------|------|----------|
| 编译成功率 | 编译通过用例数 / 产生代码用例总数 | ≥ 70% |
| 功能正确率 | 预期项全部满足的用例数 / 总用例数 | ≥ 60% |

注意：纯答疑/追问类用例（如 B01 门、B08 阻断）不产生代码，不计入编译分母；
其"不生成无法编译代码"本身是预期项，计入正确率。

## 本环境（无 DevEco/hvigor）替代验证

结构/事实一致性自检：`python3 test-cases/check_skill.py`（覆盖：
交付件齐备性、事实表与源码注册表一致性、模板属性合规性、用例-事实引用有效性）。
指标类（编译/正确率）必须由具备 hvigor 环境处执行后回填，不得以自检替代。

## 结果回填

评测完成后将各用例结果与指标填入 `report-template.md`，作为 AC-14（评测报告交付）交付物归档。
