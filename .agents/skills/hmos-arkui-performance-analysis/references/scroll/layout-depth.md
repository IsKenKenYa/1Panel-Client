# 布局测量层级

通用的容器职责、语义保持、最小对照及节点归因统一读取[冗余布局](../startup/layout-redundancy.md)，不按嵌套层数直接判缺陷。

滑动场景额外核对：

- 固定同一滚动路径、可见范围与缓存条件，观察实际布局工作；不能断言每个滑动帧都对全部节点重新布局。
- GridItem外Stack若仅包裹内容可评估移除；承担遮罩、叠加、命中或裁剪职责时保留。RelativeContainer仅在alignRules能保持原布局时评估。
- 通用属性、AttributeModifier与__Common__节点的关系按实际生成树判断，不凭属性数量推断等量新增节点。
- Flex二次布局独立按[Flex规则](flex-layout.md)判断，不把所有Flex改为Row。

按目标子树ID比较Create/Measure/Layout节点与实际FlushLayoutTask工作；范围以当前节点和动作限定，不能把全应用同名节点算入。功能语义在建议中保持，默认不附独立回归清单。
