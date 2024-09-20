//
//  ProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ProjectView: View {
    
    @ObservedObject var viewModel = ProjectViewModel()
    
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var isNotificationViewActive = false
    
    var body: some View {
        NavigationStack {
            if isLoading {
                LoadingView()
            } else {
                navigationArea
                    .padding(.bottom, 20)
                Spacer()
                ZStack {
                    if viewModel.projectList.count == 0 {
                        ProjectEmptyView(projectViewModel: viewModel)
                    } else {
                        ProjectMainView(projectViewModel: viewModel)
                    }
                }
            }
        }
        .onAppear {
            Task {
                if await viewModel.prepareData() {
                    isLoading = false
                } else {
                    showAlert = true
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
            
            Button(action: {
                isNotificationViewActive = true
            }) {
                Image(systemName: "bell")
                    .foregroundColor(.black)
            }
            .navigationDestination(isPresented: $isNotificationViewActive) {
                NotificationView()
            }
        }
        .padding(.horizontal, 16)
    }
}
