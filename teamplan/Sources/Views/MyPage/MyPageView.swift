//
//  MyPageView.swift
//  teamplan
//
//  Created by 송하민 on 2/26/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MenuView: View {
    let title: String
    let showArrow: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if showArrow {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    init(title: String, showArrow: Bool) {
        self.title = title
        self.showArrow = showArrow
    }
}

struct AccomplishView: View {
    
    let accomplishTitle: String
    let accomplishCount: Int
    
    var body: some View {
        ZStack {
            Spacer()
            VStack(spacing: 6) {
                Text(self.accomplishTitle)
                    .font(.appleSDGothicNeo(.regular, size: 12))
                Text("\(self.accomplishCount)")
                    .font(.appleSDGothicNeo(.regular, size: 18))
                    .foregroundStyle(.purple)
            }
            Spacer()
        }
        .frame(maxWidth: 132, maxHeight: 72)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 0) // 사각형 테두리
                .stroke(.clear, lineWidth: 1) // 테두리 색상 및 두께 설정
                .shadow(radius: 5) // 테두리에 그림자 적용
        )
    }
    
    init(accomplishTitle: String, accomplishCount: Int) {
        self.accomplishTitle = accomplishTitle
        self.accomplishCount = accomplishCount
    }
}

struct Accomplishment: Identifiable {
    var id = UUID()
    let accomplishTitle: String
    let accomplishCount: Int
}

struct MyPageView: View {
    
    var menuTitles: [String] = ["가이드북", "로그아웃", "회원탈퇴", "앱 버전"]
    
    var sinceDays: Int = 1
    var accomplishes: [Accomplishment] = [
        .init(accomplishTitle: "완료 도전과제", accomplishCount: 10),
        .init(accomplishTitle: "완료한 목표", accomplishCount: 12),
        .init(accomplishTitle: "완료한 할 일", accomplishCount: 12)
    ]
    
    var savedBomb = 3
    var disappearedBomb = 3
    
    var savedBombAttrString: AttributedString {
        let targetString = "\(self.savedBomb)개"
        var targetAttributed = AttributedString(targetString)
        targetAttributed.foregroundColor = .black
        return targetAttributed
    }
    
    var disappearedBombAttrString: AttributedString {
        let targetString = "\(self.disappearedBomb)개"
        var targetAttributed = AttributedString(targetString)
        targetAttributed.foregroundColor = .black
        return targetAttributed
    }
    
    
    var leftRightInset: CGFloat = 16
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Image("project_empty")
                        .padding([.leading, .trailing])
                    VStack(alignment: .leading, spacing: 10) {
                        Text("김하나 지킴이")
                            .frame(alignment: .leading)
                            .font(.appleSDGothicNeo(.bold, size: 20))
                        HStack {
                            Text(AttributedString("지켜낸 폭탄맨 ") + self.savedBombAttrString)
                                .foregroundStyle(.purple)
                            Text("사라진 폭탄맨 " + self.disappearedBombAttrString)
                                .foregroundStyle(.purple)
                        }
                    }
                    Spacer()
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.gray)
                    .padding(.init(top: 28, leading: self.leftRightInset, bottom: 0, trailing: self.leftRightInset))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("투두팡과 함께한 추억")
                        .font(.title3)
                        .bold()
                    Text("투두팡과 \(sinceDays)일 동안 함께 했어요") // bind actual data
                    HStack {
                        Spacer()
                    }
                }
                .padding(.init(top: 18, leading: self.leftRightInset, bottom: .zero, trailing: self.leftRightInset))
                
                HStack(spacing: 0) {
                    ForEach(Array(accomplishes.enumerated()), id: \.element.id) { index, accomplish in
                        AccomplishView(
                            accomplishTitle: accomplish.accomplishTitle,
                            accomplishCount: accomplish.accomplishCount
                        )
                        .padding(.leading, index == 0 ? self.leftRightInset : 0)
                        .padding(.trailing, index == self.accomplishes.count - 1 ? self.leftRightInset : 0)
                        
                    }
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.gray)
                    .padding(.init(top: 30, leading: self.leftRightInset, bottom: 0, trailing: self.leftRightInset))
                
                ZStack {
                    List {
                        ForEach(menuTitles, id: \.self) { title in
                            if title == "앱 버전" {
                                MenuView(title: "앱 버전", showArrow: false)
                            } else {
                                MenuView(title: title, showArrow: true)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(.white)
            .navigationTitle("마이페이지")
        }
        
    }
}

#Preview {
    return MyPageView()
}
