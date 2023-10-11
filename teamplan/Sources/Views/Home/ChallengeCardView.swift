//
//  ChallengeCardView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/07.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeCardView: View {
    
    let challenge: ChallengeCardModel
    let parentsWidth: CGFloat
    
    var body: some View {
        VStack {
            Circle()
                .foregroundColor(Color.init(hex: "E5E5E5")) // 원의 배경색
                .frame(width: 57, height: 57) // 원의 크기
                .overlay(
                    Image(systemName: challenge.image) // 이미지 설정
                        .foregroundColor(Color.init(hex: "B3B3B3")) // 이미지 색상
                        .font(.system(size: 25)) // 이미지 크기
                )
                .padding(.bottom, 17)
                
            
            Text(challenge.title)
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.theme.blackColor)
            Text(challenge.description)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .foregroundColor(.theme.greyColor)
        
        }
        .frame(width: setCardWidth(screenWidth: parentsWidth),height: 144)
    }
}

struct ChallengeCardView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeCardView(challenge: ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"), parentsWidth: 400)
    }
}

extension ChallengeCardView {
    func setCardWidth(screenWidth: CGFloat) -> CGFloat {
        let cardsWidth = screenWidth / 3 - 24
        return cardsWidth
    }
}
