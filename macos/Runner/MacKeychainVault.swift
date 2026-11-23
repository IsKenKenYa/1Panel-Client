import Cocoa
import FlutterMacOS
import Security

/// macOS 凭据钥匙串通道。
///
/// flutter_secure_storage 的 macOS 选项默认启用数据保护钥匙串，而本地与
/// ad-hoc 签名的发行包拿不到匹配的钥匙串访问组，写入会返回
/// errSecMissingEntitlement。这里直接用 SecItem API 操作传统登录钥匙串，
/// 门禁与开发构建因此不依赖团队签名。
final class MacKeychainVault {
  static let channelName = "onepanel/secure_storage"
  static let service = "com.iskenkenya.onepanel.credentials"
  /// flutter_secure_storage 的默认服务名；升级前的条目都记在它下面。
  private static let legacyServices = ["flutter_secure_storage_service"]

  static func setup(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      let arguments = call.arguments as? [String: Any] ?? [:]
      let key = arguments["key"] as? String ?? ""
      switch call.method {
      case "read":
        guard !key.isEmpty else {
          result(FlutterError(code: "invalid_key", message: "Key is required", details: nil))
          return
        }
        result(readWithLegacyFallback(key))
      case "write":
        guard !key.isEmpty, let value = arguments["value"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "Key and value are required", details: nil))
          return
        }
        do {
          try write(key, value: value)
          result(true)
        } catch {
          result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        }
      case "delete":
        guard !key.isEmpty else {
          result(FlutterError(code: "invalid_key", message: "Key is required", details: nil))
          return
        }
        do {
          try delete(key)
          try deleteLegacy(key)
          result(true)
        } catch {
          result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil))
        }
      case "deleteAll":
        do {
          try deleteAll()
          result(true)
        } catch {
          result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func baseQuery(
    _ key: String,
    service: String = MacKeychainVault.service
  ) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
  }

  static func read(_ key: String) -> String? {
    read(key, service: service)
  }

  private static func read(_ key: String, service: String) -> String? {
    var query = baseQuery(key, service: service)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data
    else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  /// 读取时回退到 flutter_secure_storage 的旧服务名，升级用户无需重新录入密钥。
  static func readWithLegacyFallback(_ key: String) -> String? {
    if let value = read(key) { return value }
    for service in legacyServices {
      if let value = read(key, service: service) { return value }
    }
    return nil
  }

  /// 删除旧服务名下的同名条目，避免凭据删除后残留。
  static func deleteLegacy(_ key: String) throws {
    for service in legacyServices {
      let status = SecItemDelete(baseQuery(key, service: service) as CFDictionary)
      guard status == errSecSuccess || status == errSecItemNotFound else {
        throw MacKeychainError.status(status)
      }
    }
  }

  static func write(_ key: String, value: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw MacKeychainError.encodingFailed
    }
    let query = baseQuery(key)
    let attributes: [String: Any] = [kSecValueData as String: data]
    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecSuccess { return }
    guard updateStatus == errSecItemNotFound else {
      throw MacKeychainError.status(updateStatus)
    }
    var insert = query
    insert[kSecValueData as String] = data
    insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    let addStatus = SecItemAdd(insert as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw MacKeychainError.status(addStatus)
    }
  }

  static func delete(_ key: String) throws {
    let status = SecItemDelete(baseQuery(key) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw MacKeychainError.status(status)
    }
  }

  static func deleteAll() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw MacKeychainError.status(status)
    }
  }
}

enum MacKeychainError: LocalizedError {
  case encodingFailed
  case status(OSStatus)

  var errorDescription: String? {
    switch self {
    case .encodingFailed:
      return "Unable to encode credential value"
    case .status(let status):
      let message = SecCopyErrorMessageString(status, nil) as String? ?? ""
      return "Keychain error \(status): \(message)"
    }
  }
}