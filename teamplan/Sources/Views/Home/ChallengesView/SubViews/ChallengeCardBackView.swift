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
    
    @Binding var isPresented: Bool
    @Binding var type: ChallengeAlertType
    
    var body: some View {
        VStack {
            let goal = challenge.goal
            let progress = challenge.progress
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
                    .frame(width: calculateProgressBarWidth(), height: 5)
            }
            .padding(.leading, 17)
            .padding(.trailing, 17)
            
            Text(challenge.progress == 1 ? "완료하기" : "포기하기")
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
                    challenge.progress == 1 ? completeChallenge() : quitChallenge()
                }
        }
        .frame(width: setCardWidth(screenWidth: parentsWidth),height: 144)
        .onAppear {
            print("도전과제 정보: \(challenge)")
        }
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
    
    
    private func calculateProgressBarWidth() -> CGFloat {
        guard challenge.goal != 0 else {
            return 0
        }

        let progressRatio = CGFloat(challenge.progress) / CGFloat(challenge.goal)
        return progressRatio * (setCardWidth(screenWidth: parentsWidth) - 34) // Adjusted width based on the padding
    }
    
    private func completeChallenge() {
        homeViewModel.completeChallenge(with: challenge.challengeID)
        self.type = .complete
        self.isPresented.toggle()
    }
    
    private func quitChallenge() {
        self.type = .quit
        self.isPresented.toggle()
    }
}
