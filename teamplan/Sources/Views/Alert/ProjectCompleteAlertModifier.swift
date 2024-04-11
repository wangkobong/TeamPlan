//
//  ProjectCompleteAlertModifier.swift
//  teamplan
//
//  Created by sungyeon kim on 4/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

public struct ProjectCompleteAlertModifier: ViewModifier {
    
    @Binding var isPresent: Bool
    
    let alert: ProjectCompleteAlertView
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresent) {
                
                alert
            }
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
    }
}
