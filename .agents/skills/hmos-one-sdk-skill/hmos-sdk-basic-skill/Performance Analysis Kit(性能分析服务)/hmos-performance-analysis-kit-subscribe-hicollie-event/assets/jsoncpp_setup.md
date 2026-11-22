# HiCollie事件订阅技能 - jsoncpp库配置说明

## 概述

本技能需要使用jsoncpp库来解析事件参数中的JSON字符串。以下是jsoncpp库的配置步骤。

## jsoncpp库下载

### 方式1：从示例工程获取

1. 打开链接 [HiAppEvent示例工程EventSub](https://gitcode.com/openharmony/applications_app_samples/tree/master/code/DocsSample/PerformanceAnalysisKit/HiAppEvent/EventSub)
2. 点击"下载当前目录"，下载EventSub工程文件
3. 从解压后的EventSub工程中拷贝jsoncpp库文件

### 方式2：从官方源码编译

1. 下载源码：[三方开源库jsoncpp](https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.6.tar.gz)
2. 解压到指定目录
3. 编译生成动态库

## 目录结构配置

将jsoncpp库文件拷贝到Native C++工程中，目录结构如下：

```
entry:
  libs:    //  放置jsoncpp关联三方库的文件夹
    arm64-v8a/
      lib/
        libjsoncpp.so
  src:
    main:
      cpp:
        thirdparty:
          jsoncpp:    //  放置jsoncpp关联三方库的文件夹
            src/
              jsoncpp-1.9.6.tar.gz
            arm64-v8a/
              lib/
                libjsoncpp.so
        types:
          libentry:
            - index.d.ts
        - CMakeLists.txt
        - napi_init.cpp
      ets:
        entryability:
          - EntryAbility.ets
        pages:
          - Index.ets
```

## CMakeLists.txt配置

```cmake
# 设置OHOS架构变量
set(OHOS_ARCH arm64-v8a)

# 定义jsoncpp压缩包路径
set(GZ_FILE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/src/jsoncpp-1.9.6.tar.gz")

# 定义解压目标目录
set(DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")

# 创建目标目录
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR})

# 解压jsoncpp到目标目录
execute_process(COMMAND tar -xzf ${GZ_FILE} -C ${DEST_DIR} WORKING_DIRECTORY ${DEST_DIR})

# 链接jsoncpp动态库
target_link_libraries(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so
)

# 包含jsoncpp头文件目录
target_include_directories(entry PRIVATE 
    ${DEST_DIR}/jsoncpp-1.9.6/include/json
)
```

## 头文件引用

在napi_init.cpp中引用json头文件：

```cpp
#include "napi/native_api.h"
// 根据工程中三方库jsoncpp的位置适配引用json.h的路径
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"
```

## JSON解析使用示例

```cpp
Json::Value params;
Json::Reader reader(Json::Features::strictMode());
Json::FastWriter writer;

if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
    auto time = params["time"].asInt64();
    auto foreground = params["foreground"].asBool();
    auto processName = params["process_name"].asString();
    
    // 处理解析后的数据
}
```

## 常见问题

### Q1: 找不到json.h头文件
**解决方法**：
- 检查jsoncpp是否正确解压到build目录
- 检查CMakeLists.txt中的target_include_directories路径是否正确
- 确认使用相对路径时路径层级正确

### Q2: 链接libjsoncpp.so失败
**解决方法**：
- 确认libjsoncpp.so存在于指定路径
- 检查OHOS_ARCH变量是否正确设置（如arm64-v8a）
- 确认target_link_libraries路径正确

### Q3: JSON解析失败
**解决方法**：
- 使用strictMode解析器提高容错性
- 检查JSON字符串格式是否正确
- 添加错误处理逻辑

## 版本要求

- jsoncpp版本：1.9.6
- HarmonyOS API：12及以上
- 编译工具：CMake 3.4.1及以上