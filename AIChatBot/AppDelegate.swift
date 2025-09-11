import UIKit
import CarPlay

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🚗 AppDelegate: Application did finish launching")
        print("🚗 AppDelegate: Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("🚗 AppDelegate: CarPlay categories: \(Bundle.main.object(forInfoDictionaryKey: "CPSupportedCarPlayCategories") ?? "none")")
        
        // Check if CarPlay is available
        if #available(iOS 12.0, *) {
            print("🚗 AppDelegate: CarPlay framework available")
        }
        
        // Initialize CarPlay manager
        CarPlayManager.shared.setup()
        
        return true
    }
    
    // MARK: - CarPlay Scene Configuration
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        print("🚗 AppDelegate: Scene connecting with role: \(connectingSceneSession.role.rawValue)")
        
        if connectingSceneSession.role == UISceneSession.Role.carTemplateApplication {
            print("🚗 AppDelegate: ✅ Configuring CarPlay scene!")
            let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
            config.delegateClass = CarPlaySceneDelegate.self
            print("🚗 AppDelegate: CarPlay scene delegate set to: \(String(describing: config.delegateClass))")
            return config
        } else {
            print("🚗 AppDelegate: Configuring regular app scene")
        }
        
        // Default configuration for main app scenes
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        return config
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("🚗 AppDelegate: Scene sessions discarded: \(sceneSessions.count)")
    }
}
