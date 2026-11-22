# 系统定义的公共事件
---
# 系统定义的公共事件
本文档提供了系统定义的公共事件清单。
公共事件类型定义在 [ohos.commonEventManager模块的Support枚举](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/进程线程通信/js-apis-commoneventmanager.md) 中。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/80/v3/ofH_qpJySfaST6-Wf946sQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=6DFDD9DE456090CB7EA68F16DFE8EDBCDA280F9FAB648A5C2A210083C99FA441)
本模块首批接口从API version 9开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。
#### Ability Kit
#### COMMON_EVENT_PACKAGE_RESTARTED
表示用户重启应用包并终止其所有进程。
在设备上指定用户重启应用包并终止其所有进程，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/66/v3/I7t4hKOJScu9cA61N7OSqQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=087613EB717A37FB49A33C4F3740B35ADB3BA64739E3343A17424146603DC631)
三方应用只能监听自身应用的重启事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_RESTARTED"
#### COMMON_EVENT_PACKAGE_DATA_CLEARED
表示用户清除应用包数据。
在设备上指定用户清除应用包数据，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ba/v3/7Rjri9QjSeKcp1lmv-E6WQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=8B94E909AFFAD6F4DDC1500C31B9F925CABE4373C2B20D820435F4559BE0F184)
三方应用只能监听自身应用的数据清理事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_DATA_CLEARED"
#### COMMON_EVENT_QUICK_FIX_APPLY_RESULT
表示快速修复应用。
在设备上指定用户快速修复应用，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/96/v3/Ms9L16gLTt2J1u40AsVJbw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=AA6433617C0E5A0C1CC712D9789377F4F5BA479C6B7E07BEA69BA6097D819D8D)
三方应用只能监听自身应用的快速修复事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.QUICK_FIX_APPLY_RESULT"
#### COMMON_EVENT_QUICK_FIX_REVOKE_RESULT10+
表示撤销快速修复。
在设备上撤销快速修复时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.QUICK_FIX_REVOKE_RESULT"
#### COMMON_EVENT_PACKAGE_ADDED
表示设备上已安装新应用包的公共事件的动作。
在设备上指定用户下安装了新的应用程序，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/19/v3/R-eycHCmSC6aX-o2NJm4Bg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=430421DDD664929AAF1023F5181624C49CAC53C7BB193C049BE0153917A59EF5)
三方应用只能监听自身应用的安装事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_ADDED"
#### COMMON_EVENT_PACKAGE_REMOVED
表示已从设备卸载已安装的应用程序，但应用程序数据保留的公共事件的操作。
在设备指定用户下卸载指定的应用程序包，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c4/v3/8vux8dCMQ7CfA9J5Th26XA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=BAAE7B6506642CF9DEBF9065D6B2F83E99288FA83A71D7B2C112B3AED14E858F)
三方应用只能监听自身应用的卸载事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_REMOVED"
#### COMMON_EVENT_BUNDLE_REMOVED
表示现有的应用程序包从设备中移除的事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.BUNDLE_REMOVED"
#### COMMON_EVENT_PACKAGE_FULLY_REMOVED
表示现有的应用程序包从设备上完全删除的事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_FULLY_REMOVED"
#### COMMON_EVENT_PACKAGE_CHANGED
表示应用包已更改的公共事件的动作（例如，包中的组件已启用或禁用）。
在设备上安装的应用程序包更新或者包的组件被禁用使能，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/7d/v3/8hdFWTHYS7ODLryQVatPHg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=11C9995832738350AA8490B55F5AE4AB95B4448FC1195548474DEBD17F09DD87)
三方应用只能监听自身应用的更改事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_CHANGED"
#### COMMON_EVENT_PACKAGE_CACHE_CLEARED
表示用户清除应用包缓存数据的公共事件的动作。
对设备上安装的应用程序包清除缓存时，将会触发事件通知服务发布该系统公共事件。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/80/v3/gnUibX4sSzuNIOXhuh9STA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=5724EE4E674D5A045369C98E97D250F21B4718D041E12A5F654AB53A10BB2FA5)
三方应用只能监听自身应用的缓存清理事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_CACHE_CLEARED"
#### COMMON_EVENT_PACKAGES_SUSPENDED
表示包已经被挂起。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGES_SUSPENDED"
#### COMMON_EVENT_MY_PACKAGE_SUSPENDED
发送到已被系统挂起的包。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.MY_PACKAGE_SUSPENDED"
#### COMMON_EVENT_MY_PACKAGE_UNSUSPENDED
发送到已被系统解除挂起的包。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.MY_PACKAGE_UNSUSPENDED"
#### COMMON_EVENT_MANAGE_PACKAGE_STORAGE
通知用户低内存状态并且应该启动包管理。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.MANAGE_PACKAGE_STORAGE"
#### Account Kit
#### COMMON_EVENT_MINORSMODE_ON12+
表示用户开启未成年人模式。
在设备上开启未成年人模式，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**取值：** "usual.event.MINORSMODE_ON"
#### COMMON_EVENT_MINORSMODE_OFF12+
表示用户关闭未成年人模式。
在设备上关闭未成年人模式，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**取值：** "usual.event.MINORSMODE_OFF"
#### ArkData
#### COMMON_EVENT_DATA_SHARE_READY12+
表示datashare服务可用。
datashare服务启动完成后，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.DATA_SHARE_READY"
#### ArkUI
#### COMMON_EVENT_SPLIT_SCREEN
表示分屏行为的公共事件。
启动最近任务窗口、创建或销毁分屏条，都会触发通知服务发布这个系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**取值：** "common.event.SPLIT_SCREEN"
#### Notification Kit
#### COMMON_EVENT_SLOT_CHANGE
表示通知渠道或通知开关发生变化。
通知设置里修改应用的渠道参数、渠道开关，或者开启、关闭通知使能开关时，都会触发通知服务发布这个系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.NOTIFICATION_CONTROLLER
**取值：** "usual.event.SLOT_CHANGE"
#### Background Tasks Kit
#### COMMON_EVENT_DEVICE_IDLE_MODE_CHANGED
表示设备上待机状态变化，触发公共事件发布动作。
如果用户一段时间没有使用设备且屏幕已经关闭情况下，系统延迟后台应用程序CPU和网络访问，将会触发公共事件服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.DEVICE_IDLE_MODE_CHANGED"
#### Basic Services Kit
#### COMMON_EVENT_USB_STATE
表示USB设备状态发生变化。
当USB断开或者连接时状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.hardware.usb.action.USB_STATE"
#### COMMON_EVENT_USB_PORT_CHANGED
提示用户设备的USB端口状态发生改变。
当USB的端口状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.hardware.usb.action.USB_PORT_CHANGED"
#### COMMON_EVENT_USB_DEVICE_ATTACHED
当用户设备作为USB主机时，提示USB设备已挂载。
当USB连接时状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.hardware.usb.action.USB_DEVICE_ATTACHED"
#### COMMON_EVENT_USB_DEVICE_DETACHED
当用户设备作为USB主机时，提示USB设备被卸载。
当USB断开时状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.hardware.usb.action.USB_DEVICE_DETACHED"
#### COMMON_EVENT_TIME_CHANGED
设置系统时间的公共事件的动作。
当设置系统时间时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.TIME_CHANGED"
#### COMMON_EVENT_TIME_TICK
表示系统时间更改的公共事件的动作。
当以整分钟为单位的系统时间更改时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.TIME_TICK"
#### COMMON_EVENT_TIMEZONE_CHANGED
表示系统时区更改的公共事件的动作。
当系统时区更改时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.TIMEZONE_CHANGED"
#### COMMON_EVENT_USER_INFO_UPDATED
表示用户信息已更新。
分布式账号信息变更、系统账号头像信息变更、系统账号名称变更将会触发事件通知服务发布该系统公共事件，事件携带系统账号ID。
与这个公共事件相关的接口：setOsAccountName、setOsAccountProfilePhoto, 这些为系统API，setOsAccountDistributedInfo为公共API，具体参看 [系统账号接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-osaccount.md) 、 [分布式账号接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-distributed-account.md) 。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.USER_INFO_UPDATED"
#### COMMON_EVENT_USER_UNLOCKED
表示设备重启后解锁时，当前用户的凭据加密存储已解锁的公共事件的动作。
切换到带有锁屏密码的用户，并且首次解锁会发出触发事件通知服务发布该系统公共事件，事件携带标识该用户的系统账号ID。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.USER_UNLOCKED"
#### COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN
表示分布式账号登录成功的动作。
分布式账号登录成功时会触发事件通知服务发布该系统公共事件，事件携带系统账号ID。
与这个公共事件相关的接口：setOsAccountDistributedInfo、updateOsAccountDistributedInfo(已废弃)，这些为公共API，setOsAccountDistributedInfoByLocalId为系统API，具体参看 [分布式账号接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-distributed-account.md) 。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**取值：** "common.event.DISTRIBUTED_ACCOUNT_LOGIN"
#### COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT
表示分布式账号登出成功的动作。
分布式账号登出时会触发事件通知服务发布该系统公共事件，事件携带系统账号ID。
与这个公共事件相关的接口：setOsAccountDistributedInfo、updateOsAccountDistributedInfo(已废弃)，这些为公共API，setOsAccountDistributedInfoByLocalId为系统API，具体参看 [分布式账号接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-distributed-account.md) 。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**取值：** "common.event.DISTRIBUTED_ACCOUNT_LOGOUT"
#### COMMON_EVENT_DISTRIBUTED_ACCOUNT_TOKEN_INVALID
表示分布式账号token令牌无效的动作。
分布式账号的token令牌无效时会触发事件通知服务发布该系统公共事件，事件携带系统账号ID。
与这个公共事件相关的接口：setOsAccountDistributedInfo、updateOsAccountDistributedInfo(已废弃)，这些为公共API，setOsAccountDistributedInfoByLocalId为系统API，具体参看 [分布式账号接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-distributed-account.md) 。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**取值：** "common.event.DISTRIBUTED_ACCOUNT_TOKEN_INVALID"
#### COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOFF
表示分布式账号注销的动作。
分布式账号注销成功会时触发事件通知服务发布该系统公共事件，事件携带系统账号ID。
与这个公共事件相关的接口：setOsAccountDistributedInfo、updateOsAccountDistributedInfo(已废弃)，这些为公共API，setOsAccountDistributedInfoByLocalId为系统API，具体参看 [分布式账号接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/账号管理/js-apis-distributed-account.md) 。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 12开始，该接口支持在元服务中使用。
**取值：** "common.event.DISTRIBUTED_ACCOUNT_LOGOFF"
#### COMMON_EVENT_SCREEN_LOCKED
表示屏幕锁定的公共事件。
当锁屏锁定时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**取值：** usual.event.SCREEN_LOCKED
#### COMMON_EVENT_SCREEN_UNLOCKED
表示屏幕解锁的公共事件。
当锁屏解锁时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**取值：** usual.event.SCREEN_UNLOCKED
#### COMMON_EVENT_USER_PRESENT(deprecated)
用户解锁设备的公共事件的动作。
说明：
从API Version 10开始废弃，替代接口为 [COMMON_EVENT_SCREEN_UNLOCKED](#common_event_screen_unlocked) 。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.USER_PRESENT
#### COMMON_EVENT_BATTERY_CHANGED
表示电池充电状态、电平和其他信息发生变化的公共事件的动作。
当电池电量、电池温度、电池健康状态、设备连接的充电器类型、充电器最大电流、充电器最大电压、电池充电状态、充电次数、电池的总容量、电池剩余容量、电池的技术型号、电池的充电类型变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.BATTERY_CHANGED"
#### COMMON_EVENT_BATTERY_LOW
表示电池电量低的普通事件的动作。
当电池电量低于设备设置的低电量百分比值时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.BATTERY_LOW"
#### COMMON_EVENT_BATTERY_OKAY
表示电池退出低电量状态的公共事件的动作。
当电池电量从低电量等级变化到电池电量高于低电量等级时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.BATTERY_OKAY"
#### COMMON_EVENT_POWER_CONNECTED
设备连接到外部电源的公共事件的动作。
当设备连接到外部可识别的充电器类型充电时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.POWER_CONNECTED"
#### COMMON_EVENT_POWER_DISCONNECTED
设备与外部电源断开的公共事件的动作。
当设备与外部电源断开时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.POWER_DISCONNECTED"
#### COMMON_EVENT_DISCHARGING
表示系统停止为电池充电的公共事件的动作。
当系统停止为电池充电时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.DISCHARGING"
#### COMMON_EVENT_CHARGING
表示系统开始为电池充电的公共事件的动作。
当系统开始为电池充电时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.CHARGING"
#### COMMON_EVENT_CHARGE_IDLE_MODE_CHANGED10+
表示设备进入充电空闲模式的公共事件的动作。
当设备处于空闲、正在充电并且温升可接受的一种状态时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.CHARGE_IDLE_MODE_CHANGED"
#### COMMON_EVENT_SHUTDOWN
表示设备正在关闭并将继续最终关闭的公共事件的操作。
当设备正在关闭并将继续最终关闭时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.SHUTDOWN"
#### COMMON_EVENT_SCREEN_OFF
表示由电源服务发起的设备灭屏完成的普通事件的动作。
当由电源服务发起的设备灭屏完成时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.SCREEN_OFF"
#### COMMON_EVENT_SCREEN_ON
表示由电源服务发起的设备亮屏完成的普通事件的动作。
当由电源服务发起的设备亮屏完成时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.SCREEN_ON"
#### COMMON_EVENT_POWER_SAVE_MODE_CHANGED
表示系统节能模式更改的公共事件的动作。
当系统节能模式更改时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.POWER_SAVE_MODE_CHANGED"
#### COMMON_EVENT_THERMAL_LEVEL_CHANGED
表示设备热状态的公共事件的动作。
当设备热等级变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.THERMAL_LEVEL_CHANGED"
#### COMMON_EVENT_ENTER_FORCE_SLEEP12+
表示设备即将进入强制睡眠模式的公共事件的动作。
当设备即将进入强制睡眠模式时，将会触发事件通知服务发布该系统公共事件。所有订阅者必须在1秒钟内处理该事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.ENTER_FORCE_SLEEP"
#### COMMON_EVENT_EXIT_FORCE_SLEEP12+
表示设备退出强制睡眠模式的公共事件的动作。
当设备退出强制睡眠模式时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.EXIT_FORCE_SLEEP"
#### COMMON_EVENT_ENTER_HIBERNATE15+
表示设备即将进入休眠模式的公共事件的动作。
当设备即将进入休眠模式时，将会触发事件通知服务发布该系统公共事件。所有订阅者必须在1秒钟内处理该事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.ENTER_HIBERNATE"
#### COMMON_EVENT_EXIT_HIBERNATE15+
表示设备退出休眠模式的公共事件的动作。
当设备退出休眠模式时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.EXIT_HIBERNATE"
#### Connectivity Kit
#### COMMON_EVENT_BLUETOOTH_HANDSFREE_AG_CONNECT_STATE_CHANGE20+
表示蓝牙HFP AG连接状态变化的公共事件的操作。
当蓝牙HFP AG连接状态变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.handsfree.ag.CONNECT_STATE_CHANGE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CONNECT_STATE_CHANGE20+
表示蓝牙A2DP Source连接状态变化的公共事件的操作。
当蓝牙A2DP Source连接状态变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.CONNECT_STATE_CHANGE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_AVRCP_CONNECT_STATE_CHANGE20+
表示蓝牙AVRCP连接状态变化的公共事件的操作。
当蓝牙AVRCP连接状态变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.AVRCP_CONNECT_STATE_CHANGE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CODEC_VALUE_CHANGE20+
表示蓝牙媒体编解码器变化的公共事件的操作。
当蓝牙媒体编解码器变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.CODEC_VALUE_CHANGE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_ACL_STATE_CHANGE20+
表示蓝牙远程设备ACL连接状态变化的公共事件的操作。
当蓝牙远程设备ACL连接状态变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.ACL_STATE_CHANGE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_PAIR_STATE_CHANGE20+
表示蓝牙配对状态变化的公共事件的操作。
当蓝牙配对状态变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.PAIR_STATE_CHANGE"
#### COMMON_EVENT_NFC_ACTION_ADAPTER_STATE_CHANGED
指示设备NFC状态已更改的公共事件的操作。
指示设备NFC状态更改时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.nfc.action.ADAPTER_STATE_CHANGED"
#### COMMON_EVENT_NFC_ACTION_RF_FIELD_ON_DETECTED
检测到NFC场强进入的公共事件。
当检测到NFC场强进入时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.nfc.action.RF_FIELD_ON_DETECTED"
#### COMMON_EVENT_NFC_ACTION_RF_FIELD_OFF_DETECTED
检测到NFC场强离开的公共事件。
当检测到NFC场强离开时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.nfc.action.RF_FIELD_OFF_DETECTED"
#### COMMON_EVENT_WIFI_POWER_STATE
Wi-Fi状态变化。
当Wi-Fi状态发生变化时（如启用、禁用Wi-Fi），将会触发事件通知服务发布该系统公共事件。
状态值：0：WLAN正在关闭，1：WLAN已关闭，2：WLAN正在打开，3：WLAN已启动。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.wifi.POWER_STATE"
#### COMMON_EVENT_WIFI_SCAN_FINISHED
表示Wi-Fi接入点已被扫描并证明可用的动作。
当Wi-Fi接入点已被扫描并证明可用，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.LOCATION
**取值：** "usual.event.wifi.SCAN_FINISHED"
#### COMMON_EVENT_WIFI_SCAN_STATE
表示Wi-Fi扫描接入点状态改变。
当Wi-Fi扫描接入点状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.LOCATION
**取值：** "usual.event.wifi.SCAN_STATE"
#### COMMON_EVENT_WIFI_RSSI_VALUE
表示Wi-Fi信号强度（RSSI）改变。
当Wi-Fi信号强度（RSSI）发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.RSSI_VALUE"
#### COMMON_EVENT_WIFI_CONN_STATE
Wi-Fi连接状态发生改变。
当Wi-Fi连接状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.wifi.CONN_STATE"
#### COMMON_EVENT_WIFI_HOTSPOT_STATE
表示Wi-Fi热点状态变化。
当Wi-Fi热点状态发生变化，将会触发事件通知服务发布该系统公共事件。
状态值：2：AP正在打开，3：AP已启动，4：AP正在关闭，5：AP已关闭。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.wifi.HOTSPOT_STATE"
#### COMMON_EVENT_WIFI_AP_STA_JOIN
表示客户端加入当前设备Wi-Fi热点。
当客户端加入当前设备Wi-Fi热点，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.WIFI_HS_STA_JOIN"
#### COMMON_EVENT_WIFI_AP_STA_LEAVE
表示客户端已断开与当前设备Wi-Fi热点的连接。
当客户端已断开与当前设备Wi-Fi热点的连接，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.WIFI_HS_STA_LEAVE"
#### COMMON_EVENT_WIFI_MPLINK_STATE_CHANGE
表示MPLink（增强Wi-Fi功能）状态已更改。
当MPLink（增强Wi-Fi功能）状态发生变化，将会触发事件通知服务发布该系统公共事件（暂不支持）。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者需要的权限：** 无
**取值：** "usual.event.wifi.mplink.STATE_CHANGE"
#### COMMON_EVENT_WIFI_P2P_CONN_STATE
表示Wi-Fi P2P连接状态改变。
当Wi-Fi P2P连接状态发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO和ohos.permission.LOCATION
**取值：** "usual.event.wifi.p2p.CONN_STATE_CHANGE"
#### COMMON_EVENT_WIFI_P2P_STATE_CHANGED
表示Wi-Fi P2P状态变化。
当Wi-Fi P2P状态发生变化，将会触发事件通知服务发布该系统公共事件。
状态值：2：P2P正在打开，3：P2P已启动，4：P2P正在关闭，5：P2P已关闭。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.p2p.STATE_CHANGE"
#### COMMON_EVENT_WIFI_P2P_PEERS_STATE_CHANGED
表示Wi-Fi P2P对等体状态变化。
当Wi-Fi P2P对等体状态变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.p2p.DEVICES_CHANGE"
#### COMMON_EVENT_WIFI_P2P_PEERS_DISCOVERY_STATE_CHANGED
表示Wi-Fi P2P发现状态变化。
当Wi-Fi P2P发现状态变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.p2p.PEER_DISCOVERY_STATE_CHANGE"
#### COMMON_EVENT_WIFI_P2P_CURRENT_DEVICE_STATE_CHANGED
表示Wi-Fi P2P当前设备状态变化。
当Wi-Fi P2P当前设备状态变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.p2p.CURRENT_DEVICE_CHANGE"
#### COMMON_EVENT_WIFI_P2P_GROUP_STATE_CHANGED
表示Wi-Fi P2P群组信息已更改。
当Wi-Fi P2P群组信息发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_WIFI_INFO
**取值：** "usual.event.wifi.p2p.GROUP_STATE_CHANGED"
#### MDM Kit
#### COMMON_EVENT_MANAGED_BROWSER_POLICY_CHANGED
表示浏览器托管策略已更改。
当浏览器托管策略发生变化，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.MANAGED_BROWSER_POLICY_CHANGED"
#### Localization Kit
#### COMMON_EVENT_LOCALE_CHANGED
设置系统语言的公共事件的动作。
当设置系统语言时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.LOCALE_CHANGED
#### Network Kit
#### COMMON_EVENT_CONNECTIVITY_CHANGE10+
指示网络连接状态变化。
各类网络（以太网、Wi-Fi、蜂窝等）在发生连接状态状态变化时（断开、断开中、连接中、已连接等），将会触发事件通知服务发布该系统公共事件。
具体枚举值及其对应的连接状态如下表所示：
| 枚举值 | 连接状态 |
| --- | --- |
| 2 | 连接中 |
| 3 | 已连接 |
| 4 | 正在断开 |
| 5 | 已断开 |
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**元服务API：** 从API version 11开始，该接口支持在元服务中使用。
**取值：** usual.event.CONNECTIVITY_CHANGE
#### COMMON_EVENT_AIRPLANE_MODE_CHANGED10+
指示飞行模式状态变化。
在开启或者关闭系统飞行模式状态后，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.AIRPLANE_MODE
#### COMMON_EVENT_HTTP_PROXY_CHANGE10+
指示网络Http代理配置信息更新。
在系统全局代理或者各类网络（以太网、Wi-Fi、蜂窝等）Http代理配置信息发生变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.HTTP_PROXY_CHANGE
#### Telephony Kit
电话服务子系统面向应用发布如下系统公共事件。
#### COMMON_EVENT_SIM_STATE_CHANGED10+
提示SIM卡状态更新。
在设备上面的SIM卡状态发生变化时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.SIM_STATE_CHANGED
#### COMMON_EVENT_CALL_STATE_CHANGED10+
提示呼叫状态更新。
在设备呼叫状态更新时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_TELEPHONY_STATE（该权限仅系统应用可申请）
**取值：** usual.event.CALL_STATE_CHANGED
#### COMMON_EVENT_NETWORK_STATE_CHANGED10+
提示网络状态更新。
在设备网络状态更新时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.NETWORK_STATE_CHANGED
#### COMMON_EVENT_SIGNAL_INFO_CHANGED10+
提示信号信息更新。
在设备信号信息更新时，将会触发事件通知服务发布该系统公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.SIGNAL_INFO_CHANGED
#### AppGallery Kit
AppGallery Kit面向应用发布如下系统公共事件。
#### COMMON_EVENT_PRIVACY_STATE_CHANGED11+
表示隐私签署结果的公共事件。
隐私弹框场景下，用户点击同意，会发送此事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PRIVACY_STATE_CHANGED"
#### 预留公共事件
以下事件为预留公共事件，暂未支持。
#### COMMON_EVENT_LOCKED_BOOT_COMPLETED
（预留事件，暂未支持）提示用户已完成引导，系统已加载，但屏幕仍锁定。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.LOCKED_BOOT_COMPLETED"
#### COMMON_EVENT_PACKAGE_FIRST_LAUNCH
（预留事件，暂未支持）应用程序在安装后首次启动。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_FIRST_LAUNCH"
#### COMMON_EVENT_PACKAGE_NEEDS_VERIFICATION
（预留事件，暂未支持）当一个包需要被验证时，由系统包验证者发送。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_NEEDS_VERIFICATION"
#### COMMON_EVENT_PACKAGE_VERIFIED
（预留事件，暂未支持）当一个包被验证时，由系统包验证者发送。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_VERIFIED"
#### COMMON_EVENT_PACKAGE_REPLACED
（预留事件，暂未支持）表示设备上安装了新版本的应用程序包并替换了旧版本的动作。数据包含包的名称。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGE_REPLACED"
#### COMMON_EVENT_MY_PACKAGE_REPLACED
（预留事件，暂未支持）表示设备上安装了新版本的应用程序包并替换了旧版本的应用程序包的动作，不包含额外的数据，只发送给被替换的应用程序。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.MY_PACKAGE_REPLACED"
#### COMMON_EVENT_PACKAGES_UNSUSPENDED
（预留事件，暂未支持）表示包已经被解除挂起。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.PACKAGES_UNSUSPENDED"
#### COMMON_EVENT_CLOSE_SYSTEM_DIALOGS
（预留事件，暂未支持）表示用户关闭临时系统对话框的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.CLOSE_SYSTEM_DIALOGS"
#### COMMON_EVENT_UID_REMOVED
（预留事件，暂未支持）表示用户ID已从系统中删除的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.UID_REMOVED"
#### COMMON_EVENT_EXTERNAL_APPLICATIONS_AVAILABLE
（预留事件，暂未支持）表示安装在外部存储上的应用程序对系统可用的公共事件的操作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.EXTERNAL_APPLICATIONS_AVAILABLE"
#### COMMON_EVENT_EXTERNAL_APPLICATIONS_UNAVAILABLE
（预留事件，暂未支持）表示安装在外部存储上的应用程序对系统不可用的公共事件的操作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.EXTERNAL_APPLICATIONS_UNAVAILABLE"
#### COMMON_EVENT_CONFIGURATION_CHANGED
（预留事件，暂未支持）表示设备状态（例如，方向和区域设置）已更改的公共事件的操作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.CONFIGURATION_CHANGED"
#### COMMON_EVENT_DRIVE_MODE
（预留事件，暂未支持）表示系统处于驾驶模式的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.DRIVE_MODE"
#### COMMON_EVENT_HOME_MODE
（预留事件，暂未支持）表示系统处于HOME模式的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.HOME_MODE"
#### COMMON_EVENT_OFFICE_MODE
（预留事件，暂未支持）表示系统处于办公模式的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.OFFICE_MODE"
#### COMMON_EVENT_USER_STARTED
（预留事件，暂未支持）表示用户已启动的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.USER_STARTED"
#### COMMON_EVENT_USER_BACKGROUND
（预留事件，暂未支持）表示用户已被带到后台的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.USER_BACKGROUND"
#### COMMON_EVENT_USER_STARTING
（预留事件，暂未支持）表示要启动用户的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.INTERACT_ACROSS_LOCAL_ACCOUNTS（该权限仅系统应用可申请）
**取值：** "usual.event.USER_STARTING"
#### COMMON_EVENT_USER_STOPPING
（预留事件，暂未支持）表示要停止用户的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.INTERACT_ACROSS_LOCAL_ACCOUNTS（该权限仅系统应用可申请）
**取值：** "usual.event.USER_STOPPING"
#### COMMON_EVENT_USER_STOPPED
（预留事件，暂未支持）表示用户已停止的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.USER_STOPPED"
#### COMMON_EVENT_DISK_REMOVED
（预留事件，暂未支持）外部存储设备状态变更为移除时发送此公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.STORAGE_MANAGER（该权限仅系统应用可申请）
**取值：** "usual.event.data.DISK_REMOVED"
#### COMMON_EVENT_DISK_UNMOUNTED
（预留事件，暂未支持）外部存储设备状态变更为卸载时发送此公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.STORAGE_MANAGER（该权限仅系统应用可申请）
**取值：** "usual.event.data.DISK_UNMOUNTED"
#### COMMON_EVENT_DISK_MOUNTED
（预留事件，暂未支持）外部存储设备状态变更为挂载时发送此公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.STORAGE_MANAGER（该权限仅系统应用可申请）
**取值：** "usual.event.data.DISK_MOUNTED"
#### COMMON_EVENT_DISK_BAD_REMOVAL
（预留事件，暂未支持）外部存储设备状态变更为挂载状态下移除时发送此公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.STORAGE_MANAGER（该权限仅系统应用可申请）
**取值：** "usual.event.data.DISK_BAD_REMOVAL"
#### COMMON_EVENT_DISK_UNMOUNTABLE
（预留事件，暂未支持）外部存储设备状态变更为插卡情况下无法挂载时发送此公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.STORAGE_MANAGER（该权限仅系统应用可申请）
**取值：** "usual.event.data.DISK_UNMOUNTABLE"
#### COMMON_EVENT_DISK_EJECT
（预留事件，暂未支持）用户已表示希望删除外部存储介质时发送此公共事件。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.STORAGE_MANAGER（该权限仅系统应用可申请）
**取值：** "usual.event.data.DISK_EJECT"
#### COMMON_EVENT_DATE_CHANGED
（预留事件，暂未支持）表示系统日期已更改的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** usual.event.DATE_CHANGED
#### COMMON_EVENT_USB_ACCESSORY_ATTACHED
表示已连接USB配件的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.hardware.usb.action.USB_ACCESSORY_ATTACHED"
#### COMMON_EVENT_USB_ACCESSORY_DETACHED
表示USB配件被卸载的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.hardware.usb.action.USB_ACCESSORY_DETACHED"
#### COMMON_EVENT_BLUETOOTH_HANDSFREE_AG_CONNECT_STATE_UPDATE(deprecated)
（预留事件，暂未支持）蓝牙免提通信连接状态公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fb/v3/DSytSM4VSZSrNJU22uqpCw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=7797D0286A91CC558F4A4CF3E68E021B7801225C28D929C47D2D0A01C3DC72DD)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_HANDSFREE_AG_CONNECT_STATE_CHANGE](#common_event_bluetooth_handsfree_ag_connect_state_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.handsfree.ag.CONNECT_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HANDSFREE_AG_CURRENT_DEVICE_UPDATE(deprecated)
（预留事件，暂未支持）表示连接到蓝牙免提的设备处于活动状态的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4c/v3/eW7GphcUTiGuK9IW_07WAQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=2157230E2847E47238EAAB7D7DF376818FF9BCA7AFF36442EA7F77B0DC7C5F27)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.handsfree.ag.CURRENT_DEVICE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HANDSFREE_AG_AUDIO_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙A2DP连接状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/66/v3/aIXAHJ0jQ5ubKBx1qOjP-A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=910AB82E44DE82E80B94E3E118C10EB6B447B4BD782BED45FA0F6CFD019CC74B)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.handsfree.ag.AUDIO_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CONNECT_STATE_UPDATE(deprecated)
（预留事件，暂未支持）蓝牙A2DP连接状态公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/7f/v3/u21djgFWTvq9rMGxEtIRdw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=B726267AC4F51E937E89259A64D7A8ADD392CECCE330AC6B44303E7C2816F86B)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CONNECT_STATE_CHANGE](#common_event_bluetooth_a2dpsource_connect_state_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.CONNECT_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CURRENT_DEVICE_UPDATE(deprecated)
（预留事件，暂未支持）表示使用蓝牙A2DP连接的设备处于活动状态的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f/v3/MaSdFB19SPuxYNIGPZc5Pg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=39DC0F6D467DFE9035D34D8C01B20A0EE2DFB649C8054E7CEB2C54332EF0C02B)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.CURRENT_DEVICE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_AVRCP_CONNECT_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙A2DP的AVRCP连接状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/69/v3/D6pvKc_2RW6LXrpwGbLzVw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=B7A26CD2F8788F91533584D6C0DF46EC8ACAB4EF6EB15E9C52E37BBAC927815B)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_A2DPSOURCE_AVRCP_CONNECT_STATE_CHANGE](#common_event_bluetooth_a2dpsource_avrcp_connect_state_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.AVRCP_CONNECT_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_PLAYING_STATE_UPDATE(deprecated)
（预留事件，暂未支持）蓝牙A2DP播放状态改变的普通事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a3/v3/xgw_SlE_RVihdW7IMXy35A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=F227023EE01EEBB60F70A624F8E7B0F20DC07E6831F6E19B238671CE38A1114C)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.PLAYING_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CODEC_VALUE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙A2DP音频编解码状态更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d1/v3/fhe3CEglSPm9yG5RZ7W5vA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=874CF5D7C56F3847FB955F3C525775977C2A776AFF4417035F202744681952A6)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_A2DPSOURCE_CODEC_VALUE_CHANGE](#common_event_bluetooth_a2dpsource_codec_value_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsource.CODEC_VALUE_UPDATE"
#### COMMON_EVENT_USER_FOREGROUND
（预留事件，暂未支持）表示用户已被带到前台的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.USER_FOREGROUND“
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_DISCOVERED(deprecated)
（预留事件，暂未支持）表示发现远程蓝牙设备的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/09/v3/4aaVJ-vfTqW8ty02nqQuYA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=9D3C9B70FBDE42A13D3433674F0E9714126132FD5C300EED9FD3AFF7E46DEA87)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.LOCATION和ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.DISCOVERED"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_CLASS_VALUE_UPDATE(deprecated)
（预留事件，暂未支持）表示远程蓝牙设备的蓝牙类别已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/wl-pJ0s7RMe3xe-o_uwwCQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=10C44D922D46FFD454F614E6D96C3B2B79A535BA5D1F2E620FA09BED9547E7D6)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.CLASS_VALUE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_ACL_CONNECTED(deprecated)
（预留事件，暂未支持）表示已与远程蓝牙设备建立低级别（ACL）连接的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/67/v3/KCMZVpNcSaSpWTeENTo14w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=4918DDFCA5596A8B0B65F4809389525E173AD7EC72A374CB2AFDE69A559A2F77)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_ACL_STATE_CHANGE](#common_event_bluetooth_remotedevice_acl_state_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.remotedevice.ACL_CONNECTED"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_ACL_DISCONNECTED(deprecated)
（预留事件，暂未支持）表示低电平（ACL）连接已从远程蓝牙设备断开的普通事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1a/v3/33KZg8MJTmybzy1UCAUSEA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=1F4EBAF81A632D94AB019F59611103A03F81705993801F99889492CD9E725061)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_ACL_STATE_CHANGE](#common_event_bluetooth_remotedevice_acl_state_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.ACL_DISCONNECTED"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_NAME_UPDATE(deprecated)
（预留事件，暂未支持）表示远程蓝牙设备的友好名称首次被检索或自上次检索以来被更改的公共事件的操作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/JfjgNXU9RS2z0LoQVPoyUA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=21B02B9690113B5E344FC063A851BA840A3EDB98E7AF46ADBE13E66AB4F8B1C2)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.NAME_UPDATE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_PAIR_STATE(deprecated)
（预留事件，暂未支持）远程蓝牙设备连接状态更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/87/v3/iXz0uTEuRj6Qo_uoUFpKmw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=807960B4EE77E0C06715114A257BD5CC573D97FB3551A52405F09A7AB0E55E88)
从API version 9 开始支持，从API version 20 开始废弃，建议使用 [COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_PAIR_STATE_CHANGE](#common_event_bluetooth_remotedevice_pair_state_change20) 替代。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.PAIR_STATE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_BATTERY_VALUE_UPDATE(deprecated)
（预留事件，暂未支持）表示远程蓝牙设备的电池电量首次被检索或自上次检索以来被更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/48/v3/B7jUff5iQeOCH9XxIfgBNQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=202F08FBF5D081B847F9D087EDF2206ED38D0F141BBDAE1A227E740046262C70)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.BATTERY_VALUE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_SDP_RESULT(deprecated)
（预留事件，暂未支持）远程蓝牙设备SDP状态公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ff/v3/Yd9ZtS7OS_muZnaPYcjtpA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=5C6F1D68EBCD0F3861C96FC9B7272304B01915D91E09BB21FF2CA3297184CCDC)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.remotedevice.SDP_RESULT"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_UUID_VALUE(deprecated)
远程蓝牙设备UUID连接状态公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0c/v3/KtSp4tgBTRuPkcaMsDxYEA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=F5F3954946D67CD7A497284D0E6EE75C73D4D994032A50B43C74F2E4D453A8A5)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.UUID_VALUE"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_PAIRING_REQ(deprecated)
（预留事件，暂未支持）表示远程蓝牙设备配对请求的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c5/v3/Lc_t2G_OSHeLXwZ05BZDEQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=E367C55B5F39C4330D81908971D90A29A7D5D641421AAF8D19808306EB8676CB)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.DISCOVER_BLUETOOTH
**取值：** "usual.event.bluetooth.remotedevice.PAIRING_REQ"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_PAIRING_CANCEL(deprecated)
（预留事件，暂未支持）取消蓝牙配对的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9e/v3/-jt-bgNjT8yNuf8lNuDydQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=5E61534D3A0847AD6F5905A6DF7211918F6D91E4340B7174CC81B08B23038E4A)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.remotedevice.PAIRING_CANCEL"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_CONNECT_REQ(deprecated)
（预留事件，暂未支持）表示远程蓝牙设备连接请求的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/32/v3/9H4GoKGoSjCLOQP3UhXlaA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=3671F540BB1A966890B32C576CE2ECB8124174ADA00CC5B61F431A85833477CC)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.remotedevice.CONNECT_REQ"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_CONNECT_REPLY(deprecated)
（预留事件，暂未支持）表示远程蓝牙设备连接请求响应的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b3/v3/9-3ouM1_TqmsPQ8WOCW1Kw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=1D0CC68A08C0CD6840200C7797CFC795B76F3AE383B440BB50FA8C2EA0C69E1B)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.remotedevice.CONNECT_REPLY"
#### COMMON_EVENT_BLUETOOTH_REMOTEDEVICE_CONNECT_CANCEL(deprecated)
（预留事件，暂未支持）表示取消与远程蓝牙设备的连接的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/59/v3/8hvleRfbTi2AHfhTcrq4GQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=42CFF024CF51D811037172355C0D0EFCABF8DD8B2391ECFBF35DDDBBA2110AD4)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.remotedevice.CONNECT_CANCEL"
#### COMMON_EVENT_BLUETOOTH_HANDSFREEUNIT_CONNECT_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙免提连接状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0/v3/VPYawOcdTJyOU2WYK842bQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=B9206F420949F62F0BCF5534932F0CD62A93396B244AD7FF9643DBD69792B2D4)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.handsfreeunit.CONNECT_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HANDSFREEUNIT_AUDIO_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙免提音频状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/7c/v3/DASJUyamTpKwIZyQVSZFsQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=3E748A9F06728B1B85DBCA26206A372E7F5758191ECD5426CE0D8B9F54965A70)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.handsfreeunit.AUDIO_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HANDSFREEUNIT_AG_COMMON_EVENT(deprecated)
（预留事件，暂未支持）表示蓝牙免提音频网关状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/XjqTGGzuQmiwwmxPa_FLEw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=67984F2396CAEB7673A2CF9979AA500DCB6ACDC19F1A502BE612B4C6F8147468)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.handsfreeunit.AG_COMMON_EVENT"
#### COMMON_EVENT_BLUETOOTH_HANDSFREEUNIT_AG_CALL_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙免提呼叫状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3f/v3/sXcYlAltRKC8l7lgCiFHVA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=E85D01731DB19D7DDA29BC1F1DF0EC9A3418A0288856B88FCEEAF15682D4C2C9)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.handsfreeunit.AG_CALL_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HOST_STATE_UPDATE(deprecated)
表示蓝牙适配器状态已更改的公共事件的操作，例如蓝牙已打开或关闭。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b8/v3/yKjyLBt0Q6W5x0K1P23sUw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=0388A9F6A2872491DCDF02307031F649F459C225B6F8183DAFB4F12A0D2DA0AD)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.host.STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HOST_REQ_DISCOVERABLE(deprecated)
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e8/v3/YmcPWND2SjST8nnXV6BLqQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=F74928CE3DBD7DE9A10686C9FC82EC56460C266A2CCBAEC8819E90A330D277B6)
从API version 9 开始支持，从API version 20 开始废弃。
（预留事件，暂未支持）表示用户允许扫描蓝牙请求的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.bluetooth.host.REQ_DISCOVERABLE"
#### COMMON_EVENT_BLUETOOTH_HOST_REQ_ENABLE(deprecated)
（预留事件，暂未支持）表示用户打开蓝牙请求的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ef/v3/2VCuUzEXSjCA-oj9IxHCvg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=6EDF37B172ADEA490B8CF9AD798FA39CB7A5364A608F5A1BC5C5A2095494E6E6)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.host.REQ_ENABLE"
#### COMMON_EVENT_BLUETOOTH_HOST_REQ_DISABLE(deprecated)
（预留事件，暂未支持）表示用户关闭蓝牙请求的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c2/v3/u_KlqYapQxSEDXT6vujDYQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=A5C30C3319AB17F5FA0382CB94F3EC95256377D83310CA23ACC68B0D643167BA)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.host.REQ_DISABLE"
#### COMMON_EVENT_BLUETOOTH_HOST_SCAN_MODE_UPDATE(deprecated)
（预留事件，暂未支持）设备蓝牙扫描模式更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d8/v3/SV_xsePGQRCKmBOqfcUUKA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=89AB29CE8F3470FAD95AA7FDF347C75D99C87F893E7FE276A815005DED3D561B)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.host.SCAN_MODE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_HOST_DISCOVERY_STARTED(deprecated)
设备上已启动蓝牙扫描的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/83/v3/hhY2m__DRIqefoQhgN-WjA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=E08AA92151F339FD3D8E1BEA3A9EE1D74B9F3A6965760FD68941B158FFE9302F)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.host.DISCOVERY_STARTED"
#### COMMON_EVENT_BLUETOOTH_HOST_DISCOVERY_FINISHED(deprecated)
设备上蓝牙扫描完成的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/dd/v3/Jz7YKftnRZiVD443mVIuZw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=90680282B7D6E87030A900E04E5156456E1F7D733E24C65BF94EE3EB8A100F7D)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.host.DISCOVERY_FINISHED"
#### COMMON_EVENT_BLUETOOTH_HOST_NAME_UPDATE(deprecated)
指示设备蓝牙适配器名称已更改的公共事件的操作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/3f/v3/qeNDtVXHQIqxDOZi0ja6fA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=4E7E689FC53CC3FA602A23199EFBB2B30E5655F7B7C9D9075E72DD43E1D9399F)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.ACCESS_BLUETOOTH
**取值：** "usual.event.bluetooth.host.NAME_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSINK_CONNECT_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙A2DP连接状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/69/v3/xah7NErvTo6sFercbZZypg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=32B4395EEE1F4F4EB41FEB27B0976B8E3E97A09B5ADA7F5B2C630EB79F2B9D1E)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsink.CONNECT_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSINK_PLAYING_STATE_UPDATE(deprecated)
（预留事件，暂未支持）蓝牙A2DP播放状态改变的普通事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/63/v3/hynbHk7QTx6UhRDEKUg-tw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=1088442809131F628FE56D07E7A61828D923154837027A41DA2FC782F397D982)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsink.PLAYING_STATE_UPDATE"
#### COMMON_EVENT_BLUETOOTH_A2DPSINK_AUDIO_STATE_UPDATE(deprecated)
（预留事件，暂未支持）表示蓝牙A2DP宿的音频状态已更改的公共事件的动作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a3/v3/tlKAJ-3bQaWxIIjU8-GR0w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093211Z&HW-CC-Expire=86400&HW-CC-Sign=64B728DC555106EF889A3BCF8CA33992C9F55B3C047B9B040691994027072B62)
从API version 9 开始支持，从API version 20 开始废弃。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.USE_BLUETOOTH
**取值：** "usual.event.bluetooth.a2dpsink.AUDIO_STATE_UPDATE"
#### COMMON_EVENT_ABILITY_ADDED
（预留事件，暂未支持）表示已添加能力的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.LISTEN_BUNDLE_CHANGE
**取值：** "usual.event.ABILITY_ADDED"
#### COMMON_EVENT_ABILITY_REMOVED
（预留事件，暂未支持）表示已删除能力的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.LISTEN_BUNDLE_CHANGE
**取值：** "usual.event.ABILITY_REMOVED"
#### COMMON_EVENT_ABILITY_UPDATED
（预留事件，暂未支持）表示能力已更新的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.LISTEN_BUNDLE_CHANGE
**取值：** "usual.event.ABILITY_UPDATED"
#### COMMON_EVENT_LOCATION_MODE_STATE_CHANGED
（预留事件，暂未支持）表示系统定位模式已更改的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.location.MODE_STATE_CHANGED"
#### COMMON_EVENT_IVI_SLEEP
（预留事件，暂未支持）表示表示车辆的车载信息娱乐（IVI）系统正在休眠的常见事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_SLEEP"
#### COMMON_EVENT_IVI_PAUSE
（预留事件，暂未支持）表示IVI已休眠，并通知应用程序停止播放。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_PAUSE"
#### COMMON_EVENT_IVI_STANDBY
（预留事件，暂未支持）表示第三方应用暂停当前工作的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_STANDBY"
#### COMMON_EVENT_IVI_LASTMODE_SAVE
（预留事件，暂未支持）表示第三方应用保存其最后一个模式的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_LASTMODE_SAVE"
#### COMMON_EVENT_IVI_VOLTAGE_ABNORMAL
（预留事件，暂未支持）表示车辆电源系统电压异常的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_VOLTAGE_ABNORMAL"
#### COMMON_EVENT_IVI_HIGH_TEMPERATURE
（预留事件，暂未支持）表示IVI温度过高。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_HIGH_TEMPERATURE"
#### COMMON_EVENT_IVI_EXTREME_TEMPERATURE
（预留事件，暂未支持）表示IVI温度极高。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_EXTREME_TEMPERATURE"
#### COMMON_EVENT_IVI_TEMPERATURE_ABNORMAL
（预留事件，暂未支持）表示车载系统具有极端温度的常见事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_TEMPERATURE_ABNORMAL"
#### COMMON_EVENT_IVI_VOLTAGE_RECOVERY
（预留事件，暂未支持）表示车辆电源系统电压恢复正常的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_VOLTAGE_RECOVERY"
#### COMMON_EVENT_IVI_TEMPERATURE_RECOVERY
（预留事件，暂未支持）表示车载系统温度恢复正常的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_TEMPERATURE_RECOVERY"
#### COMMON_EVENT_IVI_ACTIVE
（预留事件，暂未支持）表示电池服务处于活动状态的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "common.event.IVI_ACTIVE"
#### COMMON_EVENT_VISIBLE_ACCOUNTS_UPDATED
（预留事件，暂未支持）表示账户可见更改的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.GET_APP_ACCOUNTS（该权限仅系统应用可申请）
**取值：** "usual.event.data.VISIBLE_ACCOUNTS_UPDATED"
#### COMMON_EVENT_ACCOUNT_DELETED
（预留事件，暂未支持）删除账户的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.INTERACT_ACROSS_LOCAL_ACCOUNTS（该权限仅系统应用可申请）
**取值：** "usual.event.data.ACCOUNT_DELETED"
#### COMMON_EVENT_FOUNDATION_READY
（预留事件，暂未支持）表示foundation已准备好的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** ohos.permission.RECEIVER_STARTUP_COMPLETED（该权限仅系统应用可申请）
**取值：** "usual.event.data.FOUNDATION_READY"
#### COMMON_EVENT_SPN_INFO_CHANGED
表示spn显示信息已更新的公共事件的动作。
**系统能力：** SystemCapability.Notification.CommonEvent
**订阅者所需权限：** 无
**取值：** "usual.event.SPN_INFO_CHANGED"