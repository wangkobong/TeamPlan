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
    case logout
    case withdraw
    case version
}

struct MyPageView: View {
    
    @ObservedObject private var vm = MypageViewModel()
    @AppStorage("mainViewState") var mainViewState: MainViewState?
    
    private var leftRightInset: CGFloat = 16
    private var menuTitles: [MypageMenu] = [.version]
    
    @State private var showAlert = false
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
//            Alert(
//                title: Text(getAlertTitle()),
//                message: Text(getAlertMessage()),
//                primaryButton: .destructive(Text(getAlertTitle())){
//                    switch myPageAlertState {
//                    case .none:
//                        break
//                    case .logout:
//                        tryLogout(for: .logout)
//                    case .withdraw:
//                        tryWithdraw(for: .withdraw)
//                    case .version:
//                        break
//                    }
//                },
//                secondaryButton: .cancel(Text("확인"))
//            )
//            
            Alert(
                title: Text(getAlertTitle()),
                message: Text(getAlertMessage()),
                dismissButton: .default(Text(getAlertTitle())) {
                    switch myPageAlertState {
                    case .none:
                        break
                    case .logout:
                        tryLogout(for: .logout)
                    case .withdraw:
                        tryWithdraw(for: .withdraw)
                    case .version:
                        break
                    }
                }
            )
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
            
            HStack(spacing: 20) {
                Image(uiImage: Gen.Images.projectEmpty.image)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 4) {
                        Text("\(vm.userName) 지킴이")
                            .font(.appleSDGothicNeo(.bold, size: 20))
                    }
                    HStack {
                        Text(AttributedString("지켜낸 폭탄맨 ") + attributedString(for: vm.dto.protected))
                            .foregroundStyle(.purple)
                        Text("사라진 폭탄맨 " + attributedString(for: vm.dto.destroyed))
                            .foregroundStyle(.purple)
                    }
                }
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
        case .logout:
            myPageAlertState = .logout
            showAlert = true
        case .withdraw:
            myPageAlertState = .withdraw
            showAlert = true
        case .version:
            myPageAlertState = .version
            showAlert = true
        }
    }
    
    private func tryLogout(for menu: MypageMenu) {
        do {
            try vm.performAction(menu: menu)
            withAnimation(.easeIn(duration: 1.2)) {
                mainViewState = .login
            }
        } catch {
            print("로그아웃 에러: \(error)")
        }
    }
    
    private func tryWithdraw(for menu: MypageMenu) {
        do {
            try vm.performAction(menu: menu)
            withAnimation(.easeIn(duration: 1.2)) {
                mainViewState = .login
            }
        } catch {
            print("회원탈퇴 에러: \(error)")
        }
    }
    
    private func getAlertTitle() -> String {
        switch myPageAlertState {
        case .none:
            return ""
        case .logout:
            return "로그아웃"
        case .withdraw:
            return "회원탈퇴"
        case .version:
            return "확인"
        }
    }
    
    private func getAlertMessage() -> String {
        switch myPageAlertState {
        case .none:
            return ""
        case .logout:
            return "정말 로그아웃 하시겠습니까?"
        case .withdraw:
            return "정말 탈퇴 하시겠습니까?"
        case .version:
            return "v1.0.0"
        }
    }
}

#Preview {
    return MyPageView()
}
