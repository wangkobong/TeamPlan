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
        // get topViewController in a recursive way from the view controller hierarchy
        return findTopViewController(from: rootViewController)
    }

    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return findTopViewController(from: presentedViewController)
        } else if let navigationController = viewController as? UINavigationController,
                  let visibleViewController = navigationController.visibleViewController {
            return findTopViewController(from: visibleViewController)
        } else if let tabBarController = viewController as? UITabBarController,
                  let selectedViewController = tabBarController.selectedViewController {
            return findTopViewController(from: selectedViewController)
        }
        return viewController
    }
}
