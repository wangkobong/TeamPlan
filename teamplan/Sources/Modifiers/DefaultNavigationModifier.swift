//
//  DefaultNavigationModifier.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct DefaultNavigationModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitle("", displayMode: .automatic)
            .navigationBarHidden(true)
    }
}

extension View {
    
    func defaultNavigationMFormatting() -> some View {
        self
            .modifier(DefaultNavigationModifier())
    }
}
