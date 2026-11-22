# API参考文档链接

本技能相关的原始API文档链接如下：

## API开发指南

- **迁移模式设置开发指南(C/C++)**  
  原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\网络\Network Boost Kit（网络加速服务）\连接迁移(多网切换) (C_C++)\迁移模式设置 (C_C++)\networkboost-reporthandovermode-c.md  
  在线文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-reporthandovermode-c

- **Network Boost Kit开发准备**  
  原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\网络\Network Boost Kit（网络加速服务）\开发准备\networkboost-preparations.md  
  在线文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations

## API参考说明

- **Network Boost Kit API参考总览**  
  原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-references\系统\网络\Network Boost Kit（网络加速服务）\C API\模块\network-boost-c-overview.md  
  在线文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview

- **连接迁移头文件说明**  
  原始路径：D:\z00810349\APIDevice\output\md_output\harmonyos-references\系统\网络\Network Boost Kit（网络加速服务）\C API\头文件和结构体\头文件\network-boost-c-files-handover.md  
  在线文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-handover

## API版本信息

- **起始版本**：5.1.0(18)
- **系统能力**：SystemCapability.Communication.NetworkBoost.Core
- **库文件**：libnetwork_boost.so
- **头文件**：NetworkBoostKit/network_boost_handover.h

## 权限要求

- **必需权限**：ohos.permission.GET_NETWORK_INFO
- **可选权限**：ohos.permission.INTERNET（网络访问）
- **受限权限**：ohos.permission.LINKTURBO（仅多网并发需要）

## 相关API

### 核心API
- `HMS_NetworkBoost_SetHandoverMode(NetworkBoost_HandoverMode mode)` - 设置迁移模式

### 相关API
- `HMS_NetworkBoost_RegisterHandoverChangeCallback()` - 注册迁移回调
- `HMS_NetworkBoost_UnregisterHandoverChangeCallback()` - 取消注册迁移回调

## 枚举定义

### NetworkBoost_HandoverMode
```cpp
enum NetworkBoost_HandoverMode {
    NB_MODE_DELEGATION = 0,  // 委托模式（系统控制）
    NB_MODE_DISCRETION = 1   // 自主模式（应用控制）
}
```

## 返回值说明

| 返回值 | 说明 |
|-------|------|
| 0 | 成功 |
| 201 | 权限不足 |
| 401 | 参数错误 |
| 801 | 系统能力不支持 |
| 62100001 | 内部错误 |
| 62100002 | 系统服务操作失败 |