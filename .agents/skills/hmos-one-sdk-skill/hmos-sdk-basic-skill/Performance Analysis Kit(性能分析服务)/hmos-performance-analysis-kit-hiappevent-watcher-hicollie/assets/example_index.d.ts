/**
 * index.d.ts - HiCollie定时器检测接口类型定义
 * 导出Native C++函数到ArkTS
 */

/**
 * 基本超时触发测试
 * 设置1秒超时阈值，实际执行2秒
 * 将触发APP_HICOLLIE事件
 */
export const TestHiCollieTimerNdk: () => void;

/**
 * 正常执行测试（未超时）
 * 设置2秒超时阈值，实际执行1秒
 * 不触发超时事件
 */
export const TestNormalExecution: () => void;

/**
 * 带回调的超时检测测试
 * 设置超时回调函数，自定义处理逻辑
 * 超时后回调函数将被调用
 */
export const TestHiCollieWithCallback: () => void;

/**
 * 错误场景测试
 * 演示各种错误码：无效名称、无效超时值、NULL指针等
 * 用于验证错误处理逻辑
 */
export const TestErrorCases: () => void;

/**
 * 连续多次超时检测测试
 * 模拟多个任务的执行和超时场景
 * 验证多次事件触发和取消逻辑
 */
export const TestMultipleTimeouts: () => void;