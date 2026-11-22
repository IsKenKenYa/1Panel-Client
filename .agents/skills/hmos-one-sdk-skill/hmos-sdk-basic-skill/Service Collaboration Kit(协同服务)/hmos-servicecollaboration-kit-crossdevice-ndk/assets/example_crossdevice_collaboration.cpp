#include "service_collaboration/service_collaboration_api.h"
#include <thread>
#include <cstring>
#include <iostream>
#include <fstream>

static int32_t OnEventProc(ServiceCollaborationEventCode code, uint32_t extraCode) {
    switch (code) {
        case LAST_DATA_BACK:
            std::cout << "已收到最后一个数据包，数据传输完成" << std::endl;
            break;
        case PEER_CANCEL:
            std::cout << "对端设备已取消操作" << std::endl;
            break;
        case NETWORK_ERROR:
            std::cout << "网络异常，错误码：" << extraCode << std::endl;
            std::cout << "建议：检查网络连接，接入同一局域网" << std::endl;
            break;
        case PEER_WIFI_NOT_OPEN:
            std::cout << "对端WLAN未开启" << std::endl;
            std::cout << "建议：提示用户开启对端WLAN开关" << std::endl;
            break;
        case LOCAL_WIFI_NOT_OPEN:
            std::cout << "本端WLAN未开启" << std::endl;
            std::cout << "建议：开启本端WLAN开关" << std::endl;
            break;
        case DATA_BACK_START:
            std::cout << "开始回传数据，准备接收..." << std::endl;
            break;
        case MIDDLE_DATA_BACK:
            std::cout << "收到中间数据包，继续接收..." << std::endl;
            break;
        case TIMEOUT_AUTO_CANCEL:
            std::cout << "接收数据超时自动取消" << std::endl;
            std::cout << "建议：增加等待时间或检查网络稳定性" << std::endl;
            break;
        case DATA_READ_FAILED:
            std::cout << "数据读取失败" << std::endl;
            std::cout << "建议：检查存储权限和空间" << std::endl;
            break;
        case LINK_SHUTDOWN:
            std::cout << "链路断开" << std::endl;
            std::cout << "建议：检查设备连接状态并重新尝试" << std::endl;
            break;
        case REMOTE_HOTSPOT_CONFLICT:
            std::cout << "对端开启热点导致链路冲突" << std::endl;
            std::cout << "建议：提示用户关闭对端热点" << std::endl;
            break;
        case REMOTE_DISTRIBUTED_SERVICES_CONFLICT:
            std::cout << "对端与其他设备互联导致冲突" << std::endl;
            std::cout << "建议：提示用户停止其他互联操作" << std::endl;
            break;
        default:
            std::cout << "收到事件码：" << code << "，额外码：" << extraCode << std::endl;
    }
    return 0;
}

static int32_t OnDataCallbackProc(
    ServiceCollaborationEventCode code,
    ServiceCollaborationDataType dataType,
    uint32_t dataSize,
    char* data) {
    
    if (dataType == IMAGE) {
        std::cout << "收到图片数据，大小：" << dataSize << " 字节" << std::endl;
        
        std::string filename = "received_image_" + std::to_string(std::time(nullptr)) + ".jpg";
        std::ofstream outfile(filename, std::ios::binary);
        
        if (outfile.is_open()) {
            outfile.write(data, dataSize);
            outfile.close();
            std::cout << "图片已保存到：" << filename << std::endl;
        } else {
            std::cerr << "无法打开文件保存图片数据" << std::endl;
        }
    }
    
    return 0;
}

