# Flutter Vulkan 内存分配优化

**适用场景**：鸿蒙应用嵌入 Flutter 引擎，通过 Impeller Vulkan 后端渲染，native heap 中 GPU 相关内存占用过高，存在 VMA 内存分配未优化的问题。

本方案包含两个互补的优化项：

1. **专用内存分配**：Image/Buffer 资源启用 `VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT`，减少碎片化
2. **大块堆预分配**：`preferredLargeHeapBlockSize` 设置非零值（如 32MB），减少 `vkAllocateMemory` 调用次数

## 架构概览

```
┌──────────────────────────────────────────────┐
│           Flutter 应用层                      │
│  Dart 代码 / Widget 树 / 业务逻辑             │
├──────────────────────────────────────────────┤
│           Flutter 引擎层                      │
│  Impeller 渲染器 / Skia / Dart VM             │
├──────────────────────────────────────────────┤
│           Impeller Vulkan 后端                │
│  AllocatorVK → VMA (Vulkan Memory Allocator) │
│  DeviceBufferVK / TextureVK / PipelineVK     │
│  vkAllocateMemory / vkBindImageMemory        │
└──────────────────────────────────────────────┘
```

## 问题定位

### 关键文件

| 文件路径 | 说明 |
|---------|------|
| `src/flutter/impeller/renderer/backend/vulkan/allocator_vk.cc` | Impeller 后端 VMA 分配器（初始化 + Image/Buffer 分配） |
| `src/flutter/flutter_vma/flutter_skia_vma.cc` | Skia 渲染路径 VMA 分配器初始化 |
| `src/flutter/impeller/renderer/backend/vulkan/device_buffer_vk.cc` | GPU Buffer 分配 |
| `src/flutter/impeller/renderer/backend/vulkan/texture_vk.cc` | GPU Texture/Image 分配 |

### 搜索关键词

| 关键词 | 文件 | 检查内容 |
|--------|------|---------|
| `vmaCreateAllocator` | `allocator_vk.cc`, `flutter_skia_vma.cc` | VmaAllocatorCreateInfo 中 `preferredLargeHeapBlockSize` 是否为 0 |
| `preferredLargeHeapBlockSize` | `allocator_vk.cc`, `flutter_skia_vma.cc` | 是否设置为大块预分配值（建议 32MB） |
| `vmaCreateImage` | `allocator_vk.cc` | VmaAllocationCreateInfo 的 flags 是否设置 `VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT` |
| `vmaCreateBuffer` | `allocator_vk.cc` | 大型 Buffer（>= 1MB）flags 是否设置 `VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT` |

---

## 优化项一：专用内存分配（Dedicated Memory）

### 1. allocator_vk.cc — vmaCreateImage 启用专用内存

```cpp
// ⚠️ 以下代码为 Flutter 引擎 C++ 修改

// 修改前：未设置 VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT
bool AllocatorVK::CreateImage(VkImage* image,
                               VmaAllocation* allocation,
                               const VkImageCreateInfo& image_create_info,
                               const char* debug_name) {
  VmaAllocationCreateInfo alloc_info = {};
  alloc_info.usage = VMA_MEMORY_USAGE_GPU_ONLY;
  // 缺少: alloc_info.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;

  VkResult result = vmaCreateImage(allocator_, &image_create_info,
                                    &alloc_info, image, allocation, nullptr);
  return result == VK_SUCCESS;
}

// 修改后：Image 一律使用专用内存分配
bool AllocatorVK::CreateImage(VkImage* image,
                               VmaAllocation* allocation,
                               const VkImageCreateInfo& image_create_info,
                               const char* debug_name) {
  VmaAllocationCreateInfo alloc_info = {};
  alloc_info.usage = VMA_MEMORY_USAGE_GPU_ONLY;
  alloc_info.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;

  VkResult result = vmaCreateImage(allocator_, &image_create_info,
                                    &alloc_info, image, allocation, nullptr);
  return result == VK_SUCCESS;
}
```

### 2. allocator_vk.cc — vmaCreateBuffer 启用专用内存

```cpp
// ⚠️ 以下代码为 Flutter 引擎 C++ 修改

// 修改后：大型 Buffer 启用专用内存分配，小型 Buffer 保持池化
bool AllocatorVK::CreateBuffer(VkBuffer* buffer,
                                VmaAllocation* allocation,
                                const VkBufferCreateInfo& buffer_create_info,
                                const char* debug_name) {
  VmaAllocationCreateInfo alloc_info = {};
  alloc_info.usage = VMA_MEMORY_USAGE_GPU_ONLY;

  // 大型 Buffer（>= 1MB）使用专用内存分配，小型 Buffer 保持池化分配
  if (buffer_create_info.size >= 1024 * 1024) {
    alloc_info.flags = VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;
  }

  VkResult result = vmaCreateBuffer(allocator_, &buffer_create_info,
                                     &alloc_info, buffer, allocation, nullptr);
  return result == VK_SUCCESS;
}
```

