# Kit 路由索引

本文件包含本 Skill 收录的全部 Kit 的功能路径映射。路径相对于 `hmos-sdk-basic-skill/` 目录。

使用方式：当用户提到某个 Kit 名称或功能需求时，在下方表格中查找对应的 Kit 目录和功能子路径。

## 目录

- [应用框架领域](#应用框架领域)
- [应用服务领域](#应用服务领域)
- [网络通信领域](#网络通信领域)
- [AI 能力领域](#ai-能力领域)
- [位置与地图领域](#位置与地图领域)
- [安全认证领域](#安全认证领域)
- [系统调优领域](#系统调优领域)
- [设备硬件领域](#设备硬件领域)
- [UI 设计领域](#ui-设计领域)
- [媒体领域](#媒体领域)

## 应用框架领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Accessibility Kit（无障碍服务） | 无障碍服务简介、屏幕朗读体验提升（页面变化通知/动态内容播报/列表项组合/卡片自动居中/弹窗走焦/按钮标注/控件状态变化/多语种朗读/操作错误播报/焦点位置设置）、长辈关怀功能（关怀模式同步/应用声明接入/状态获取）、无障碍功能测试 | `Accessibility Kit(无障碍服务)/` |
| Localization Kit（本地化开发服务） | 应用国际化（字符处理/数字与度量衡/时区与夏令时/本地化名称/电话号码格式化/日历历法/语言与用户偏好）、应用本地化（多语言适配/多语言资源配置） | `Localization Kit(本地化开发服务)/` |
| Form Kit（卡片开发服务） | ArkTS卡片开发（生命周期/配置文件/UI动效/页面交互/页面刷新/待机屏保/背板透明/锁屏/应用内加桌）、互动卡片开发、JS卡片开发（FA/Stage模型） | `Form Kit(卡片开发服务)/` |

## 应用服务领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Account Kit（华为账号服务） | 登录、获取用户信息、未成年人模式、开发准备 | `Account Kit(华为账号服务)/` |
| AppGallery Kit（应用市场服务） | 应用市场推荐、应用市场更新、应用归因、图标管理 | `AppGallery Kit(应用市场服务)/` |
| IAP Kit（应用内支付服务） | 商品购买、售后、开发准备 | `IAP Kit(应用内支付服务)/` |
| Push Kit（推送服务） | 获取 Push Token、获取 AAID、推送场景化消息 | `Push Kit(推送服务)/` |
| Live View Kit（实况窗服务） | 开发准备、构建本地实况窗 | `Live View Kit(实况窗服务)/` |
| Share Kit（分享服务） | 系统分享、碰一碰分享、隔空传送、体验规范 | `Share Kit(分享服务)/` |
| Service Collaboration Kit（协同服务） | 跨设备互通ArkTS（跨设备拍照/文档扫描/图库选择/视频选择）、跨设备互通RichEditor控件（右键菜单跨设备调用）、跨设备互通NDK(C)（C API跨设备相机/扫描/图库） | `Service Collaboration Kit(协同服务)/` |

## 网络通信领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Network Kit（网络服务） | 连接网络、访问网络（HTTP/Socket） | `Network Kit(网络服务)/` |
| Network Boost Kit（网络加速服务） | 连接迁移、网络质量、多网并发 | `Network Boost Kit(网络加速服务)/` |
| Remote Communication Kit（远场通信服务） | 开发准备、HTTP 通信、文件上传下载 | `Remote Communication Kit(远场通信服务)/` |
| Connectivity Kit（短距通信服务） | WLAN、蓝牙（传统/低功耗） | `Connectivity Kit(短距通信服务)/` |
| Call Service Kit（通话服务） | 来电场景、去电场景 | `Call Service Kit(通话服务)/` |

## 位置与地图领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Location Kit（位置服务） | 获取设备位置、地理编码 | `Location Kit(位置服务)/` |
| Map Kit（地图服务） | 创建地图、地图交互、在地图上绘制、位置搜索 | `Map Kit(地图服务)/` |

## 安全认证领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Device Security Kit（设备安全服务） | 安全检测、应用设备状态检测、开发准备 | `Device Security Kit(设备安全服务)/` |
| Online Authentication Kit（在线认证服务） | FIDO 免密认证、IFAA 免密认证 | `Online Authentication Kit(在线认证服务)/` |

## 系统调优领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Performance Analysis Kit（性能分析服务） | 事件订阅（HiAppEvent/FaultLog）、系统调试信息（HiDebug） | `Performance Analysis Kit(性能分析服务)/` |

## 设备硬件领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Wear Engine Kit（穿戴服务） | 手机侧应用开发、穿戴侧应用开发 | `Wear Engine Kit(穿戴服务)/` |
| Health Service Kit（运动健康服务） | 开发接入、Wearable 应用开发 | `Health Service Kit(运动健康服务)/` |
| Multimodal Awareness Kit（多模态融合感知服务） | 获取用户动作 | `Multimodal Awareness Kit(多模态融合感知服务)/` |

## UI 设计领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| UI Design Kit（UI设计套件） | 图标处理（分层/单层） | `UI Design Kit(UI设计套件)/` |

## 媒体领域

| Kit | 功能模块 | 路径 |
|-----|---------|------|
| Scan Kit（统一扫码服务） | 默认界面扫码、自定义界面扫码、图像识码、码图生成 | `Scan Kit(统一扫码服务)/` |

---

## 功能路由速查

当用户描述功能需求但未提及 Kit 名称时，按以下映射定位：

| 用户需求关键词 | 推荐 Kit |
|-------------|---------|
| 无障碍、屏幕朗读、辅助功能、accessibility、长辈关怀、关怀模式 | Accessibility Kit |
| 国际化、本地化、多语言、i18n、时区、夏令时、日历历法、电话号码格式化 | Localization Kit |
| 登录、账号、手机号、头像昵称、实名认证 | Account Kit |
| 应用市场、应用更新、应用推荐、快捷方式 | AppGallery Kit |
| 支付、内购、订阅、商品购买、退款 | IAP Kit |
| 推送、Push Token、AAID、通知消息 | Push Kit |
| 实况窗、动态卡片 | Live View Kit |
| 分享、系统分享、碰一碰、隔空传送 | Share Kit |
| 跨设备互通、跨设备拍照、远程拍照、跨设备扫描、跨设备图库、跨设备选择图片/视频、Service Collaboration、协同服务、RichEditor跨设备 | Service Collaboration Kit |
| HTTP 请求、网络访问、Socket | Network Kit / Remote Communication Kit |
| 网络加速、多网并发、连接迁移、网络质量 | Network Boost Kit |
| 蓝牙、WLAN、Wi-Fi、短距通信 | Connectivity Kit |
| 通话、来电、去电 | Call Service Kit |
| 多模态感知、用户动作识别 | Multimodal Awareness Kit |
| 定位、获取位置、地理编码 | Location Kit |
| 地图、地图绘制、POI 搜索、地图交互 | Map Kit |
| 安全检测、系统完整性、风控、URL 检测 | Device Security Kit |
| 免密认证、FIDO、IFAA | Online Authentication Kit |
| 性能分析、事件订阅、HiAppEvent、崩溃事件、冻屏 | Performance Analysis Kit |
| 穿戴设备、手表、Wear Engine | Wear Engine Kit |
| 运动健康、健康数据、三环数据 | Health Service Kit |
| 图标处理、分层图标 | UI Design Kit |
| 扫码、二维码、条形码、码图生成 | Scan Kit |
| 卡片、服务卡片、桌面卡片、卡片开发、卡片刷新、卡片交互、锁屏卡片、互动卡片 | Form Kit |
