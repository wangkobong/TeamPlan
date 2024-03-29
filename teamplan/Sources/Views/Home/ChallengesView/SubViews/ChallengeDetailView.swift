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
           
                Image(ChallengeIconHelper.setIcon(type: challenge.type, isLock: challenge.lock, isComplete: challenge.status))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 57, height: 57)
            }
        
            Spacer()
                .frame(height: 10)
            
            Text(challenge.title)
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

