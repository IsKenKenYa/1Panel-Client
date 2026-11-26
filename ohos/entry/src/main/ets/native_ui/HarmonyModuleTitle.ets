import { titleBarMaterial } from './HarmonyNativeBridge';

/**
 * 原生模块根页面标题栏的统一规格。
 *
 * 所有一级模块页共用同一份标题选项：浮动标题栏叠在滚动内容之上，
 * 使用官方 ULTRA_THIN 材质并随内容滚动产生模糊。页面只提供标题文本与
 * 菜单项，不各自定义标题栏样式。
 */
export const moduleTitleOptions: NavigationTitleOptions = {
  barStyle: BarStyle.STACK,
  systemMaterial: titleBarMaterial,
  scrollEffectOptions: { scrollEffectType: ScrollEffectType.COMMON_BLUR },
};

/** 侧边导航栏的统一宽度，取官方侧栏默认值 240vp。 */
export const MODULE_NAV_BAR_WIDTH = 240;
