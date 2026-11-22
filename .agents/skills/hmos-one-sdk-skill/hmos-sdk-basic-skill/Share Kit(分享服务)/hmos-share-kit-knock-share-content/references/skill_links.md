# Skill相关链接汇总

## API参考文档链接

### Share Kit相关API
- [harmonyShare模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share) - 华为分享核心模块
- [systemShare模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share) - 系统分享模块

### 相关Kit API
- [uniformTypeDescriptor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-uniformtypedescriptor) - 标准化数据定义与描述
- [fileUri](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fileuri) - 文件URI处理

## 开发指南文档链接

### Share Kit指南
- [碰一碰内容分享](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/knock-share-between-phones-content) - 手机与手机碰一碰内容分享
- [碰一碰分享设计指南](https://developer.huawei.com/consumer/cn/doc/design-guides/onehop-0000002354602581) - 碰一碰分享设计规范

### 应用跳转指南
- [使用App Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup) - App Linking应用跳转
- [使用Deep Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/deep-linking-startup) - Deep Linking应用跳转

### App Linking Kit指南
- [App Linking Kit简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-introduction) - App Linking Kit概述
- [直达应用市场能力](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-direct-to-ag) - 直达应用市场
- [延迟链接能力](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-deferredlink) - 延迟链接跳转

## 示例代码资源

### 碰一碰引导资源
- [碰一碰引导资源下载](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/tree/master/entry/src/main/resources/rawfile) - 引导动图资源文件
- [碰一碰引导示例代码](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/components/subpages/KnockShareTips.ets) - 引导提示示例

## 技能内部资源

### 参考文档
- [原始开发指南](references/knock-share-between-phones-content.md) - 原始API开发指南文档

### 示例代码
- [基础碰一碰分享](assets/basic-knock-share.ets) - 基础功能示例
- [预览图延迟更新](assets/preview-delay-update.ets) - 预览图更新示例
- [App Linking分享](assets/app-linking-share.ets) - App Linking跳转示例
- [异常处理](assets/error-handling.ets) - 错误处理示例
- [配置文件示例](assets/module.json5) - 模块配置示例

### 测试用例
- [纯文本分享测试](tests/test_text_share.py) - 文本分享测试
- [链接分享测试](tests/test_hyperlink_share.py) - 链接分享测试
- [图片分享测试](tests/test_image_share.py) - 图片分享测试
- [预览图更新测试](tests/test_preview_update.py) - 预览图更新测试
- [无网络场景测试](tests/test_no_network.py) - 异常场景测试