//
//  ChallengesView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/09/21.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengesView: View {
    
    @ObservedObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isPresented: Bool = false
    @State private var type: ChallengeAlertType = .lock
    @State private var currentPage = 0
    @State private var indexForAlert = 0
    @State private var selectedCardIndex: Int? = nil
    @State private var toast: Toast? = nil
    
    let columns = [
      //추가 하면 할수록 화면에 보여지는 개수가 변함
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
    ]
    
    private let itemsPerPage = 12
    private var numberOfPages: Int {
        return ($homeViewModel.challengeArray.count + itemsPerPage - 1) / itemsPerPage
    }
    
    var body: some View {
        ScrollView {
            VStack {
                
                descriptionSection
                    .padding(.bottom, 24)
                topCardSection
                    .padding(.bottom, 21)
                    .onChange(of: homeViewModel.challengeArray) { _ in
                        withAnimation(.linear) {
                            selectedCardIndex = nil
                        }
                    }
                    .onChange(of: homeViewModel.myChallenges) { _ in
                        withAnimation(.linear) {
                            selectedCardIndex = nil
                        }
                    }
                
                gridSection
                Spacer()
                pageControl
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("도전과제")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss.callAsFunction()
                    } label: {
                        Image("left_arrow_home")
                    }
                }
            }
            .challengeAlert(isPresented: $isPresented) {
                ChallengeAlertView(isPresented: $isPresented, allChallenge: $homeViewModel.challengeArray, challenge: $homeViewModel.challengeArray[self.indexForAlert], type: self.type, index: self.indexForAlert) {
                    switch type {
                    case .didComplete:
                        break
                    case .didSelected:
                        break
                    case .willChallenge:
                        self.type = .didChallenge
                        self.isPresented = true
                        homeViewModel.tryChallenge(with: $homeViewModel.challengeArray[self.indexForAlert].challengeId.wrappedValue)
                    case .lock:
                        break
                    case .quit:
                        homeViewModel.quitChallenge(with: $homeViewModel.myChallenges[selectedCardIndex ?? 0].challengeID.wrappedValue)
                    case .didChallenge:
                        break
                    }
                }
            }
            .toastView(toast: $toast)
            .onAppear {
                homeViewModel.challengeArray.forEach {
                    print("-------")
                    print("desc: \($0.desc)")
                    print("id: \($0.challengeId)")
                    print("desc2: \($0.title)")
                    print("isSelected: \($0.selectStatus)")
                    print("lock: \($0.lock)")
                    print("isComplete: \($0.status)")
                    print("prevGoal: \($0.goal)")
                    print("prevTitle: \($0.title)")
                    
                }
                print("$homeViewModel.challengeArray: \($homeViewModel.challengeArray.count)")
            }
        }
    }
}

//struct ChallengesView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengesView()
//    }
//}

extension ChallengesView {
    
