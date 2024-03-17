//
//  MyPageView.swift
//  teamplan
//
//  Created by 송하민 on 2/26/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MyPageView: View {
    
    // MARK: - private properties
    
    private var leftRightInset: CGFloat = 16
    private var menuTitles: [String] = ["가이드북", "로그아웃", "회원탈퇴", "앱 버전"]
    
    private var savedBombAttrString: AttributedString {
        let targetString = "\(self.savedBomb)개"
        var targetAttributed = AttributedString(targetString)
        targetAttributed.foregroundColor = .black
        return targetAttributed
    }
    
    private var disappearedBombAttrString: AttributedString {
        let targetString = "\(self.disappearedBomb)개"
        var targetAttributed = AttributedString(targetString)
        targetAttributed.foregroundColor = .black
        return targetAttributed
    }
    
    
    // MARK: - properties
    
    // FIXME: need data binding
    
    var sinceDays: Int = 1
    var savedBomb = 3
    var disappearedBomb = 3
    
    var accomplishes: [Accomplishment] = [
        .init(accomplishTitle: "완료 도전과제", accomplishCount: 10),
        .init(accomplishTitle: "완료한 목표", accomplishCount: 12),
        .init(accomplishTitle: "완료한 할 일", accomplishCount: 12)
    ]
    
    
    // MARK: - body
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("마이페이지")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.purple)
                    .frame(height: 60)
                
                HStack(spacing: 20) {
//                    Image("project_empty")
                    Image(uiImage: Gen.Images.projectEmpty.image)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("김하나 지킴이")
                                .frame(alignment: .leading)
                                .font(.appleSDGothicNeo(.bold, size: 20))
                            Image("Pencil")
                        }
                        HStack {
                            Text(AttributedString("지켜낸 폭탄맨 ") + self.savedBombAttrString)
                                .foregroundStyle(.purple)
                            Text("사라진 폭탄맨 " + self.disappearedBombAttrString)
                                .foregroundStyle(.purple)
                        }
                    }
                }
                
                Divider()
                    .background(.black.opacity(0.6))
                    .frame(height: 1)
                    .padding(.init(top: 20, leading: .zero, bottom: 0, trailing: .zero))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("투두팡과 함께한 추억")
                        .font(.title3)
                        .bold()
                    HStack {
                        Image("Time")
                        Text("투두팡과 \(sinceDays)일 동안 함께 했어요")
                        Spacer()
                    }
                }
                .padding(
                    .init(
                        top: 18,
                        leading: .zero,
                        bottom: 10,
                        trailing: .zero
                    )
                )
                
                AccomplishmentView(accomplishes: self.accomplishes)
                    .frame(maxWidth: .infinity, minHeight: 78)

                Divider()
                    .background(.black.opacity(0.6))
                    .frame(height: 1)
                    .padding(
                        .init(
                            top: 30,
                            leading: .zero,
                            bottom: .zero,
                            trailing: .zero
                        )
                    )
            }
            .padding(.init(top: 0, leading: self.leftRightInset, bottom: 0, trailing: self.leftRightInset))
            
            List {
                ForEach(menuTitles, id: \.self) { title in
                    if title == "앱 버전" {
                        MenuItemView(title: "앱 버전", showArrow: false)
                    } else {
                        MenuItemView(title: title, showArrow: true)
                    }
                }
            }
            .scrollDisabled(true)
            .listStyle(.plain)
        }
        
    }
}

#Preview {
    return MyPageView()
}
