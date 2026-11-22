/**
 * TypeScript接口定义文件
 * 定义Native C++模块导出的接口
 */

/**
 * 测试HiCollie定时器
 * 模拟任务执行超时场景,触发APP_HICOLLIE事件
 */
export const TestHiCollieTimerNdk: () => void;

/**
 * 注册onReceive类型观察者
 * 实时接收APP_HICOLLIE事件,事件发生后立即触发回调
 */
export const RegisterAppHicollieWatcherR: () => void;

/**
 * 注册onTrigger类型观察者
 * 缓存APP_HICOLLIE事件,满足触发条件后批量处理
 */
export const RegisterAppHicollieWatcherT: () => void;

/**
 * 移除观察者
 * 使观察者停止监听系统消息
 * 注意:仅停止监听,观察者对象仍存在
 */
export const RemoveWatcher: () => void;

/**
 * 销毁观察者
 * 释放观察者内存,防止内存泄漏
 * 注意:销毁后指针置空,无法再次使用
 */
export const DestroyWatcher: () => void;