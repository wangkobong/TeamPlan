//
//  MyPageView.swift
//  teamplan
//
//  Created by 송하민 on 2/26/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MyPageView: View {
    
    @ObservedObject private var vm = MypageViewModel()
    
    // MARK: - private properties
    
    private var leftRightInset: CGFloat = 16
    private var menuTitles: [MypageMenu] = [.guide, .setting, .logout, .withdraw, .version]
    
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
                        print("클릭: \(title)")
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
}

#Preview {
    return MyPageView()
}
