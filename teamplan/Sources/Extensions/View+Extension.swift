//
//  View+Extension.swift
//  teamplan
//
//  Created by sungyeon on 2023/12/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

extension View {
    public func challengeAlert(isPresented: Binding<Bool>, challengeAlert: @escaping () -> ChallengeAlertView) -> some View {
        return modifier(ChallengeAlertModifier(isPresent: isPresented, alert: challengeAlert()))
    }
    
    public func projectCompleteAlert(isPresented: Binding<Bool>, projectCompleteAlert: @escaping () -> ProjectCompleteAlertView) -> some View {
        return modifier(ProjectCompleteAlertModifier(isPresent: isPresented, alert: projectCompleteAlert()))
    }
}

struct ClearBackground: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> UIView {
        
        let view = ClearBackgroundView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}

class ClearBackgroundView: UIView {
    open override func layoutSubviews() {
        guard let parentView = superview?.superview else {
            return
        }
        parentView.backgroundColor = .clear
    }
}