    private var descriptionSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("도전과제에 하나씩 도전해보세요!")
                    .font(.appleSDGothicNeo(.bold, size: 17))
                    .foregroundColor(.theme.darkGreyColor)
                Spacer()
            }
            
            HStack {
                Text("도전과제는 '나의 도전과제'에 등록한 시점부터 수치가 계산됩니다.")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.theme.darkGreyColor)
                Spacer()
            }
        
        }
        .padding(.leading, 16)
        .padding(.top, 14)
    }
    
    private var topCardSection: some View {
        
        
        VStack {
           let _ = Self._printChanges()
            HStack {
                Text("나의 도전과제")
                    .font(.appleSDGothicNeo(.semiBold, size: 20))
                    .foregroundColor(.theme.blackColor)
                Spacer()
            }
            .padding(.leading, 16)
            
            HStack(spacing: 17) {
                
                ForEach(0..<$homeViewModel.myChallenges.count, id: \.self) { index in
                    let challenge = self.$homeViewModel.myChallenges[index]
                    let screenWidth = UIScreen.main.bounds.size.width
                    ZStack {
                        if self.selectedCardIndex == index {
                            ChallengeCardBackView(homeViewModel: homeViewModel, challenge: challenge.wrappedValue, parentsWidth: screenWidth, isPresented: $isPresented, type: $type)
                                .background(.white)
                                .cornerRadius(4)
                                .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: 1.0, z: 0.0))
                        } else {
                            ChallengeCardFrontView(challenge: challenge.wrappedValue, parentsWidth: screenWidth)
                                .background(.white)
                                .cornerRadius(4)
                        }
                    }
                    .rotation3DEffect(
                        .degrees(self.selectedCardIndex == index ? 180 : 0),
                        axis: (x: 0.0, y: 1.0, z: 0.0)
                    )
                    .onTapGesture {
                        withAnimation(.linear) {
                            self.selectedCardIndex = (self.selectedCardIndex == index) ? nil : index
                            if let index = homeViewModel.challengeArray.firstIndex(where: { $0.challengeId == self.homeViewModel.myChallenges[index].challengeID }) {
                                // index를 사용하여 작업 수행
                                print("해당 요소의 인덱스: \(index)")
                                self.indexForAlert = index
                            } else {
                                // 배열에서 조건을 만족하는 요소를 찾지 못한 경우에 대한 처리
                                print("해당하는 요소가 없습니다.")
                            }
                        }
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

        }
    }
    private var gridSection: some View {
        
        VStack {
            HStack {
                Text("모든 도전과제")
                    .font(.appleSDGothicNeo(.semiBold, size: 20))
                    .foregroundColor(.theme.blackColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            TabView(selection: $currentPage) {
                ForEach(0..<($homeViewModel.challengeArray.count / 12), id: \.self) { pageIndex in
                    let startIndex = pageIndex * 12
                    let endIndex = min(startIndex + 12, $homeViewModel.challengeArray.count)
                    let pageItems = Array($homeViewModel.challengeArray[startIndex..<endIndex])
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(pageItems.indices, id: \.self) { index in
                            let absoluteIndex = startIndex + index
                            let item = pageItems[index]
                            ChallengeDetailView(challenge: item.wrappedValue)
                                .frame(width: 62, height: 120)
                                .onTapGesture {
                                    self.indexForAlert = absoluteIndex
                                    self.setAlert(challenge: item.wrappedValue)
//                                    print("-------")
//                                    print("desc: \(item.wrappedValue.chlg_desc)")
//                                    print("desc2: \(item.wrappedValue.chlg_title)")
//                                    print("isSelected: \(item.wrappedValue.chlg_selected)")
//                                    print("lock: \(item.wrappedValue.chlg_lock)")
//                                    print("isComplete: \(item.wrappedValue.chlg_status)")
//                                    print("prevGoal: \(item.wrappedValue.chlg_goal)")
//                                    print("prevTitle: \(item.wrappedValue.chlg_title)")
                                }
                        }
                    }
                    .tag(pageIndex)
                    
                }
            }
            .frame(height: 380)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

        }
    }
    
    private var pageControl: some View {
        HStack(spacing: 10) {
            ForEach(0..<($homeViewModel.challengeArray.count / 12), id: \.self) { index in
                if index == currentPage {
                    Circle()
                        .frame(width: 9, height: 9)
                        .foregroundColor(.theme.mainPurpleColor)
                } else {
                    Circle()
                        .frame(width: 9, height: 9)
                        .foregroundColor(.init(hex: "D9D9D9"))
                }
            }
        }
        .padding(.bottom, 24)
    }
}

extension ChallengesView {
    private func setAlert(challenge: ChallengeObject) {
        
        // 완료한 도전과제
        if challenge.status == true && challenge.selectStatus == false && challenge.lock == false {
            self.type = .didComplete
            self.isPresented.toggle()
        // 등록된 도전과제
        } else if challenge.status == false && challenge.selectStatus == true && challenge.lock == false {
            self.type = .didSelected
            self.isPresented.toggle()
        // 도전하기
        } else if challenge.status == false && challenge.selectStatus == false && challenge.lock == false {
            if homeViewModel.myChallenges.count == 3 {
                toast = Toast(style: .error, message: "나의 도전과제는 3개까지만 등록이 가능합니다.", width: 300)
            } else {
                self.type = .willChallenge
                self.isPresented.toggle()
            }
        // 잠금해제 안됨
        } else if challenge.status == false && challenge.selectStatus == false && challenge.lock == true {
            self.type = .lock
            self.isPresented.toggle()
        }
    }
}
