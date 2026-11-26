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
