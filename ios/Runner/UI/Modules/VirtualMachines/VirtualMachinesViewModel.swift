import AppleSharedUI

/// iOS 虚拟机模块的视图模型：加载与写操作由共享包的
/// `VirtualMachineStore` 承担，这里只注入通道实现。
@MainActor
final class VirtualMachinesViewModel: VirtualMachineStore {
    init() {
        super.init(channel: IOSDataChannel(channelManager: .shared))
    }
}