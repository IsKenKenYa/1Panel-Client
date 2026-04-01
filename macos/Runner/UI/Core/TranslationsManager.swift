import Foundation
import FlutterMacOS

class TranslationsManager: ObservableObject {
    static let shared = TranslationsManager()
    @Published private var translations: [String: String] = [:]
    
    private init() {}
    
    func load(completion: @escaping () -> Void) {
        ChannelManager.shared.invokeDataMethod("getTranslations") { [weak self] result in
            DispatchQueue.main.async {
                if let dict = result as? [String: String] {
                    self?.translations = dict
                } else if let dict = result as? [String: Any] {
                    var newDict: [String: String] = [:]
                    for (key, value) in dict {
                        if let strValue = value as? String {
                            newDict[key] = strValue
                        }
                    }
                    self?.translations = newDict
                }
                completion()
            }
        }
    }
    
    func get(_ key: String, fallback: String? = nil) -> String {
        return translations[key] ?? fallback ?? key
    }
}
