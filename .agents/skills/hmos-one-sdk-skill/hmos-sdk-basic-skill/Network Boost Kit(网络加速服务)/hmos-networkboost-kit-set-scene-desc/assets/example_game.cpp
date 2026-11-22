#include "NetworkBoostKit/network_boost.h"
#include <cstdio>
#include <unistd.h>

int32_t StartRealTimeGame()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_REAL_TIME_GAME;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("实时游戏场景设置成功: 进入场景\n");
    } else {
        printf("实时游戏场景设置失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int32_t PauseGame()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_REAL_TIME_GAME;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_UPDATE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 30;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("游戏暂停: 更新场景，预计暂停30秒\n");
    } else {
        printf("场景更新失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int32_t ResumeGame()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_REAL_TIME_GAME;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_UPDATE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("游戏恢复: 更新场景，持续时长未知\n");
    } else {
        printf("场景更新失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int32_t StopGame()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_REAL_TIME_GAME;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_LEAVE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("实时游戏场景设置成功: 离开场景\n");
    } else {
        printf("实时游戏场景设置失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int main()
{
    printf("=== 实时游戏场景设置示例 ===\n");
    
    printf("步骤1: 开始实时游戏\n");
    int32_t ret = StartRealTimeGame();
    if (ret != 0) {
        printf("进入场景失败，示例终止\n");
        return -1;
    }
    
    printf("步骤2: 模拟游戏进行（15秒）\n");
    sleep(15);
    
    printf("步骤3: 游戏暂停（切换后台）\n");
    ret = PauseGame();
    printf("游戏已暂停\n");
    
    printf("步骤4: 等待暂停时间（5秒）\n");
    sleep(5);
    
    printf("步骤5: 游戏恢复（切回前台）\n");
    ret = ResumeGame();
    printf("游戏已恢复\n");
    
    printf("步骤6: 继续游戏（10秒）\n");
    sleep(10);
    
    printf("步骤7: 退出游戏\n");
    ret = StopGame();
    
    printf("=== 示例完成 ===\n");
    return 0;
}