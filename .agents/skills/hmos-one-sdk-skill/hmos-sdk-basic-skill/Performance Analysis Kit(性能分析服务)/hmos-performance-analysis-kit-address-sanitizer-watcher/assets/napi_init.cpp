/**
 * Native C++地址越界错误构造示例
 * 用于演示如何触发ADDRESS_SANITIZER事件
 * 
 * 功能：
 * 1. 提供test()接口触发数组越界写入
 * 2. 注册NAPI模块导出接口
 * 3. 供ArkTS层调用触发错误
 */

#include "napi/native_api.h"

/**
 * 测试函数：构造数组越界写入
 * 触发Address Sanitizer检测并生成事件
 */
static napi_value Test(napi_env env, napi_callback_info info)
{
    // 定义大小为10的数组
    int a[10];
    
    // 构造数组越界写入（访问索引10，超出范围0-9）
    a[10] = 1;  // Address Sanitizer会检测到此错误
    
    // 返回空值
    return {};
}

/**
 * 模块初始化：注册NAPI接口
 */
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    // 定义接口属性
    napi_property_descriptor desc[] = {
        { 
            "test",               // 接口名称
            nullptr,              // getter
            Test,                 // 函数实现
            nullptr,              // setter
            nullptr,              // value
            napi_default,         // 属性属性
            nullptr               // data
        }
    };
    
    // 注册接口到exports对象
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    return exports;
}
EXTERN_C_END

/**
 * 模块定义：声明模块信息
 */
static napi_module demoModule = {
    .nm_version = 1,                // 模块版本
    .nm_flags = 0,                  // 模块标志
    .nm_filename = nullptr,         // 文件名
    .nm_register_func = Init,       // 注册函数
    .nm_modname = "entry",          // 模块名称（与libentry.so对应）
    .nm_priv = ((void*)0),          // 私有数据
    .reserved = { 0 }               // 保留字段
};

/**
 * 模块注册：自动调用注册函数
 */
extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}