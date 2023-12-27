//
//  ChallengesView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/09/21.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengesView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var allChallenge: [ChallengeObject]
    @Binding var myChallenges: [MyChallengeDTO]
    @State private var isPresented: Bool = false
    @State private var type: ChallengeAlertType = .lock
    @State private var currentPage = 0
    @State private var indexForAlert = 0
    
    let columns = [
      //추가 하면 할수록 화면에 보여지는 개수가 변함
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
    ]
    
    private let itemsPerPage = 12
    private var numberOfPages: Int {
        return (allChallenge.count + itemsPerPage - 1) / itemsPerPage
    }

    @State private var selectedCardIndex: Int? = nil
    
    var body: some View {
        ScrollView {
            VStack {
                
                descriptionSection
                    .padding(.bottom, 24)
                topCardSection
                    .padding(.bottom, 21)
                
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
                ChallengeAlertView(isPresented: $isPresented, allChallenge: $allChallenge, type: self.type, index: self.indexForAlert) {
                    print("클릭")
                }
            }
            .onAppear {
                allChallenge.forEach {
                    print("-------")
                    print("desc: \($0.chlg_desc)")
                    print("desc2: \($0.chlg_title)")
                    print("isSelected: \($0.chlg_selected)")
                    print("lock: \($0.chlg_lock)")
                    print("isComplete: \($0.chlg_status)")
                    print("prevGoal: \($0.chlg_goal)")
                    print("prevTitle: \($0.chlg_title)")
                }
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
            HStack {
                Text("나의 도전과제")
                    .font(.appleSDGothicNeo(.semiBold, size: 20))
                    .foregroundColor(.theme.blackColor)
                Spacer()
            }
            .padding(.leading, 16)
            
            HStack(spacing: 17) {
                
                ForEach(0..<min(3, myChallenges.count)) { index in
                    let challenge = self.myChallenges[index]
                    let screenWidth = UIScreen.main.bounds.size.width
                    ZStack {
                        if self.selectedCardIndex == index {
                            ChallengeCardBackView(challenge: challenge, parentsWidth: screenWidth)
                                .background(.white)
                                .cornerRadius(4)
                                .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: 1.0, z: 0.0))
                        } else {
                            ChallengeCardFrontView(challenge: challenge, parentsWidth: screenWidth)
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
                        }
                    }
                }
                
                if myChallenges.count < 3 {
                    // 나머지 뷰를 채우는 코드
                    ForEach(myChallenges.count..<3) { index in
                        // 다른 뷰 표시 (여기서는 기본 Text를 사용하겠습니다.)
                        ChallengeEmptyView()
                            .background(.white)
                            .cornerRadius(4)
                            .onTapGesture {
                                self.type = .willChallenge
                                self.isPresented.toggle()
                            }
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
                ForEach(0..<(allChallenge.count / 12), id: \.self) { pageIndex in
                    let startIndex = pageIndex * 12
                    let endIndex = min(startIndex + 12, allChallenge.count)
                    let pageItems = Array(allChallenge[startIndex..<endIndex])
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(pageItems.indices, id: \.self) { index in
                            let absoluteIndex = startIndex + index
                            let item = pageItems[index]
                            ChallengeDetailView(challenge: item)
                                .frame(width: 62, height: 120)
                                .onTapGesture {
                                    self.indexForAlert = absoluteIndex
                                    self.setAlert(challenge: item)
                                    print("-------")
                                    print("desc: \(item.chlg_desc)")
                                    print("desc2: \(item.chlg_title)")
                                    print("isSelected: \(item.chlg_selected)")
                                    print("lock: \(item.chlg_lock)")
                                    print("isComplete: \(item.chlg_status)")
                                    print("prevGoal: \(item.chlg_goal)")
                                    print("prevTitle: \(item.chlg_title)")
                                    self.isPresented.toggle()
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
            ForEach(0..<(allChallenge.count / 12), id: \.self) { index in
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
        if challenge.chlg_status == true && challenge.chlg_selected == false && challenge.chlg_lock == false {
            self.type = .didComplete
        // 등록된 도전과제
        } else if challenge.chlg_status == false && challenge.chlg_selected == true && challenge.chlg_lock == false {
            self.type = .didSelected
        // 도전하기
        } else if challenge.chlg_status == false && challenge.chlg_selected == false && challenge.chlg_lock == false {
            self.type = .willChallenge
        // 잠금해제 안됨
        } else if challenge.chlg_status == false && challenge.chlg_selected == false && challenge.chlg_lock == true {
            self.type = .lock
        }
    }
}
