/**
 * ArkTS接口定义
 * 用于在ArkTS层调用Native C++模块的接口
 */

/**
 * 注册事件观察者
 * 创建观察者，设置过滤器，添加回调，开始监听应用终止事件
 */
export const registerWatcher: () => void;

/**
 * 移除事件观察者
 * 停止监听事件，观察者仍常驻内存
 */
export const removeWatcher: () => void;

/**
 * 销毁事件观察者
 * 释放内存，防止内存泄漏
 * 销毁后观察者指针置为nullptr
 */
export const destroyWatcher: () => void;

/**
 * 获取观察者状态
 * 返回观察者的当前状态信息
 */
export const getWatcherStatus: () => {
  isNull: boolean;
  message: string;
};

/**
 * 触发内存泄漏（仅用于测试）
 * 模拟内存泄漏场景，触发应用终止
 * 注意：仅用于故障注入及自验证，无需集成到业务逻辑中
 */
export const leak?: () => void;