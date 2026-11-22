# 参考文档说明

本技能基于以下官方HarmonyOS API文档生成:

## API开发指南

- **原文档路径**: `D:\code\APIDevice\output\md_output\harmonyos-guides\系统\调测调优\Performance Analysis Kit（性能分析服务）\事件订阅\使用HiAppEvent订阅事件\系统事件\应用冻屏告警事件\订阅应用冻屏告警事件（ArkTS）\hiappevent-watcher-appfreezewarning-events-arkts.md`
- **官方链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-appfreezewarning-events-arkts
- **说明**: 订阅应用冻屏告警事件(ArkTS)的开发指南,包含完整的开发步骤、代码示例和验证方法

## API参考说明

- **原文档路径**: `D:\code\APIDevice\output\md_output\harmonyos-references\系统\调测调优\Performance Analysis Kit（性能分析服务）\ArkTS API\js-apis-hiviewdfx-hiappevent.md`
- **官方链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent
- **说明**: @ohos.hiviewdfx.hiAppEvent应用事件打点API的详细接口说明,包含参数规格、返回值、错误码等完整定义

## 相关参考文档

- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [应用事件打点错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent)
- [HiAppEvent介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-intro)

## 链接转换规则

根据用户要求,本技能中的文档链接遵循以下转换规则:
1. 保留md文件名
2. 如果md文件实际在harmonyos-guides中,替换为: `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/` + 文件名(去掉.md后缀)
3. 如果md文件实际在harmonyos-references中,拼上: `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/` + 文件名(去掉.md后缀)

## API查找目录

本技能的API查找目录设置为: `D:\code\APIDevice\output\md_output\harmonyos-references`

可通过以下方式查询API定义:
```bash
python scripts/search_api.py hiAppEvent -d D:\code\APIDevice\output\md_output\harmonyos-references -L ArkTS --verify -l 20 -v
```