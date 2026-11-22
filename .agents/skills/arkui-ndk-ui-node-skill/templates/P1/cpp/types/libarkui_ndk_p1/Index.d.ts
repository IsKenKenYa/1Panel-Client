import { NodeContent } from '@kit.ArkUI';

// ArkTS NDK .so 模块类型声明：必须用 export const 顶层声明导出各方法
// ArkTS 侧 `import nativeModule from 'libarkui_ndk_p1.so'` 后，nativeModule 即此模块对象
// 不得改写为 export interface + export default（会导致 nativeModule 为类型而非值 → "X is not callable"）
export const mountNativeNodes: (nodeContent: NodeContent) => void;
export const disposeNodes: () => void;
