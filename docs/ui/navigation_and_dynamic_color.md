# 导航栏优化与 Android 动态取色

## 导航图标优化

### 更新的图标 (Material Design 3)

按照 MD3 规范，优化了所有导航图标，使其更具语义化和现代感：

| 模块 | 旧图标 | 新图标 | 说明 |
|------|--------|--------|------|
| 文件 | `folder_outlined` | `folder_open_outlined` | 更直观地表示"打开文件" |
| 容器 | `layers_outlined` | `widgets_outlined` | 更符合容器/组件的概念 |
| 应用 | `apps_outlined` | `grid_view_outlined` | 更清晰的网格视图 |
| 网站 | `language_outlined` | `public_outlined` | 更准确的公共/网络图标 |
| AI | `smart_toy_outlined` | `psychology_outlined` | 更符合 AI/智能的概念 |
| 安全 | `verified_user_outlined` | `shield_outlined` | 更简洁的安全图标 |

### 动画效果

所有导航组件现在都包含流畅的图标切换动画：

- **动画时长**: 200ms (图标切换) + 400ms (导航栏整体)
- **动画类型**: ScaleTransition + FadeTransition
- **效果**: 图标在选中/未选中状态切换时有缩放和淡入淡出效果
- **性能**: GPU 加速，无性能损耗

适用于：
- 底部导航栏 (NavigationBar) - 移动端
- 侧边导航栏 (NavigationRail) - 平板端
- 抽屉式导航 (Sidebar) - 桌面端

### 交互优化

- 图标切换使用 `AnimatedSwitcher` 实现平滑过渡
- 每个图标都有独立的 `ValueKey`，确保动画正确触发
- 禁用状态的图标使用 42% 透明度，符合 MD3 规范

## Android 动态取色 (Material You)

### 功能说明

应用已完整支持 Android 12+ 的 Material You 动态取色功能：

- **自动提取**: 从系统壁纸自动提取主题色
- **和谐化**: 使用 `harmonized()` 方法确保颜色协调
- **降级方案**: 不支持时使用自定义种子色
- **默认开启**: 新用户默认启用动态取色

### 配置文件

#### 1. 依赖配置 (`pubspec.yaml`)
```yaml
dependencies:
  dynamic_color: ^1.7.0
```

#### 2. Android 样式配置

**通用样式** (`android/app/src/main/res/values/styles.xml`):
```xml
<style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
    <item name="android:windowBackground">?android:colorBackground</item>
</style>
```

**Android 12+ 专用** (`android/app/src/main/res/values-v31/styles.xml`):
```xml
<style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
    <item name="android:windowBackground">@drawable/launch_background</item>
</style>

<style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
    <item name="android:windowBackground">?android:colorBackground</item>
</style>
```

使用 `Theme.Black.NoTitleBar` 作为基础主题，Flutter 会接管完整的主题控制，包括动态取色。

#### 3. 主题实现 (`lib/main.dart`)
```dart
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    if (lightDynamic != null && 
        darkDynamic != null && 
        themeController.useDynamicColor) {
      // 使用系统动态颜色
      lightTheme = AppTheme.create(lightDynamic.harmonized());
      darkTheme = AppTheme.create(darkDynamic.harmonized());
    } else {
      // 降级到种子色
      lightTheme = AppTheme.create(
        ColorScheme.fromSeed(
          seedColor: themeController.seedColor,
          brightness: Brightness.light,
        ),
      );
      darkTheme = AppTheme.create(
        ColorScheme.fromSeed(
          seedColor: themeController.seedColor,
          brightness: Brightness.dark,
        ),
      );
    }
  },
)
```

### 用户控制

用户可以在 **设置 > 主题设置** 中：
- 开启/关闭动态取色
- 选择自定义种子色（动态取色不可用时使用）
- 切换深色/浅色/跟随系统

### 平台支持

| 平台 | 动态取色支持 | 说明 |
|------|-------------|------|
| Android 12+ (API 31+) | ✅ 完全支持 | Material You 动态取色 |
| Android 11- (API 30-) | ❌ 不支持 | 使用种子色降级 |
| iOS | ❌ 不支持 | 使用种子色 |
| Web/Desktop | ❌ 不支持 | 使用种子色 |

### 测试验证

在 Android 12+ 设备上：
1. 更换系统壁纸（选择色彩鲜明的壁纸效果更明显）
2. 打开应用，主题色会自动适配壁纸
3. 在设置中可以关闭动态取色，使用固定种子色
4. 切换深色/浅色模式，动态取色都会生效

## 修改的文件

### 导航图标优化
1. `lib/features/shell/models/client_module.dart` - 更新图标定义
2. `lib/widgets/navigation/app_bottom_navigation_bar.dart` - 添加动画效果
3. `lib/features/shell/widgets/adaptive_shell_navigation_widget.dart` - 优化 Rail 和 Sidebar

### Android 动态取色
4. `android/app/src/main/res/values-v31/styles.xml` - Android 12+ 样式配置（新增）

### 测试文件
5. `test/features/shell/navigation_icon_optimization_test.dart` - 导航图标测试（新增）

## 性能影响

- 动画使用 Flutter 内置的 AnimatedSwitcher，性能开销极小
- 动态取色仅在应用启动时提取一次，无运行时开销
- 所有动画都是 GPU 加速的，不影响 UI 流畅度
- 图标切换动画仅在用户点击时触发，不会持续消耗资源

## 符合规范

- ✅ 遵循 Material Design 3 设计规范
- ✅ 使用语义化图标提升可读性
- ✅ 动画流畅自然，符合 MD3 动效标准
- ✅ Android 12+ 完整支持 Material You
- ✅ 通过 `flutter analyze` 静态分析
- ✅ 所有单元测试通过 (16 个测试)
