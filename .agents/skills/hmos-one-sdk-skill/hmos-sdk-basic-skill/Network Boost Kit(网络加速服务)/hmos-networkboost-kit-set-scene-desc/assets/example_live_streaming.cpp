#include "NetworkBoostKit/network_boost.h"
#include <cstdio>
#include <unistd.h>

int32_t StartLiveStreamingWatcher()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_LIVE_STREAMING_WATCHER;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("直播观看场景设置成功: 进入场景\n");
    } else {
        printf("直播观看场景设置失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int32_t UpdateLiveStreamingBitrate(uint32_t newDuration)
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_LIVE_STREAMING_WATCHER;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_UPDATE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = newDuration;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("直播场景更新成功: 预计持续%d秒\n", newDuration);
    } else {
        printf("直播场景更新失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int32_t StopLiveStreamingWatcher()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_LIVE_STREAMING_WATCHER;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_LEAVE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("直播观看场景设置成功: 离开场景\n");
    } else {
        printf("直播观看场景设置失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int main()
{
    printf("=== 直播观看场景设置示例 ===\n");
    
    printf("步骤1: 开始观看直播\n");
    int32_t ret = StartLiveStreamingWatcher();
    if (ret != 0) {
        printf("进入场景失败，示例终止\n");
        return -1;
    }
    
    printf("步骤2: 模拟观看直播（10秒）\n");
    sleep(10);
    
    printf("步骤3: 切换高清码率，更新场景\n");
    ret = UpdateLiveStreamingBitrate(20);
    printf("码率切换完成\n");
    
    printf("步骤4: 继续观看（10秒）\n");
    sleep(10);
    
    printf("步骤5: 退出直播间\n");
    ret = StopLiveStreamingWatcher();
    
    printf("=== 示例完成 ===\n");
    return 0;
}