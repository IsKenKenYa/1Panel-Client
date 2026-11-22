# 取消网络请求（C++）

在远场通信服务的框架中，使用HMS_Rcp_CancelSession方法可以取消传入session的所有正在进行的网络请求。如果开发者需要取消特定的一个网络请求，可以使用HMS_Rcp_CancelRequest方法，并传入需要取消的请求，以实现这一目标。开发者们可以根据具体需求，灵活地管理和控制网络请求的执行。总之，HMS_Rcp_CancelRequest方法的灵活运用，不仅能够优化网络资源的使用，还能提升应用程序的用户体验。

## 约束与限制

取消网络请求能力支持Phone、2in1、Tablet、Wearable设备。并且从5.1.1(19)开始，新增支持TV设备；从6.1.0(23)开始，新增支持Car设备。

## 接口说明

具体API说明详见 [接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview) 。

| 接口名 | 描述 |
| --- | --- |
| uint32_t HMS_Rcp_CancelRequest([Rcp_Session](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview)*session, const[Rcp_Request](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview)*request); | 取消指定或所有正在进行的会话请求。 |

## 使用示例

### 1. CPP侧导入模块

```cpp
#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
```

### 2. CMakeLists.txt中添加以下lib

（具体请见 [C API开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-preparations) ）。

```cpp
librcp_c.so
```

### 3. 创建会话，会话发起请求，并在使用fetch请求后，使用HMS_Rcp_CancelRequest取消网络请求

销毁request并关闭session。"http://www.example.com"请根据实际情况替换为想要请求的URL地址。

```cpp
void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode)
{
    (void *)usrCtx;
    if (response != NULL) {
        printf("Response status: %d\n", response->statusCode);
    } else {
        printf("Fetch failed: errCode: %u\n", errCode);
    }
    if (response != NULL) {
        response->destroyResponse(response);
    }
}

int main() {
    const char *kHttpServerAddress = "http://www.example.com/delete";
    Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
    request->method = RCP_METHOD_DELETE;
    uint32_t errCode = 0;
    
    // 创建session
    Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
    
    // 配置请求回调
    Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
    
    // 发起fetch请求
    errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
    
    // 取消指定request的请求，处理errCode
    errCode = HMS_Rcp_CancelRequest(session, request);
    
    // 取消指定session的全部请求，处理errCode
    errCode = HMS_Rcp_CancelSession(session);
    
    // 清理request
    HMS_Rcp_DestroyRequest(request);
    
    // 关闭session
    errCode = HMS_Rcp_CloseSession(&session);
    
    // 处理errCode
    return 0;
}
```