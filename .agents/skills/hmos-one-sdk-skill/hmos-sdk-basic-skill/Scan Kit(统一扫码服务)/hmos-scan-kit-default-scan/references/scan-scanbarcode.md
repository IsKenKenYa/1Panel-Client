# 默认界面扫码开发指南

原始文档链接: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-scanbarcode

本文档提供了默认界面扫码功能的详细开发指南。

## 主要内容

1. **场景介绍** - 默认界面扫码能力提供系统级体验一致的扫码界面
2. **约束与限制** - API版本要求、设备支持、功能限制
3. **业务流程** - 完整的扫码流程说明
4. **接口说明** - startScanForResult接口详细说明
5. **开发步骤** - 具体的开发实现步骤
6. **模拟器开发** - 模拟器使用指导

## 相关参考文档

- [scanBarcode API参考说明](scan-scanbarcode-api.md)
- [scanCore API参考说明](scan-scancore.md)
- [接入"扫码直达"服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-directservice)

## 核心要点

- 从API版本4.0.0(10)开始提供默认界面扫码能力
- 无需申请相机权限(系统预授权)
- 支持Promise和Callback两种异步回调方式
- 从6.1.0(23)版本开始支持标题动态显示
- 支持单码和多码识别模式
- 相册扫码只支持单码识别

详细内容请参考原始文档链接。