int main(int argc, char* argv[]) {
    std::cout << "=== 跨设备互通NDK示例程序 ===" << std::endl;
    
    ServiceCollaborationFilterType serviceFilterTypes[3] = {
        TAKE_PHOTO,
        SCAN_DOCUMENT,
        IMAGE_PICKER
    };
    
    std::cout << "步骤1：获取支持跨设备互通能力的设备列表..." << std::endl;
    ServiceCollaboration_CollaborationDeviceInfoSets* deviceInfoSets = 
        HMS_ServiceCollaboration_GetCollaborationDeviceInfos(3, serviceFilterTypes);
    
    if (deviceInfoSets == nullptr || deviceInfoSets->size == 0) {
        std::cerr << "错误：未找到支持跨设备互通能力的设备" << std::endl;
        std::cout << "请检查：" << std::endl;
        std::cout << "1. 远端设备是否已登录同一华为账号" << std::endl;
        std::cout << "2. 双端设备是否已开启WLAN和蓝牙" << std::endl;
        std::cout << "3. 远端设备HarmonyOS版本是否≥5.0" << std::endl;
        return 1;
    }
    
    std::cout << "找到 " << deviceInfoSets->size << " 个支持跨设备互通的设备" << std::endl;
    
    ServiceCollaboration_SelectInfo taskInfo = { TAKE_PHOTO, { 0 } };
    bool deviceFound = false;
    
    for (uint32_t i = 0; i < deviceInfoSets->size; i++) {
        ServiceCollaboration_CollaborationDeviceInfo* deviceInfo = 
            &(deviceInfoSets->deviceInfoSets[i]);
        
        std::cout << "设备 " << i << ": 网络ID=" << deviceInfo->deviceNetworkId 
                  << ", 设备类型=" << deviceInfo->deviceType 
                  << ", 支持能力数=" << deviceInfo->filterTypesNum << std::endl;
        
        for (uint32_t j = 0; j < deviceInfo->filterTypesNum; j++) {
            if (deviceInfo->filterTypes[j] == TAKE_PHOTO) {
                taskInfo.serviceFilterType = TAKE_PHOTO;
                std::memcpy(taskInfo.deviceNetworkId, deviceInfo->deviceNetworkId, 
                    COLLABORATIONDEVICEINFO_DEVICENETWORKID_MAXLENGTH - 1);
                deviceFound = true;
                std::cout << "已选择设备 " << i << " 进行拍照协同" << std::endl;
                break;
            }
        }
        
        if (deviceFound) break;
    }
    
    if (!deviceFound) {
        std::cerr << "错误：未找到支持拍照能力的设备" << std::endl;
        return 1;
    }
    
    std::cout << "步骤2：创建回调函数..." << std::endl;
    ServiceCollaborationCallback callback = {
        .OnEvent = OnEventProc,
        .OnDataCallback = OnDataCallbackProc
    };
    
    std::cout << "步骤3：启动跨设备互通..." << std::endl;
    uint32_t collaborationId = HMS_ServiceCollaboration_StartCollaboration(&taskInfo, &callback);
    
    if (collaborationId == 0) {
        std::cerr << "错误：启动跨设备互通失败" << std::endl;
        return 1;
    }
    
    std::cout << "跨设备互通已启动，会话ID：" << collaborationId << std::endl;
    std::cout << "等待对端设备操作..." << std::endl;
    
    std::cout << "提示：对端设备将拉起相机，请在远端设备上进行拍照操作" << std::endl;
    
    int shouldCancel = 0;
    std::cout << "是否在3秒后主动取消？(输入1取消，0等待完成): ";
    std::cin >> shouldCancel;
    
    if (shouldCancel == 1) {
        std::this_thread::sleep_for(std::chrono::seconds(3));
        std::cout << "步骤4：主动取消跨设备互通..." << std::endl;
        
        int32_t result = HMS_ServiceCollaboration_StopCollaboration(collaborationId);
        
        if (result == 0) {
            std::cout << "跨设备互通已成功取消" << std::endl;
        } else {
            std::cerr << "取消失败，错误码：" << result << std::endl;
        }
    } else {
        std::cout << "等待对端设备完成操作并回传数据..." << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(60));
    }
    
    std::cout << "=== 程序结束 ===" << std::endl;
    return 0;
}