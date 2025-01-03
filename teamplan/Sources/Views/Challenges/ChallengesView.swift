//
//  ChallengesView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/09/21.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengesView: View {
    
    @StateObject var viewModel = ChallengeViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var isPresented: Bool = false
    @State private var isLoading: Bool = true
    @State private var showInitAlert: Bool = false
    
    @State private var type: ChallengeAlertType = .lock
    @State private var currentPage = 0
    @State private var indexForAlert = 0
    @State private var selectedCardIndex: Int? = nil
    @State private var toast: Toast? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
        GridItem(.adaptive(minimum: 57)),
    ]
    
    private let itemsPerPage = 12
    private var numberOfPages: Int {
        return ($viewModel.challengeList.count + itemsPerPage - 1) / itemsPerPage
    }
    
    //MARK: Main
    
    var body: some View {
        ScrollView {
            if isLoading {
                LoadingView()
            } else {
                VStack {
                    descriptionSection
                    topCardSection
                    gridSection
                    Spacer()
                    pageControl
                }
                .navigationBarBackButtonHidden(true)
                .navigationTitle("도전과제")
                .toolbar {
                    toolbarContent
                }
                .challengeAlert(isPresented: $isPresented) {
                    challengeAlertView
                }
                .toastView(toast: $toast)
            }
        }
        .onAppear{
            handleOnAppear()
        }
        .alert(isPresented: $showInitAlert) {
            Alert(title: Text("너무 빨랐습니다!"), message: Text("도전과제 기능을 준비중입니다! 잠시후 다시 시도해주세요"), dismissButton: .default(Text("OK")))
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                dismiss.callAsFunction()
            } label: {
                Image("left_arrow_home")
            }
        }
    }
    
    private var challengeAlertView: ChallengeAlertView {
        let challengeIndex =  indexForAlert
        let challenge = $viewModel.challengeList[indexForAlert]
        
        return ChallengeAlertView(
            isPresented: $isPresented,
            allChallenge: $viewModel.challengeList,
            challenge: challenge,
            type: self.type,
            index: challengeIndex
        ) {
            handleChallengeAlert(with: challengeIndex)
        }
    }
    
    private func handleOnAppear() {
        Task {
            if await viewModel.prepareData() {
                isLoading = false
            } else {
                showInitAlert = true
            }
        }
    }
    
    private func handleChallengeAlert(with index: Int) {
        switch self.type {
        case .didComplete:
            break
        case .didSelected:
            break
        case .didChallenge:
            break
        case .lock:
            break
        case .willChallenge:
            self.type = .didChallenge
            self.isPresented = true
            Task {
                _ = await viewModel.setMyChallenge(
                    with: $viewModel.challengeList[index].challengeId.wrappedValue
                )
            }
        case .complete:
            Task {
                _ = await viewModel.rewardMyChallenge(
                    with: $viewModel.myChallenges[selectedCardIndex ?? 0].challengeID.wrappedValue
                )
            }
        case .quit:
            Task {
                _ = await viewModel.disableMtChallenge(
                    with: $viewModel.myChallenges[selectedCardIndex ?? 0].challengeID.wrappedValue
                )
            }
        }
    }
}

extension ChallengesView {
    
