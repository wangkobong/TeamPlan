//
//  ChallengeDetailView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/09/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeDetailView: View {
    
    let challenge: ChallengeCardModel
    
    var body: some View {
        VStack {
            
            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                    .frame(width: 62, height: 62)
                
                Image(systemName: challenge.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(hex: "B3B3B3"))
            }
        
            Spacer()
                .frame(height: 13)
            
            Text(challenge.title)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                .lineLimit(2)
        }
    }
}

struct ChallengeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeDetailView(challenge: ChallengeCardModel(image: "applelogo", title: "목표달성의 쾌감!", description: "물방울 3개 모으기"))
    }
}
