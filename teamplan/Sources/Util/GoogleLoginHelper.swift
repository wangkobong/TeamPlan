//
//  GoogleLoginHelper.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/13.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import UIKit

final class GoogleLoginHelper{
    static let shared = GoogleLoginHelper()
    private init(){}
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        
        let controller = controller ?? primaryRootViewController()

        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
    func primaryRootViewController() -> UIViewController? {
        // Get the first window scene
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.rootViewController
        }
        return nil
    }
}
