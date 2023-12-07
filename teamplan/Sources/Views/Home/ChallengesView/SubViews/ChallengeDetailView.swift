//
//  ChallengeDetailView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/09/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeDetailView: View {
    
    let challenge: ChallengeObject
    
    var body: some View {
        VStack {
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 57, height: 57)
           
                Image(self.setIcon(type: challenge.chlg_type, isLock: challenge.chlg_lock, isComplete: challenge.chlg_status))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 57, height: 57)
            }
        
            Spacer()
                .frame(height: 10)
            
            Text(challenge.chlg_title)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                .lineLimit(2)
        }
    }
}

//struct ChallengeDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengeDetailView(challenge: ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"))
//    }
//}

extension ChallengeDetailView {
    private func setIcon(type: ChallengeType, isLock: Bool, isComplete: Bool) -> String {
        if isLock {
            return "lock_icon"
        } else {
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
}
