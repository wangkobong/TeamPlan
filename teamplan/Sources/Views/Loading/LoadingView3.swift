//
//  LoadingView.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct LoadingView2: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(tint: .red)
                )
                .scaleEffect(3)
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView2()
    }
}
