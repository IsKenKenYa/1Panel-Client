# Wear Engine服务连接状态相关错误码

## 401 参数错误
**错误信息**
Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types; 3. Parameter verification failed.

**错误描述**
参数错误。

**可能原因**
必选参数没有传入,或者参数类型错误。

**处理步骤**
1. 请检查必选参数是否没有传入,或者传的参数类型是否错误。
2. 通过[在线提单](https://developer.huawei.com/consumer/cn/support/feedback/#/)提交问题,华为支持人员会及时处理。

## 1008500012 回调函数过多
**错误信息**
Too many callbacks of the same type.

**错误描述**
回调函数过多。

**可能原因**
在同一个type上注册了过多的回调函数。

**处理步骤**
及时关闭已经不再使用的监听事件。

## 1008509999 内部错误
**错误信息**
Internal error.

**错误描述**
内部错误。

**可能原因**
1. 应用的签名证书等信息和云端不一致。
2. randomId错误。
3. 应用未在metadata中配置clientId。
4. WearEngine发生未知错误。

**处理步骤**
1. 调试时检查应用的签名证书等信息,与开发者联盟是否一致。
2. 断开重连设备。
3. 在metadata中[配置clientId](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/configuration_client_id)。
4. 通过[在线提单](https://developer.huawei.com/consumer/cn/support/feedback/#/)提交问题,华为支持人员会及时处理。