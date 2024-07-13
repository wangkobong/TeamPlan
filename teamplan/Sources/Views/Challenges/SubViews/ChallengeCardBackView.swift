//
//  ChallengeOverleafView.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ChallengeCardBackView: View {
    
    @ObservedObject var viewModel: ChallengeViewModel
    let challenge: MyChallengeDTO
    let parentsWidth: CGFloat
    
    @Binding var isPresented: Bool
    @Binding var type: ChallengeAlertType
    
    var body: some View {
        VStack(spacing: 8) {
            challengeInfo
            progressBar
            actionButton
        }
        .frame(width: setCardWidth(screenWidth: parentsWidth),height: 144)
        .onAppear {
            print("도전과제 정보: \(challenge)")
        }
    }
    
    private var challengeInfo: some View {
        VStack(spacing: 4) {
            Text(challenge.title)
                .font(.appleSDGothicNeo(.bold, size: 12))
                .foregroundColor(.theme.blackColor)
                .multilineTextAlignment(.center)
            Text(challenge.desc)
                .font(.appleSDGothicNeo(.regular, size: 12))
                .foregroundColor(.theme.greyColor)
        }
    }
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.black.opacity(0.08))
                .frame(height: 3)
            Capsule()
                .fill(Color.theme.mainBlueColor)
                .frame(width: calculateProgressBarWidth(), height: 5)
        }
        .padding(.horizontal, 17)
    }
    
    private var actionButton: some View {
        Button(action: handleButtonTap) {
            Text(challenge.progress == challenge.goal ? "완료하기" : "포기하기")
                .frame(maxWidth: .infinity)
                .frame(height: 25)
                .background(Color.theme.mainPurpleColor)
                .foregroundColor(.theme.whiteColor)
                .cornerRadius(8)
                .font(.appleSDGothicNeo(.regular, size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
    }
    
}

extension ChallengeCardBackView {
    func setCardWidth(screenWidth: CGFloat) -> CGFloat {
        let cardsWidth = screenWidth / 3 - 24
        return cardsWidth
    }
    
    private func calculateProgressBarWidth() -> CGFloat {
        guard challenge.goal != 0 else { return 0 }
        let progressRatio = CGFloat(challenge.progress) / CGFloat(challenge.goal)
        return progressRatio * (setCardWidth(screenWidth: parentsWidth) - 34)
    }
    
    private func handleButtonTap() {
        Task {
            if challenge.progress == challenge.goal {
                await completeChallenge()
            } else {
                quitChallenge()
            }
        }
    }
    
    private func completeChallenge() async {
        if await viewModel.rewardMyChallenge(with: challenge.challengeID) {
            self.type = .complete
            self.isPresented.toggle()
        } else {
            // 실패 케이스 처리
            // 예: 에러 메시지 표시
        }
    }
    
    private func quitChallenge() {
        self.type = .quit
        self.isPresented.toggle()
    }
}
