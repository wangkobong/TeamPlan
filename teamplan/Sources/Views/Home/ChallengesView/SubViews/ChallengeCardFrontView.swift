//
//  ChallengeCardView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/07.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeCardFrontView: View {
    
    let challenge: MyChallengeDTO
    let parentsWidth: CGFloat

    var body: some View {
        front
        .frame(width: setCardWidth(screenWidth: parentsWidth),height: 144)

    }
}

//struct ChallengeCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengeCardFrontView(challenge: ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"), parentsWidth: 400)
//            .previewLayout(.sizeThatFits)
//    }
//
//}

extension ChallengeCardFrontView {
    private var front: some View {
        VStack {
            Circle()
                .foregroundColor(Color.init(hex: "E5E5E5")) // 원의 배경색
                .frame(width: 57, height: 57) // 원의 크기
                .overlay(
                    Image(self.setIcon(type: challenge.type, isComplete: true)) // 이미지 설정
                        .foregroundColor(Color.init(hex: "B3B3B3")) // 이미지 색상
                        .font(.system(size: 25)) // 이미지 크기
                )
                .padding(.bottom, 17)
                
            
            Text(challenge.title)
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.theme.blackColor)
            Text(challenge.desc)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .foregroundColor(.theme.greyColor)
        
        }
        
    }
}

extension ChallengeCardFrontView {
    private func setCardWidth(screenWidth: CGFloat) -> CGFloat {
        let cardsWidth = screenWidth / 3 - 24
        return cardsWidth
    }
    
    private func setIcon(type: ChallengeType, isComplete: Bool) -> String {
        switch type {
        case .onboarding: // 온보딩
            return isComplete ? "book_circle_blue" : "book_circle_grey"
        case .serviceTerm: // 서비스 사용 기간
            return isComplete ? "calendar_circle_blue" : "calendar_circle_grey"
        case .totalTodo: // 등록 개수
            return isComplete ? "pencil_circle_blue" : "pencil_circle_grey"
        case .projectAlert: // 프로젝트 등록
            return isComplete ? "folder_circle_plus_blue" : "folder_circle_plus_grey"
        case .projectFinish: // 프로젝트 해결
            return isComplete ? "folder_circle_check_blue" : "folder_circle_check_grey"
        case .waterDrop: // 물방울 개수
            return isComplete ? "drop_circle_blue" : "drop_circle_grey"
        case .unknownType:
            return isComplete ? "book_circle_blue" : "book_circle_grey"
        }
    }
}
