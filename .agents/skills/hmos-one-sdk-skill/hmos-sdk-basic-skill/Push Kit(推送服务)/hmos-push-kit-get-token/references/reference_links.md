# 参考文档索引

本目录包含获取Push Token技能的相关参考文档链接。

## 开发指南文档

- [获取Push Token开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-get-token)
  - 原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-guides\应用服务\Push Kit（推送服务）\开发准备\获取Push Token\push-get-token.md
  - 转换规则：harmonyos-guides目录下的文档转换为 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ + 文件名（去掉.md）

- [开通推送服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/push-config-setting)
  - 原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-guides\应用服务\Push Kit（推送服务）\开发准备\开通推送服务\push-config-setting.md
  - 转换规则：harmonyos-guides目录下的文档转换为 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ + 文件名（去掉.md）

## API参考文档

- [pushService API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-pushservice)
  - 原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-references\应用服务\Push Kit（推送服务）\ArkTS API\push-pushservice.md
  - 转换规则：harmonyos-references目录下的文档转换为 https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ + 文件名（去掉.md）

- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-error-code)
  - 原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-references\应用服务\Push Kit（推送服务）\ArkTS API\push-error-code.md
  - 转换规则：harmonyos-references目录下的文档转换为 https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ + 文件名（去掉.md）

## 链接转换规则说明

根据用户要求，Skill文档中保留的md链接需要按照以下规则进行转换：

1. **harmonyos-guides目录下的文档**：
   - 转换格式：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/` + 文件名（去掉.md）
   - 示例：`D:\code\APIDevice\output\md_output\harmonyos-guides\AI\Agent Framework Kit（智能体框架服务）\harmony-agent-framework-kit-guide.md`
   - 转换为：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/harmony-agent-framework-kit-guide`

2. **harmonyos-references目录下的文档**：
   - 转换格式：`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/` + 文件名（去掉.md）
   - 示例：`D:\code\APIDevice\output\md_output\harmonyos-references\应用服务\Push Kit（推送服务）\ArkTS API\push-pushservice.md`
   - 转换为：`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-pushservice`

## API搜索工具

用于查找API参考文档的工具脚本位于：
- `C:\Users\z00810349\.config\opencode\skills\api-coding-skill-creator\scripts\search_api.py`

使用方法：
```bash
python search_api.py getToken -d "D:\z00810349\APIDevice\output\md_output\harmonyos-references" --verify -l 10
```