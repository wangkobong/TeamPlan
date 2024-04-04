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
    
    private let challengeCardsExample: [ChallengeCardModel] = [
        ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "프로젝트 완주", description: "프로젝트 한개 완주"),
        ChallengeCardModel(image: "applelogo", title: "화이팅!", description: "물방울 10개 모으기")
    ]
    
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
    @State private var pageControlCount = 1
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                        .frame(height: 21)
                    navigationArea
                        .padding(.horizontal, 30)
                        .padding(.bottom, 5)
                    
                    ScrollView {
                        guideArea
                        
                        userNameArea
                            .padding(.top, 40)

                        if isExistProject {
                            myProjectCardView
                                .padding(.horizontal, 16)
                        } else {
                            noProjectView
                                .padding(.horizontal, 16)
                        }
                            
                        pageControl
                            .padding(.top, 12)
                        
                        myChallengeArea
                            .padding(.top, 20)
                        
                        challengeCardsArea

                        Spacer()
                    }

                }
                .fullScreenCover(isPresented: $showingTutorial) {
                    TutorialView()
                }
                
                if isLoading {
                    LoadingView()
                }
            }
        }
        .onAppear {
            isExistProject = false
            pageControlCount = max(homeViewModel.myChallenges.count, 1)
            homeViewModel.configureData()
            isChallenging = !homeViewModel.myChallenges.isEmpty
        }
        .onChange(of: homeViewModel.myChallenges) { newValue in
            isChallenging = !homeViewModel.myChallenges.isEmpty
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

extension HomeView {
    private var navigationArea: some View {
        HStack {
            Image("title_home")
                .frame(width: 61, height: 27)
                .padding(.leading, -10)
            Spacer()
            
            Button {
                do {
                    let google = AuthGoogleService()
                    try google.logout()
                    withAnimation(.easeIn(duration: 10)) {
                        mainViewState = .login
                    }
                } catch {
                    print(error)
                }
            } label: {
                Text("로그아웃")
            }

            NavigationLink(destination: NotificationView(), isActive: $isNotificationViewActive) {
                Image(systemName: "bell")
                    .foregroundColor(.black)
            }
        }
    }
    
    private var guideArea: some View {
        VStack {
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
            Spacer()
            ZStack {
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
                .overlay {
                    HStack {
                        Image("bomb")
                        Spacer()
                        HStack {
                            NavigationLink(destination: GuideView(), isActive: $isGuideViewActive) {
                                Text("읽으러 가기")
                            }
                                .font(.appleSDGothicNeo(.bold, size: 12))
                                .foregroundColor(.theme.whiteColor)
                                .padding(.trailing, -6)
                            Image("chevron_right")
                                .frame(width: 14, height: 12)
                        }
                        .foregroundColor(.clear)
                        .frame(width: 111, height: 28)
                        .background(Color.theme.mainPurpleColor)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
                        .padding(.trailing, -7)
                        .padding(.bottom, 10)
                        .onTapGesture {
//                            showingTutorial.toggle()
                        }

                        Image("waterdrop_side")
                    }
                }


            }
        }
        .frame(height: 120)
        .background(Color(red: 0.92, green: 0.91, blue: 0.95))
    }
    
    private var userNameArea: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(homeViewModel.userName)" + "님,    ")
                    .font(.appleSDGothicNeo(.bold, size: 20))
                    .foregroundColor(.theme.blackColor)
                    .background(
                        Color.init(hex: "7248E1").opacity(0.5)
                            .frame(height: 3) // underline's height
                            .offset(y: 7) // underline's y pos
                    )
                Spacer()
            }
            HStack {
                Text("오늘도 목표를 향해 달려볼까요?")
                    .font(.appleSDGothicNeo(.bold, size: 20))
                    .foregroundColor(.theme.blackColor)
                Spacer()
            }
        }
        .padding(.leading, 16)
    }
    
    private var noProjectView: some View {
        VStack {
            Image("warning_circle")
                .frame(width: 32, height: 32)
                .padding(.bottom, 5)
            Text("프로젝트를 먼저 생성해주세요")
                .font(.appleSDGothicNeo(.regular, size: 16))
                .padding(.bottom, 22)
            Text("프로젝트 생성하기")
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.theme.whiteColor)
                .frame(width: 111, height: 28)
                .background(Color.theme.mainPurpleColor)
                .cornerRadius(4)
                .onTapGesture {
                    print("프로젝트 생성하기 클릭")
                }
        }
        .frame(height: 176)
        .frame(maxWidth: .infinity)
        .clipped()
        .background(
            Rectangle()
              .foregroundColor(.clear)
              .frame(width: 358, height: 176)
              .background(.white)
              .cornerRadius(8)
              .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
        )
    }
    
    private var myProjectCardView: some View {
        VStack {
            VStack {
                HStack {
                    Text("마감기한이 다가오고 있어요!")
                        .foregroundColor(.theme.mainPurpleColor)
                        .font(.appleSDGothicNeo(.regular, size: 12))
                    Spacer()
                }
                
                HStack {
                    Text("프로젝트 1")
                        .font(.appleSDGothicNeo(.bold, size: 18))
                        .foregroundColor(.black)
                    Spacer()
                    HStack {
                        Image("waterdrop")
                            .frame(width: 18, height: 14)
                        Text("10")
                            .font(.appleSDGothicNeo(.semiBold, size: 18))
                        Text("개")
                            .font(.appleSDGothicNeo(.regular, size: 12))
                            .padding(.leading, -5)
                    }
                }
                
                HStack {
                    Text("총 3개의 TODO가 남아있어요")
                        .font(.appleSDGothicNeo(.regular, size: 12))
                        .foregroundColor(.black)
                    Spacer()
                }
                
                Spacer()
                    .frame(height: 35)
                
                // 프로그레스 바
                let width = UIScreen.main.bounds.width - 16 - 16 - 17 - 17
                ZStack(alignment: .leading) {
                    
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .fill(.black.opacity(0.08))
                            .frame(width: width, height: 8)
                    }
                    ZStack {
                        HStack {
                            Capsule()
                                .fill(Color.theme.mainPurpleColor)
                                .frame(width: calPercent(), height: 8)
                            Image("bomb_smile")
                                .padding(.leading, -12)
                        }
                    }
                }
                .frame(height: 10)
                
                HStack {
                    Text("START")
                        .font(.appleSDGothicNeo(.regular, size: 12))
                        .foregroundColor(.theme.greyColor)
                    Spacer()
                    Text("D-10")
                        .font(.appleSDGothicNeo(.regular, size: 12))
                        .foregroundColor(.theme.blackColor)
                }
                Spacer()
                    .frame(height: 10)
                
                HStack {
                    Spacer()
                    HStack {
                        Text("23.02.20")
                        Text("-")
                        Text("23.08.23")
                    }
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 17)
            
        }
        .frame(height: 176)
        .frame(maxWidth: .infinity)
        .clipped()
        .background(
            Rectangle()
              .foregroundColor(.clear)
              .frame(width: 358, height: 176)
              .background(.white)
              .cornerRadius(8)
              .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
        )
    }
    
    private var pageControl: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageControlCount, id: \.self) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(index == 0 ? .theme.mainBlueColor : Color.init(hex: "D9D9D9"))
            }
        }
        .frame(height: 6)
    }
    
    private var myChallengeArea: some View {
        HStack {
            Text("나의 도전과제")
                .font(.appleSDGothicNeo(.semiBold, size: 20))
            
            Spacer()
            
            HStack {
                NavigationLink(destination: ChallengesView(
                    homeViewModel: homeViewModel),
                               isActive: $isChallengesViewActive) {
                    Text("전체보기")
                }
                Image("right_arrow_home")
                    .frame(width: 15, height: 15)
                    .padding(.leading, -5)
                    .padding(.bottom, 2)
            }
            .font(.appleSDGothicNeo(.regular, size: 12))
            .onTapGesture {
                
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var challengeCardsArea: some View {
        ZStack {
            HStack(spacing: 17) {
                
                ForEach(0..<$homeViewModel.myChallenges.count, id: \.self) { index in
                    let challenge = self.$homeViewModel.myChallenges[index]
                    let screenWidth = UIScreen.main.bounds.size.width
                    ZStack {
                        ChallengeCardFrontView(challenge: challenge.wrappedValue, parentsWidth: screenWidth)
                            .background(.white)
                            .cornerRadius(4)
                    }
                }
                
                if $homeViewModel.myChallenges.count < 3 {
                    // 나머지 뷰를 채우는 코드
                    ForEach($homeViewModel.myChallenges.count..<3, id: \.self) { index in
                        // 다른 뷰 표시 (여기서는 기본 Text를 사용하겠습니다.)
                        ChallengeEmptyView()
                            .background(.white)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)

            
            VStack {
                HStack {
                    Image("waterdrop_reverse")
                    Spacer()
                    Image("waterdrop")
                }
                .padding(.horizontal, 60)
                Text("도전과제에 도전하여 물방울을 모아보세요!")
                    .font(.appleSDGothicNeo(.regular, size: 16))
                    .foregroundColor(Color(hex: "3B3B3B"))
                Text("도전하기")
                    .font(.appleSDGothicNeo(.semiBold, size: 12))
                    .foregroundColor(.white)
                    .frame(width: 70, height: 28)
                    .background(Color(red: 0.51, green: 0.87, blue: 1))
                    .cornerRadius(4)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
                    .overlay(
                    RoundedRectangle(cornerRadius: 4)
                    .inset(by: 0.5)
                    .stroke(Color(red: 0.51, green: 0.87, blue: 1), lineWidth: 1)
                    )
                    
            }
            .frame(maxWidth: .infinity, maxHeight: 144)
            .background(.white.opacity(0.8))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
            .opacity(isChallenging ? 0 : 1)
        }
    }
    
    private func calPercent() -> CGFloat {
        let width = UIScreen.main.bounds.width - 18 - 18
        return width * percent
    }
}

