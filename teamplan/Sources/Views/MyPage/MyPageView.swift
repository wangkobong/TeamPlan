//
//  MyPageView.swift
//  teamplan
//
//  Created by 송하민 on 2/26/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

// MARK: - properties

enum MyPageAlertState {
    case none
    case mockInjection
    case alreaadyInjected
    case eraseData
    case versionCheck
}

struct MyPageView: View {
    
    @ObservedObject private var vm = MypageViewModel()
    @AppStorage("mainViewState") var mainViewState: MainViewState?
    
    private var leftRightInset: CGFloat = 16
    private var menuTitles: [MypageMenu] = [.mock, .erase, .version]
    
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var mockInjected = false
    @State private var myPageAlertState: MyPageAlertState = .none

    // MARK: - body
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                headerSection
                historySection
                accomplishmentsSection
            }
            .padding(.init(top: 0, leading: self.leftRightInset, bottom: 0, trailing: self.leftRightInset))
            
            menuList
        }
        .onAppear {
            vm.loadData()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(getAlertTitle()),
                message: Text(getAlertMessage()),
                primaryButton: .destructive(Text(getAlertTitle())) {
                    switch myPageAlertState {
                    case .mockInjection:
                        tryMockInjection(for: .mock)
                    case .eraseData:
                        tryEraseData(for: .erase)
                    default:
                        break
                    }
                },
                secondaryButton: .cancel(Text("뒤로가기"))
            )
        }
        .onChange(of: vm.injectResult) { newValue in
            if newValue {
                vm.loadData()
            }
        }
    }
    
    // MARK: Section
    
    private var headerSection: some View {
        VStack {
            HStack {
                Text("마이페이지")
                    .font(.appleSDGothicNeo(.bold, size: 20))
                    .foregroundColor(.theme.blackColor)
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 10)
            
            HStack(alignment: .center, spacing: 50) {
                Image(uiImage: Gen.Images.projectEmpty.image)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 4) {
                        Text("\(vm.userName) 지킴이")
                            .font(.appleSDGothicNeo(.bold, size: 20))
                    }
                    HStack {
                        Text(AttributedString("지켜낸 폭탄맨 ") + attributedString(for: vm.dto.protected))
                            .foregroundStyle(.purple)
                    }
                    HStack {
                        Text(AttributedString("사라진 폭탄맨 ") + attributedString(for: vm.dto.destroyed))
                            .foregroundStyle(.purple)
                    }
                }
                Spacer()
            }
            Divider()
                .background(.black.opacity(0.6))
                .frame(height: 1)
                .padding(.init(top: 20, leading: .zero, bottom: 0, trailing: .zero))
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("투두팡과 함께한 추억")
                .font(.title3)
                .bold()
            HStack {
                Image("Time")
                Text("투두팡과 \(vm.dto.serviceTerm)일 동안 함께 했어요")
                Spacer()
            }
        }
        .padding(.init(top: 18, leading: .zero, bottom: 10, trailing: .zero))
    }
    
    private var accomplishmentsSection: some View {
        VStack {
            AccomplishmentView(accomplishes: vm.accomplishes)
                .frame(maxWidth: .infinity, minHeight: 78)

            Divider()
                .background(Color.black.opacity(0.6))
                .frame(height: 1)
                .padding(.init(top: 30, leading: .zero, bottom: .zero, trailing: .zero))
        }
    }
    
    private var menuList: some View {
        List {
            ForEach(menuTitles, id: \.self) { title in
                MenuItemView(title: title.rawValue, showArrow: title != .version)
                    .onTapGesture {
                        handleMenuTap(for: title)
                    }
            }
        }
        .scrollDisabled(true)
        .listStyle(.plain)
    }
}

//MARK: Support

extension MyPageView {
    
    private func attributedString(for count: Int) -> AttributedString {
        var attributed = AttributedString("\(count)개")
        attributed.foregroundColor = .black
        return attributed
    }

    private func handleMenuTap(for menu: MypageMenu) {
        switch menu {
        case .mock:
            if self.mockInjected {
                myPageAlertState = .alreaadyInjected
            } else {
                myPageAlertState = .mockInjection
            }
            showAlert = true
        case .erase:
            myPageAlertState = .eraseData
            showAlert = true
        case .version:
            myPageAlertState = .versionCheck
            showAlert = true
        }
    }
    
    private func tryMockInjection(for menu: MypageMenu) {
        self.isLoading = true
        Task {
            await vm.performAction(menu: menu)
            self.isLoading = false
            if vm.injectResult {
                self.mockInjected = true
            }
        }
    }
    
    private func tryEraseData(for menu: MypageMenu) {
        self.isLoading = true
        Task {
            await vm.performAction(menu: menu)
            self.isLoading = false
            if vm.eraseResult {
                withAnimation(.easeIn(duration: 1.2)) {
                    mainViewState = .login
                }
            }
        }
    }
    
    private func getAlertTitle() -> String {
        switch myPageAlertState {
        case .none:
            return ""
        case .mockInjection:
            return "추가하기"
        case .eraseData:
            return "삭제하기"
        case .versionCheck:
            return "버젼확인"
        case .alreaadyInjected:
            return "확인"
        }
    }
    
    private func getAlertMessage() -> String {
        switch myPageAlertState {
        case .none:
            return ""
        case .mockInjection:
            return "주의!\n사용자의 통계정보가 변경될 것이며, 임시목표들이 생성될 것입니다! "
        case .eraseData:
            return "주의!\n 지금까지의 모든 데이터가 삭제될 것입니다!"
        case .versionCheck:
            return "0.0.85_test"
        case .alreaadyInjected:
            return "이미 데이터를 추가하였습니다."
        }
    }
}

#Preview {
    return MyPageView()
}
