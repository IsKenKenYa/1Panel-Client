/**
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @file example_set_scene_desc.cpp
 * @brief Network Boost Kit - 业务场景设置完整示例
 * 
 * 本示例演示如何使用HMS_NetworkBoost_SetSceneDesc接口设置业务场景,
 * 包括登录场景、秒杀场景、直播场景等多种业务场景的设置流程。
 */

#include "NetworkBoostKit/network_boost.h"
#include <cstdio>
#include <cstring>
#include <thread>
#include <chrono>

/**
 * 设置登录业务场景
 * 场景类型: NB_SERVICE_LOGIN
 * 持续时长: 30秒
 */
int32_t SetLoginScene()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 30;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("登录场景设置成功,场景类型: LOGIN, 持续时长: %d秒\n", sceneDesc.duration);
    } else {
        printf("登录场景设置失败,错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 设置秒杀业务场景
 * 场景类型: NB_SERVICE_SECKILL_SERVICE
 * 持续时长: 20秒
 */
int32_t SetSeckillScene()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = NB_SERVICE_SECKILL_SERVICE;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 20;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("秒杀场景设置成功,场景类型: SECKILL_SERVICE, 持续时长: %d秒\n", sceneDesc.duration);
    } else {
        printf("秒杀场景设置失败,错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 设置直播观看业务场景
 * 场景类型: NB_SERVICE_LIVE_STREAMING_WATCHER
 * 持续时长: 60分钟(3600秒)
 */
int32_t SetLiveStreamingWatcherScene()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = NB_SERVICE_LIVE_STREAMING_WATCHER;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 3600;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("直播观看场景设置成功,场景类型: LIVE_STREAMING_WATCHER, 持续时长: %d分钟\n", 
               sceneDesc.duration / 60);
    } else {
        printf("直播观看场景设置失败,错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 设置实时游戏业务场景
 * 场景类型: NB_SERVICE_REAL_TIME_GAME
 * 持续时长: 未知(0),由LEAVE事件终止
 */
int32_t SetRealTimeGameScene()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = NB_SERVICE_REAL_TIME_GAME;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("实时游戏场景设置成功,场景类型: REAL_TIME_GAME, 持续时长: 未知(由LEAVE事件终止)\n");
    } else {
        printf("实时游戏场景设置失败,错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 更新业务场景信息
 * 场景事件: SCENE_EVENT_UPDATE
 */
int32_t UpdateSceneDesc(NetworkBoost_ServiceType serviceType, uint32_t newDuration)
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = serviceType;
    sceneDesc.sceneEvent = SCENE_EVENT_UPDATE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = newDuration;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("业务场景更新成功,新的持续时长: %d秒\n", newDuration);
    } else {
        printf("业务场景更新失败,错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 离开业务场景
 * 场景事件: SCENE_EVENT_LEAVE
 */
int32_t LeaveSceneDesc(NetworkBoost_ServiceType serviceType)
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = serviceType;
    sceneDesc.sceneEvent = SCENE_EVENT_LEAVE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("业务场景离开成功,场景类型: %d\n", serviceType);
    } else {
        printf("业务场景离开失败,错误码: %d\n", ret);
    }
    
    return ret;
}

/**
 * 带错误处理的场景设置
 */
int32_t SetSceneDescWithErrorHandling(NetworkBoost_ServiceType serviceType, 
                                       NetworkBoost_SceneEvent sceneEvent,
                                       uint32_t startTime, 
                                       uint32_t duration)
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = serviceType;
    sceneDesc.sceneEvent = sceneEvent;
    sceneDesc.startTime = startTime;
    sceneDesc.duration = duration;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    switch (ret) {
        case 0:
            printf("业务场景设置成功\n");
            printf("场景类型: %d, 场景事件: %d\n", serviceType, sceneEvent);
            printf("开始时间: %d秒, 持续时长: %d秒\n", startTime, duration);
            break;
        case 201:
            printf("权限不足,请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误,请检查参数是否合法\n");
            printf("sceneType范围: 0-23, sceneEvent范围: 0-2\n");
            printf("startTime和duration必须为非负数\n");
            break;
        case 801:
            printf("系统能力不支持,API版本需>=6.0.2(22)\n");
            break;
        case 62100001:
            printf("内部错误,建议重试最多3次\n");
            break;
        case 62100002:
            printf("系统服务操作失败,延迟100ms后重试\n");
            break;
        default:
            printf("未知错误: %d\n", ret);
    }
    
    return ret;
}

/**
 * 带降级处理的场景设置
 */
int32_t SetSceneDescWithFallback(NetworkBoost_ServiceType serviceType)
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = serviceType;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 30;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 62100002) {
        printf("系统服务失败,延迟100ms后重试...\n");
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
        
        if (ret != 0) {
            printf("场景设置重试失败,跳过场景设置\n");
            return -1;
        }
    } else if (ret == 801) {
        printf("系统不支持此API,跳过场景设置\n");
        return -1;
    } else if (ret == 201) {
        printf("权限不足,跳过场景设置\n");
        return -1;
    }
    
    return ret;
}

/**
 * 完整的业务场景生命周期示例
 * 1. 进入场景(ENTER)
 * 2. 更新场景(UPDATE)
 * 3. 离开场景(LEAVE)
 */
void SceneLifecycleExample()
{
    printf("\n=== 业务场景生命周期示例 ===\n");
    
    NetworkBoost_ServiceType serviceType = NB_SERVICE_LOGIN;
    
    printf("\n1. 进入登录场景\n");
    int32_t ret = SetSceneDescWithErrorHandling(serviceType, SCENE_EVENT_ENTER, 0, 30);
    if (ret != 0) {
        printf("进入场景失败,终止示例\n");
        return;
    }
    
    printf("\n等待10秒...\n");
    std::this_thread::sleep_for(std::chrono::seconds(10));
    
    printf("\n2. 更新登录场景(延长持续时间)\n");
    ret = UpdateSceneDesc(serviceType, 60);
    if (ret != 0) {
        printf("更新场景失败\n");
    }
    
    printf("\n等待5秒...\n");
    std::this_thread::sleep_for(std::chrono::seconds(5));
    
    printf("\n3. 离开登录场景\n");
    ret = LeaveSceneDesc(serviceType);
    if (ret != 0) {
        printf("离开场景失败\n");
    }
    
    printf("\n=== 业务场景生命周期示例完成 ===\n");
}

/**
 * 主函数
 */
int main()
{
    printf("=== Network Boost Kit - 业务场景设置示例 ===\n");
    printf("API版本: 6.0.2(22)\n");
    printf("权限要求: ohos.permission.GET_NETWORK_INFO\n\n");
    
    printf("=== 示例1: 设置登录场景 ===\n");
    SetLoginScene();
    
    printf("\n=== 示例2: 设置秒杀场景 ===\n");
    SetSeckillScene();
    
    printf("\n=== 示例3: 设置直播观看场景 ===\n");
    SetLiveStreamingWatcherScene();
    
    printf("\n=== 示例4: 设置实时游戏场景 ===\n");
    SetRealTimeGameScene();
    
    printf("\n=== 示例5: 带降级处理的场景设置 ===\n");
    SetSceneDescWithFallback(NB_SERVICE_DOWNLOAD);
    
    printf("\n=== 示例6: 完整业务场景生命周期 ===\n");
    SceneLifecycleExample();
    
    printf("\n=== 示例执行完成 ===\n");
    printf("注意事项:\n");
    printf("1. 需要在module.json5中配置ohos.permission.GET_NETWORK_INFO权限\n");
    printf("2. 需要在CMakeLists.txt中链接libnetwork_boost.so\n");
    printf("3. API版本需要>=6.0.2(22)\n");
    printf("4. 建议在发起多网请求前设置业务场景\n");
    
    return 0;
}