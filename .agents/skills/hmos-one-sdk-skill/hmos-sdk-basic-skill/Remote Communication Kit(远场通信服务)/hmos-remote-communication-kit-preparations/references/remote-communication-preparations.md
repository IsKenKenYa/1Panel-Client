# 开发准备
---
# 开发准备
#### 申请权限
应用在使用Remote Communication Kit能力前，需要检查是否已经获取对应权限。如未获得授权，需要声明对应权限。
除取消网络请求、关闭会话外，其余请求都需要权限。Remote Communication Kit所需权限有：
-
ohos.permission.INTERNET：用于应用访问互联网。
-
ohos.permission.GET_NETWORK_INFO：用于获取设备网络信息。
必须手动配置上述权限后才能使用，详细配置参见 [申请权限步骤](#申请权限步骤) 。
#### 申请权限步骤
需要在entry/src/main路径下的module.json5中配置所需申请的权限。示例代码如下所示：
```typescript
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```
#### C API开发准备
除上述权限配置外，C API使用时还需要在CMakeLists.txt中设置动态库路径及头文件路径，并进行链接。
如编译target为entry，则添加如下命令：
```cpp
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC librcp_c.so) # 链接librcp_c.so及其他依赖的so
```
#### HTTP明文设置
从6.1.0(23)开始，新增支持HTTP明文拦截配置。
HTTP是明文传输协议，为保障数据安全，通常需禁用HTTP，仅允许HTTPS。可通过src/main/resources/base/profile/network_config.json（该文件不存在时可以手动创建）配置HTTP明文传输策略。相关配置可以参考 [明文http访问权限配置说明](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/网络/Network Kit（网络服务）/访问网络/使用HTTP访问网络/http-request.md) 。
以下示例配置全局允许明文传输，但禁止对 "example.com" 域名使用明文通信。在此设置下，Remote Communication Kit仅能通过HTTPS访问该域名；若尝试发起HTTP请求，将触发错误码 [1007900201](D:/code/APIDevice/output/md_output/harmonyos-references/errorcode-remote-communication.md) 。
```json
{
  "network-security-config": {
    "base-config": {
      "cleartextTrafficPermitted": true
    },
    "domain-config": [
      {
        "domains": [
          {
            "name": "example.com"
          }
        ],
        "cleartextTrafficPermitted": false
      }
    ],
    "component-config": {
      "Remote Communication Kit": true
    }
  }
}
```