### 设备分档策略

专用内存分配无需设备分档——在所有档位设备上都应启用：
- **减少碎片化**是通用收益，不区分设备档位
- **专用内存分配**对于大型 Image/Buffer 是 Vulkan 最佳实践
- 不涉及策略性取舍（如缓存大小、预加载开关等）

---

## 优化项二：大块堆预分配（preferredLargeHeapBlockSize）

### 3. allocator_vk.cc — Impeller 后端 VMA 初始化

```cpp
// ⚠️ 以下代码为 Flutter 引擎 C++ 修改

// 修改前：preferredLargeHeapBlockSize 为 0（默认值）
// 每次分配触发独立的 vkAllocateMemory 调用，效率低且碎片化
bool AllocatorVK::Initialize(VkInstance instance,
                              VkPhysicalDevice physical_device,
                              VkDevice device) {
  VmaAllocatorCreateInfo allocator_info = {};
  allocator_info.instance = instance;
  allocator_info.physicalDevice = physical_device;
  allocator_info.device = device;
  // 缺少: allocator_info.preferredLargeHeapBlockSize = 32 * 1024 * 1024;

  VkResult result = vmaCreateAllocator(&allocator_info, &allocator_);
  return result == VK_SUCCESS;
}

// 修改后：设置 preferredLargeHeapBlockSize 为 32MB
bool AllocatorVK::Initialize(VkInstance instance,
                              VkPhysicalDevice physical_device,
                              VkDevice device) {
  VmaAllocatorCreateInfo allocator_info = {};
  allocator_info.instance = instance;
  allocator_info.physicalDevice = physical_device;
  allocator_info.device = device;
  // 预分配 32MB 大块堆内存，减少碎片化和 vkAllocateMemory 调用次数
  allocator_info.preferredLargeHeapBlockSize = 32 * 1024 * 1024;  // 32MB

  VkResult result = vmaCreateAllocator(&allocator_info, &allocator_);
  return result == VK_SUCCESS;
}
```

### 4. flutter_skia_vma.cc — Skia 渲染路径 VMA 初始化

```cpp
// ⚠️ 以下代码为 Flutter 引擎 C++ 修改

// 修改后：与 Impeller 后端保持一致，设置 32MB 大块堆
VmaAllocator CreateVmaAllocator(VkInstance instance,
                                 VkPhysicalDevice physical_device,
                                 VkDevice device) {
  VmaAllocatorCreateInfo allocator_info = {};
  allocator_info.instance = instance;
  allocator_info.physicalDevice = physical_device;
  allocator_info.device = device;
  // 预分配 32MB 大块堆内存，与 Impeller 后端保持一致
  allocator_info.preferredLargeHeapBlockSize = 32 * 1024 * 1024;  // 32MB

  VmaAllocator allocator;
  vmaCreateAllocator(&allocator_info, &allocator);
  return allocator;
}
```

### 设备分档策略

`preferredLargeHeapBlockSize` 可根据设备分档调整预分配块大小：

| 设备分档 | preferredLargeHeapBlockSize | 说明 |
|---------|---------------------------|------|
| low（≤8GB） | 16 MB | 低内存设备减小预分配块，避免单次占用过多 |
| medium | 32 MB | 平衡预分配效率和内存占用 |
| high（>8GB） | 64 MB | 高端设备使用更大块，最大化子分配效率 |

---

## 注意事项

- **两个优化项互补**：优化项一针对单个资源使用专用分配，优化项二优化 VMA 分配器整体预分配策略，建议同时应用
- **preferredLargeHeapBlockSize 仅影响非专用分配**：设置了 `VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT` 的资源不受此参数影响
- **两个文件都需要修改**：Impeller 后端（`allocator_vk.cc`）和 Skia 渲染路径（`flutter_skia_vma.cc`）分别有独立的 VMA 分配器实例
- **小型 Buffer 保持池化**：小于 1MB 的 Buffer 保持池化分配更高效
- **修改后需完整回归测试**：这是 Flutter 引擎层修改，需验证渲染正确性和内存表现
- **兼容性**：VMA 的 dedicated allocation 和 preferredLargeHeapBlockSize 在 Vulkan 1.0+ 即支持
- **不适用于 OpenGL 后端**：此优化仅针对 Impeller Vulkan 后端

## 验证方式

1. 修改前后使用 `hidumper --mem <PID>` 对比 native heap 和 GPU 内存占用
2. 使用 Vulkan 验证层（`VK_LAYER_KHRONOS_validation`）确认无内存警告
3. 通过 VMA 统计接口（`vmaBuildStatsString`）对比：
   - `vkAllocateMemory` 调用次数（应显著减少）
   - 大块堆利用率
   - 内存碎片率
4. 运行 Flutter_gallery 等基准测试确认渲染性能无回退