    //MARK: Description
    
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
        .padding(.bottom, 24)
    }
    
    //MARK: TopCard
    
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
                ForEach(0..<viewModel.myChallenges.count, id: \.self) { index in
                    handleChallengeCard(for: index)
                }
                
                if $viewModel.myChallenges.count < 3 {
                    ForEach($viewModel.myChallenges.count..<3, id: \.self) { index in
                        ChallengeEmptyView()
                            .background(.white)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
        }
        .padding(.bottom, 21)
        .onChange(of: viewModel.challengeList) { _ in
            withAnimation(.linear) {
                selectedCardIndex = nil
            }
        }
        .onChange(of: viewModel.myChallenges) { _ in
            withAnimation(.linear) {
                selectedCardIndex = nil
            }
        }
    }
    
    private func handleChallengeCard(for index: Int) -> some View {
        let challenge = viewModel.myChallenges[index]
        let screenWidth = UIScreen.main.bounds.size.width
        return ZStack {
            if selectedCardIndex == index {
                ChallengeCardBackView(
                    viewModel: viewModel,
                    challenge: challenge,
                    parentsWidth: screenWidth,
                    isPresented: $isPresented,
                    type: $type
                )
                .background(.white)
                .cornerRadius(4)
                .rotation3DEffect(.degrees(180), axis: (x: 0.0, y: 1.0, z: 0.0))
            } else {
                ChallengeCardFrontView(
                    challenge: challenge,
                    parentsWidth: screenWidth
                )
                .background(.white)
                .cornerRadius(4)
            }
        }
        .rotation3DEffect(
            .degrees(self.selectedCardIndex == index ? 180 : 0),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .onTapGesture {
            handleChallengeCardTap(for: index)
        }
    }
    
    private func handleChallengeCardTap(for index: Int) {
        withAnimation(.linear) {
            // For front & back card
            self.selectedCardIndex = (self.selectedCardIndex == index) ? nil : index
            
            // For challengeAlert
            if let challengeIndex = viewModel.challengeList.firstIndex(where: {
                $0.challengeId == self.viewModel.myChallenges[index].challengeID
            }) {
                self.indexForAlert = challengeIndex
            } else {
                print("[ChallengeView] Invalid MyChallenge Index detected!!")
            }
        }
    }
    
    //MARK: Grid
    
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
                let totalPages = (viewModel.challengeList.count + 11) / 12
                ForEach(0..<totalPages, id: \.self) { pageIndex in
                    gridPage(for: pageIndex)
                }
            }
            .frame(height: 380)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }

    private func gridPage(for pageIndex: Int) -> some View {
        let startIndex = pageIndex * 12
        let endIndex = min(startIndex + 12, viewModel.challengeList.count)
        let pageItems = viewModel.challengeList[startIndex..<endIndex]
        
        return VStack {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(pageItems.indices, id: \.self) { index in
                    let item = pageItems[index]
                    ChallengeDetailView(challenge: item)
                        .frame(width: 62, height: 120)
                        .onTapGesture {
                            handleGridPageTap(with: item)
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            Spacer()
        }
        .padding(.top, 16)
        .tag(pageIndex)
    }
    
    private var pageControl: some View {
        HStack(spacing: 10) {
            let totalPages = (viewModel.challengeList.count + 11) / 12
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .frame(width: 9, height: 9)
                    .foregroundColor(index == currentPage ? .theme.mainPurpleColor : Color(hex: "D9D9D9"))
            }
        }
        .padding(.bottom, 24)
    }
    
    private func handleGridPageTap(with item: ChallengeDTO) {
        withAnimation(.linear) {
            // For challengeAlertView
            if let challengeIndex = viewModel.challengeList.firstIndex(where: {
                $0.challengeId == item.challengeId
            }) {
                self.indexForAlert = challengeIndex
                setChallengeAlert(with: item)
            } else {
                print("[ChallengeView] Invalid FullChallenge Index detected!!")
            }
        }
    }
    
    private func setChallengeAlert(with challenge: ChallengeDTO) {
        // 완료한 도전과제
        if challenge.isFinished == true && challenge.isSelected == false && challenge.islock == false {
            self.type = .didComplete
            self.isPresented.toggle()
        // 등록된 도전과제
        } else if challenge.isFinished == false && challenge.isSelected == true && challenge.islock == false {
            self.type = .didSelected
            self.isPresented.toggle()
        // 도전하기
        } else if challenge.isFinished == false && challenge.isSelected == false && challenge.islock == false {
            if viewModel.myChallenges.count == 3 {
                toast = Toast(style: .error, message: "나의 도전과제는 3개까지만 등록이 가능합니다.", width: 300)
            } else {
                self.type = .willChallenge
                self.isPresented.toggle()
            }
        // 잠금해제 안됨
        } else if challenge.isFinished == false && challenge.isSelected == false && challenge.islock == true {
            self.type = .lock
            self.isPresented.toggle()
        }
    }
}
