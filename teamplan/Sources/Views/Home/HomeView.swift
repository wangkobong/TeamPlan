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
    @StateObject var homeViewModel = HomeViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @AppStorage("mainViewState") var mainViewState: MainViewState?
    
    @State private var isChallenging: Bool = false
    @State private var isExistProject: Bool = false
    @State private var percent: CGFloat = 0.65
    @State private var isNotificationViewActive = false
    @State private var showingTutorial = false
    @State private var isGuideViewActive = false
    @State private var isChallengesViewActive = false
    @State private var isLoading = false
    
    @State private var showLogoutAlert = false
    
    //MARK: Main

    var body: some View {
        NavigationStack {
            ZStack {
                if !homeViewModel.isViewModelReady {
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
                            
                            MyProjectView(isProjectExist: $isExistProject, homeVM: homeViewModel)

                            MyChallengeView(homeVM: homeViewModel, isChallengeViewActive: $isChallengesViewActive)

                            Spacer()
                        }
                    }
                    .fullScreenCover(isPresented: $showingTutorial) {
                        TutorialView()
                    }
                    .onAppear {
                        homeViewModel.updateData()
                        checkProperties()
                    }
                }
            }
        }
        .onAppear {
            isExistProject = false
            Task {
                isChallenging = !homeViewModel.userData.myChallenges.isEmpty
                isExistProject = !homeViewModel.userData.projects.isEmpty
            }
        }
        // MyChallege Array Check
        .onChange(of: homeViewModel.userData.myChallenges) { newValue in
            isChallenging = !homeViewModel.userData.myChallenges.isEmpty
        }

        // HomeViewModel Exception Handling
        .onChange(of: homeViewModel.isLoginRedirectNeed) { newValue in
            if newValue {
                logout()
            }
        }
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("로그아웃"),
                message: Text("정말 로그아웃 하시겠습니까?"),
                primaryButton: .destructive(Text("로그아웃")){
                    logout()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
    }
    
    private func checkProperties() {
        pageControlCount = max(homeViewModel.userData.myChallenges.count, 1)
        Task {
            isChallenging = !homeViewModel.userData.myChallenges.isEmpty
            isExistProject = !homeViewModel.userData.projectsDTO.isEmpty
        }
    }
    
    //MARK: Function
    
    private func logout() {
        LoginService().logoutUser()
        withAnimation(.easeIn(duration: 2)) {
            mainViewState = .login
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
            
            Button {
                showLogoutAlert = true
            } label: {
                Text("로그아웃")
            }
            
            NavigationLink(destination: NotificationView().environmentObject(homeViewModel), isActive: $isNotificationViewActive) {
                Image(systemName: "bell")
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 16)
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
        HStack {
            Image("bomb")
            Spacer()
            HStack {
                NavigationLink(destination: GuideView(), isActive: $isGuideViewActive) {
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
                Image("waterdrop_side")
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

