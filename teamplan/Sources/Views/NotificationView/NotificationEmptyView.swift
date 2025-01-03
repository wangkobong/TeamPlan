//
//  NotificationEmptyView.swift
//  투두팡
//
//  Created by sungyeon kim on 9/6/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct NotificationEmptyView: View {
    var body: some View {
        VStack {
            
            Spacer()
            
            Image("project_empty")
                .padding(.bottom, 10)
            
            HStack {
                Text("알림이")
                    .font(.appleSDGothicNeo(.regular, size: 16))
                    .foregroundColor(.theme.blackColor)
                Text("텅!")
                    .font(.appleSDGothicNeo(.semiBold, size: 18))
                    .foregroundColor(.theme.mainPurpleColor)
                Text("비었어요")
                    .font(.appleSDGothicNeo(.regular, size: 16))
                    .foregroundColor(.theme.blackColor)
            }
            .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

#Preview {
    NotificationEmptyView()
}
