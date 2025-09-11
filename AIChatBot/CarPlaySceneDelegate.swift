import UIKit
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        print("🚗 CarPlay scene connected via SceneDelegate")
        CarPlayManager.shared.interfaceController = interfaceController
        CarPlayManager.shared.setupCarPlayInterface()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController) {
        print("🚗 CarPlay scene disconnected via SceneDelegate")
        CarPlayManager.shared.interfaceController = nil
    }
}
