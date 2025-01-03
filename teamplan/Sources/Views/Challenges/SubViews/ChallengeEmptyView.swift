//
//  ChallengeEmptyView.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/29.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeEmptyView: View {
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 34)
            Image("plus_circle") // 이미지 설정
                .frame(width: 35, height: 35) // 원의 크기
                .padding(.bottom, 21)
                
            
            Image("add_challenge_text") // 이미지 설정
                .frame(width: 35, height: 35) // 원의 크기
                .padding(.bottom, 20)
        
        }
        .frame(width: setCardWidth(screenWidth: UIScreen.main.bounds.size.width),height: 144)
    }
}

struct ChallengeEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeEmptyView()
    }
}

extension ChallengeEmptyView {
    func setCardWidth(screenWidth: CGFloat) -> CGFloat {
        let cardsWidth = screenWidth / 3 - 24
        return cardsWidth
    }
}
