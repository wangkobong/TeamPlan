//
//  HomeView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/07/30.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI
import KeychainSwift

struct HomeView: View {
    
    //MARK: Properties
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    
    @AppStorage("mainViewState") var mainViewState: MainViewState?
    
    @State private var percent: CGFloat = 0.65
    @State private var showingTutorial = false
    @State private var showAlert = false
    
    @State private var isChallenging: Bool = false
    @State private var isExistProject: Bool = false
    @State private var isNotificationViewActive = false
    @State private var isGuideViewActive = false
    @State private var isChallengesViewActive = false
    @State private var isRedirecting: Bool = false
    
    @State private var isLoading = true
    @State private var isNotifyNeed = true
    @State private var isRotating = false
    @State private var showLoadAlert = false
    @State private var showUpdateAlert = false
    //MARK: Main

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    LoadingView()
                } else {
                    VStack {
                        Spacer()
                            .frame(height: 21)
                        navigationArea
                            .padding(.horizontal, 30)
                            .padding(.bottom, 5)
                        
                        ScrollView {
                            guideArea
                            userNameArea
                                .padding(.top, 26)
                            
                            MyProjectView(homeVM: homeViewModel, projectVM: projectViewModel, isProjectExist: $isExistProject)

                            MyChallengeView(homeVM: homeViewModel, isChallengeViewActive: $isChallengesViewActive)

                            Spacer()
                        }
                    }
                    .fullScreenCover(isPresented: $showingTutorial) {
                        TutorialView()
                    }
                    .onAppear {
                        Task {
                            if await homeViewModel.updateData() {
                                checkProperties()
                            } else {
                                showUpdateAlert = true
                            }
                        }
                    }
                    .alert(isPresented: $showUpdateAlert) {
                        Alert(
                            title: Text("Error"), 
                            message: Text("Failed to update data"), 
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
        }
        .onAppear {
            Task {
                let isHomeViewModelReady = await homeViewModel.prepareData()
                let isProjectrViewModelReady = await projectViewModel.prepareData()
                
                if isHomeViewModelReady && isProjectrViewModelReady {
                    isLoading = false
                } else {
                    showLoadAlert = true
                    isRedirecting = true
                }
            }
        }
        .alert(isPresented: $showLoadAlert) {
            Alert(title: Text("Error"), message: Text("Failed to load data"), dismissButton: .default(Text("OK")))
        }
    }
    
    private func checkProperties() {
        Task {
            isChallenging = !homeViewModel.userData.myChallenges.isEmpty
            isExistProject = !homeViewModel.userData.projectsDTOs.isEmpty
        }
    }
}

extension HomeView {
    
    //MARK: Navi: Area
    private var navigationArea: some View {
        HStack {
            Image("title_home")
                .frame(width: 61, height: 27)
                .padding(.leading, -10)
            Spacer()
            
            Image(systemName: "bell")
                .foregroundColor(.black)
                .rotationEffect(isRotating ? .degrees(30) : .degrees(0))
                .onTapGesture {
                    isNotificationViewActive = true
                }
                .navigationDestination(isPresented: $isNotificationViewActive) {
                    NotificationView()
                }
                .onAppear(){
                    startRepeatingAnimation()
                }
        }
        .padding(.horizontal, 16)
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
                withAnimation{
                    isRotating = false
                }
            }
        }
    }
    
    //MARK: Guide: Area
    private var guideArea: some View {
        VStack {
            guideTitle
            Spacer()
            ZStack {
                guideBackground
                guideOverlay
            }
        }
        .frame(height: 120)
        .background(Color(red: 0.92, green: 0.91, blue: 0.95))
        .padding(.horizontal, 16)
    }
    
    //MARK: Guide: Title
    private var guideTitle: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("투두팡 사용법")
                    .font(.appleSDGothicNeo(.bold, size: 16))
                    .foregroundColor(.theme.mainPurpleColor)
                Text("투두팡 사용이 어려우신가요? 핵심만 정리된 가이드북 읽어보세요 !")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.theme.blackColor)
            }
            .padding(.horizontal, 14)
            Spacer()
        }
        .padding(.top, 15)
    }
    
    //MARK: Guide: Background
    private var guideBackground: some View {
        VStack {
            Spacer()
                .frame(width: 390, height: 42)
                .background(Color.clear)
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 390, height: 6)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.64, green: 0.6, blue: 0.83).opacity(0.7), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.61, green: 0.9, blue: 1).opacity(0.7), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0, y: 1),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                )
        }
        .frame(height: 48)
    }
    
    //MARK: Guide: Overlay
    private var guideOverlay: some View {
        NavigationStack {
            HStack {
                Image("bomb")
                Spacer()
                HStack {
                    Text("읽으러 가기")
                        .font(.appleSDGothicNeo(.bold, size: 12))
                        .foregroundColor(.theme.whiteColor)
                        .padding(.trailing, -6)
                    Image("chevron_right")
                        .frame(width: 14, height: 12)
                }
                .frame(width: 111, height: 28)
                .background(Color.theme.mainPurpleColor)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.trailing, -7)
                .padding(.bottom, 10)
                .onTapGesture {
                    isGuideViewActive = true
                }
                Image("waterdrop_side")
            }
            .navigationDestination(isPresented: $isGuideViewActive) {
                GuideView()
            }
        }
    }
    
    //MARK: userName: Area
    private var userNameArea: some View {
        VStack(alignment: .leading) {
            userNameSection
            pharseSection
        }
        .padding(.leading, 16)
        .padding(.horizontal, 16)
    }
    
    //MARK: userName: Name
    private var userNameSection: some View {
        HStack {
            Text("\(homeViewModel.userData.userName)" + "님,")
                .font(.appleSDGothicNeo(.bold, size: 20))
                .foregroundColor(.theme.blackColor)
                .background(
                    Color.init(hex: "7248E1").opacity(0.5)
                        .frame(height: 3) // underline's height
                        .offset(y: 7) // underline's y pos
                )
            Spacer()
        }
    }
    
    //MARK: userName: pharse
    private var pharseSection: some View {
        HStack {
            Text("\(homeViewModel.userData.phrase)")
                .font(.appleSDGothicNeo(.bold, size: 20))
                .foregroundColor(.theme.blackColor)
            Spacer()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

