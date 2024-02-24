//
//  ProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ProjectView: View {
    
    @State private var isNotificationViewActive = false
    private var isEmpty = false
    
    var body: some View {
        NavigationStack {
            navigationArea
                .padding(.bottom, 20)
            Spacer()
            ZStack {
                if isEmpty {
                    ProjectEmptyView()
                } else {
                    ProjectMainView()
                }
            }
        }
    }
}

struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectView()
    }
}

extension ProjectView {
    private var navigationArea: some View {
        HStack {
            Text("프로젝트")
                .font(.archivoBlack(.regular, size: 20))
                .foregroundColor(.theme.mainPurpleColor)
            Spacer()
            NavigationLink(destination: NotificationView(), isActive: $isNotificationViewActive) {
                Image(systemName: "bell")
                    .foregroundColor(.black)
            }
            
        }
        .padding(.horizontal, 16)

    }
}
