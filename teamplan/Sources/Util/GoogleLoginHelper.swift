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
    func topViewController() -> UIViewController? {
        // get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController
        else {
            return nil
        }
        // get topViewController through the view controller hierarchy
        var topController = rootViewController
        while true {
            if let presented = topController.presentedViewController {
                topController = presented
            } else if
                let navigationController = topController as? UINavigationController,
                let visibleViewController = navigationController.visibleViewController {
                topController = visibleViewController
            } else if
                let tabBarController = topController as? UITabBarController,
                let selectedViewController = tabBarController.selectedViewController {
                topController = selectedViewController
            } else {
                break
            }
        }
        return topController
    }

}
