//
//  ChallengeOverleafView.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeCardBackView: View {
    
    @ObservedObject var homeViewModel: HomeViewModel
    let challenge: MyChallengeDTO
    let parentsWidth: CGFloat
    
    var body: some View {
        VStack {
                
            Text(challenge.title)
                .font(.appleSDGothicNeo(.bold, size: 12))
                .foregroundColor(.theme.blackColor)
                .multilineTextAlignment(.center)
            Text(challenge.desc)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .foregroundColor(.theme.greyColor)

            
            ZStack(alignment: .leading) {
                
                ZStack(alignment: .trailing) {
                    Capsule()
                        .fill(.black.opacity(0.08))
                        .frame(height: 3)
                }
                Capsule()
                    .fill(
                        Color.theme.mainBlueColor
                    )
                    .frame(width: 30, height: 5)
            }
            .padding(.leading, 17)
            .padding(.trailing, 17)
            
            Text("포기하기")
                .frame(height: 25)
                .frame(maxWidth: .infinity)
                .background(Color.theme.mainPurpleColor)
                .foregroundColor(.theme.whiteColor)
                .cornerRadius(8)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .padding(.top, 12)
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .onTapGesture {
                    print("포기하기")
                    homeViewModel.quitChallenge(with: challenge.cahllengeID)
                }
        }
        .frame(width: setCardWidth(screenWidth: parentsWidth),height: 144)
    }
}

//struct ChallengeOverleafView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengeCardBackView(
//            challenge: ChallengeCardModel(
//                image: "applelogo",
//                title: "목표달성의 쾌감!",
//                description: "물방울 3개 모으기"),
//            parentsWidth: 400
//        )
//        .previewLayout(.sizeThatFits)
//    }
//}


extension ChallengeCardBackView {
    func setCardWidth(screenWidth: CGFloat) -> CGFloat {
        let cardsWidth = screenWidth / 3 - 24
        return cardsWidth
    }
}
