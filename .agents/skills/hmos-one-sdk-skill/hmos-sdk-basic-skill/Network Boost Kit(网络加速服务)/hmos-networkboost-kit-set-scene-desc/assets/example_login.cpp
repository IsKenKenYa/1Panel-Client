#include "NetworkBoostKit/network_boost.h"
#include <cstdio>
#include <unistd.h>

int32_t SetLoginSceneEnter()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 10;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("登录场景设置成功: 进入场景，预计持续10秒\n");
    } else {
        printf("登录场景设置失败: 错误码=%d\n", ret);
        switch (ret) {
            case 201:
                printf("权限不足，请配置ohos.permission.GET_NETWORK_INFO\n");
                break;
            case 401:
                printf("参数错误\n");
                break;
            case 801:
                printf("系统能力不支持\n");
                break;
            default:
                printf("系统服务异常\n");
        }
    }
    
    return ret;
}

int32_t SetLoginSceneLeave()
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = NB_SCENE_EVENT_LEAVE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("登录场景设置成功: 离开场景\n");
    } else {
        printf("登录场景设置失败: 错误码=%d\n", ret);
    }
    
    return ret;
}

int main()
{
    printf("=== 登录场景设置示例 ===\n");
    
    printf("步骤1: 进入登录场景\n");
    int32_t ret = SetLoginSceneEnter();
    if (ret != 0) {
        printf("进入场景失败，示例终止\n");
        return -1;
    }
    
    printf("步骤2: 模拟登录过程（5秒）\n");
    sleep(5);
    
    printf("步骤3: 登录成功，更新场景\n");
    NetworkBoost_SceneDesc updateDesc;
    updateDesc.scene = NB_SERVICE_LOGIN;
    updateDesc.sceneEvent = NB_SCENE_EVENT_UPDATE;
    updateDesc.startTime = 0;
    updateDesc.duration = 5;
    ret = HMS_NetworkBoost_SetSceneDesc(updateDesc);
    printf("场景更新结果: %d\n", ret);
    
    printf("步骤4: 等待剩余时间\n");
    sleep(5);
    
    printf("步骤5: 离开登录场景\n");
    ret = SetLoginSceneLeave();
    
    printf("=== 示例完成 ===\n");
    return 0;
}