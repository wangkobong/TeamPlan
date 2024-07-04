//
//  TopViewFinder.swift
//  teamplan
//
//  Created by 크로스벨 on 6/25/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import UIKit
import SwiftUI
import Foundation

final class TopViewManager {
    static let shared = TopViewManager()
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
    
    @MainActor
    func redirectToLoginView(title: String,  message: String) async {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let window = windowScene.windows.first
        else {
            return
        }
        
        let viewModel = AuthenticationViewModel()
        let loginView = LoginView()
            .environmentObject(viewModel)
        let hostingController = UIHostingController(rootView: loginView)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        hostingController.present(alert, animated: true, completion: nil)
    }
}
