//
//  ProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ProjectView: View {
    
    @ObservedObject var projectViewModel = ProjectViewModel()
    @State private var isNotificationViewActive = false
    private var isEmpty = false
    
    var body: some View {
        if !projectViewModel.isViewModelReady {
            LoadingView()
        } else {
            NavigationStack {
                navigationArea
                    .padding(.bottom, 20)
                Spacer()
                ZStack {
                    if projectViewModel.projectList.count == 0 {
                        ProjectEmptyView(projectViewModel: projectViewModel)
                    } else {
                        ProjectMainView(projectViewModel: projectViewModel)
                    }
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
            Text("목표관리")
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
