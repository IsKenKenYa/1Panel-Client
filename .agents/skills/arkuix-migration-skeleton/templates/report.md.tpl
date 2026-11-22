# ArkUI-X 迁移骨架报告

| 项 | 值 |
|----|----|
| 模式 | {{MODE}} |
| 平台选项 | {{PLATFORM}} |
| Android 壳 | `{{ANDROID_SHELL}}` |
| iOS 壳 | `{{IOS_SHELL}}` |
| 共享 ArkTS | `{{SHARED_ARKTS_DIR}}` |
| Android 编译环境 | {{ANDROID_READY}} |
| iOS 编译环境 | {{IOS_READY}} |
| ArkUI-X SDK | {{ARKUIX_SDK}} |

骨架文件已按所选平台生成（不受开发环境影响）；环境仅决定能否在当前环境做编译验证。壳与共享 ArkTS 路径为相对路径（modify 相对工程根，new 相对输出目录）。

---

{{SECTIONS}}

---

> 本报告由 arkuix-migration-skeleton 生成；结构化结论见同目录 `skeleton-result.json`（契约 schema_version=1，供 F3/F4 消费）。modify 模式经 ace tool modify 就地改造（原工程结构与源码保留）；new 模式源码为原样搬移（内容改写属 F3）。全流程离线执行。
