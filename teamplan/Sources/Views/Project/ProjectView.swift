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
    @StateObject private var notifyViewModel = NotificationViewModel()
    
    @State private var isLoading = true
    @State private var isNotifyNeed = false
    @State private var isRotating = false
    
    @State private var showAlert = false
    @State private var isNotifyViewActive = false
    @State private var isNewNotifyAdded = false
    
    var body: some View {
        NavigationStack {
            if isLoading {
                LoadingView()
            } else {
                Spacer()
                    .frame(height: 21)
                navigationArea
                    .padding(.horizontal, 10)
                    .padding(.bottom, 5)
                
                ZStack {
                    if projectViewModel.projectList.count == 0 {
                        ProjectEmptyView(projectViewModel: projectViewModel)
                    } else {
                        ProjectMainView(projectViewModel: projectViewModel)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await prepareViewModel()
            }
        }
    }
    
    private func prepareViewModel() async {
        let isProjectViewModelReady = await projectViewModel.prepareData()
        let isNotifyViewModelReady = await notifyViewModel.prepareViewModel()
        
        if isProjectViewModelReady && isNotifyViewModelReady {
            if notifyViewModel.isNewNotifyAdded {
                self.isNotifyNeed = true
            }
            isLoading = false
        } else {
            showAlert = true
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
        GeometryReader { geometry in
            HStack {
                Text("목표관리")
                    .font(.archivoBlack(.regular, size: 20))
                    .foregroundColor(.theme.mainPurpleColor)

                Spacer()
                
                Image(systemName: "bell")
                    .foregroundColor(.black)
                    .rotationEffect(isRotating ? .degrees(40) : .degrees(0))
                    .onTapGesture {
                        isNotifyViewActive = true
                    }
                    .navigationDestination(isPresented: $isNotifyViewActive) {
                        NotificationView()
                            .environmentObject(notifyViewModel)
                    }
                    .onAppear(){
                        if isNotifyNeed {
                            startRepeatingAnimation()
                        }
                    }
            }
            .padding(.horizontal, geometry.size.width * 0.05)
        }
        .frame(height: 30)
    }
    
    private func startRepeatingAnimation() {
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { timer in
            
            guard isNotifyNeed == true else {
                timer.invalidate()
                return
            }
            
            withAnimation(.linear(duration: 0.1).repeatCount(50, autoreverses: true)) {
                isRotating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation{ isRotating = false }
            }
        }
    }
}
