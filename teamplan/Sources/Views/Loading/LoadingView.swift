//
//  LoadingView.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
                .opacity(0.2)
                .blur(radius: 3)
            
            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(tint: .gray)
                )
                .scaleEffect(3)
        }
        
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
