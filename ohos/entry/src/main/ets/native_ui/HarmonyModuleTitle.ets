import { titleBarMaterial } from './HarmonyNativeBridge';

/**
 * 原生模块根页面标题栏的统一规格。
 *
 * 所有一级模块页共用同一份标题选项：标题栏与内容区上下排列，系统为标题栏
 * 预留空间，内容不会被压到标题栏下方。页面只提供标题文本与菜单项，
 * 不各自定义标题栏样式。
 */
export const moduleTitleOptions: NavigationTitleOptions = {
  barStyle: BarStyle.STANDARD,
  systemMaterial: titleBarMaterial,
};

/** 侧边导航栏的统一宽度，取官方侧栏默认值 240vp。 */
export const MODULE_NAV_BAR_WIDTH = 240;

/**
 * 分栏页导航页的默认宽度。
 *
 * 官方默认 240vp 在宽窗口下会挤压列表列，取 340vp 作为初始值。
 */
export const MODULE_SPLIT_NAV_BAR_WIDTH = 340;

/**
 * 分栏页导航页的宽度区间。
 *
 * 官方在同时设置 navBarWidthRange 与 minContentWidth 时允许拖拽分割线，
 * 拖拽受内容区最小宽度约束；仅设置 navBarWidth 会固定宽度并禁止拖拽。
 */
export const MODULE_SPLIT_NAV_BAR_RANGE: [Dimension, Dimension] = [240, 432];

/**
 * 分栏页内容区最小宽度。
 *
 * 官方默认 360vp 会把宽折叠屏上的列表列压缩到 313vp，取 320vp 让列表与详情宽度接近。
 */
export const MODULE_SPLIT_MIN_CONTENT_WIDTH = 320;
