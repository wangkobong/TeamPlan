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
    
    let columns = [
      //추가 하면 할수록 화면에 보여지는 개수가 변함
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private let myChallengeCards: [ChallengeCardModel] = [
        ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "프로젝트 완주", description: "프로젝트 한개 완주"),
        ChallengeCardModel(image: "applelogo", title: "화이팅!", description: "물방울 10개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "할수있다!", description: "물방울 100개 모으기"),
    ]
    
    private let allChallenge: [ChallengeCardModel] = [
        ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "프로젝트 완주", description: "프로젝트 한개 완주"),
        ChallengeCardModel(image: "applelogo", title: "화이팅!", description: "물방울 10개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "할수있다!", description: "물방울 100개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "프로젝트 완주", description: "프로젝트 한개 완주"),
        ChallengeCardModel(image: "applelogo", title: "화이팅!", description: "물방울 10개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "할수있다!", description: "물방울 100개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "프로젝트 완주", description: "프로젝트 한개 완주"),
        ChallengeCardModel(image: "applelogo", title: "화이팅!", description: "물방울 10개 모으기"),
        ChallengeCardModel(image: "applelogo", title: "할수있다!", description: "물방울 100개 모으기"),
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                
                topCardSection
                    .padding(.bottom, 21)
                
                gridSection
                Spacer()
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
        }
    }
}

struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengesView()
    }
}

extension ChallengesView {
    private var topCardSection: some View {
        VStack {
            HStack {
                Text("나의 도전과제")
                    .font(.appleSDGothicNeo(.semiBold, size: 20))
                    .foregroundColor(.theme.mainPurpleColor)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 19)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 17) {
                    ForEach(myChallengeCards, id: \.self) { challenge in
                        ChallengeCardView(challenge: challenge)
                            .background(.white)
                            .cornerRadius(4)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
                    }
                }
            }
        }
    }
    private var gridSection: some View {
        VStack {
            HStack {
                Text("모든 도전과제")
                    .font(.appleSDGothicNeo(.semiBold, size: 20))
                    .foregroundColor(.theme.mainPurpleColor)
                    .padding(.leading, 16)
                Spacer()
            }
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(allChallenge, id: \.self) { item in
                    ChallengeDetailView(challenge: item)
                        .frame(width: 62, height: 100)
                }
            }
            .padding()
        }
    }
}
