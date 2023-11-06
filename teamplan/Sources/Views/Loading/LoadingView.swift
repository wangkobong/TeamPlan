//
//  LoadingView2.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct LoadingView<Content>: View where Content: View {

    @Binding var isShowing: Bool
    var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {

                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)

                ActivityIndicator(isAnimating: .constant(true), style: .large)
                    .opacity(self.isShowing ? 1 : 0)
//                VStack {
//                    Text("Loading...")
//
//                }
//                .frame(width: geometry.size.width / 2,
//                       height: geometry.size.height / 5)
//                .background(Color.secondary.colorInvert())
//                .foregroundColor(Color.primary)
//                .cornerRadius(20)
                

            }
        }
    }

}
