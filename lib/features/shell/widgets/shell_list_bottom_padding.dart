import 'package:flutter/material.dart';

/// 玻璃底栏悬浮胶囊的列表底部让位。
///
/// 壳层在液态玻璃模式下开启 extendBody 并向 body 的 MediaQuery 注入
/// 胶囊占高（见 app_shell_page 的 floatHeight），让列表滚动范围延伸到
/// 玻璃底栏后方、内容可从栏下穿透。ListView 仅在 padding 为 null 时
/// 才消费 MediaQuery 底部让位；显式 padding 的列表页必须把该值并入
/// 自己的 padding，否则最后一屏内容停在胶囊后方、无法滚动出来点击。
EdgeInsets shellListBottomPadding(BuildContext context) =>
    EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom);
