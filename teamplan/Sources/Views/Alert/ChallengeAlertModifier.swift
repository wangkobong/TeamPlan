//
//  ChallengeALertModifier.swift
//  teamplan
//
//  Created by sungyeon on 2023/12/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

public struct ChallengeAlertModifier: ViewModifier {
    
    @Binding var isPresent: Bool
    
    let alert: ChallengeAlertView
    
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
