//
//  MyChallengeView.swift
//  teamplan
//
//  Created by 크로스벨 on 5/20/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import SwiftUI

struct MyChallengeView: View {
    
    //MARK: Properties & Body
    @ObservedObject var homeVM: HomeViewModel
    @Binding var isChallengeViewActive: Bool
    
    var body: some View {
        VStack {
            challengeLinkSection
                .padding(.top, 20)
                .padding(.horizontal, 16)
            myChallengeSection
        }
        .padding(.horizontal, 16)
    }
    
    //MARK: Total Challenge Link
    private var challengeLinkSection: some View {
        HStack {
            Text("나의 도전과제")
                .font(.appleSDGothicNeo(.semiBold, size: 20))
            Spacer()
            
            NavigationLink(
                destination: ChallengesView(homeViewModel: homeVM),
                isActive: $isChallengeViewActive)
            {
                Text("전체보기")
            }
            Image("right_arrow_home")
                .frame(width: 15, height: 15)
                .padding(.leading, -5)
                .padding(.bottom, 2)
        }
        .font(.appleSDGothicNeo(.regular, size: 12))
    }
    
    //MARK: ChallengeCard Section
    private var myChallengeSection: some View {
        ZStack {
            checkMyChallenges
            
            if homeVM.userData.myChallenges.isEmpty {
                noMyChallenges
            }
        }
    }
    
    //MARK: Extract MyChallenge
    private var checkMyChallenges: some View {
        HStack(spacing: 17) {
            let screenWidth = UIScreen.main.bounds.size.width
            let myChallengeCount = homeVM.userData.myChallenges.count

            ForEach(0..<3, id: \.self) { index in
                if index < myChallengeCount {
                    let challenge = homeVM.userData.myChallenges[index]
                    ZStack {
                        ChallengeCardFrontView(challenge: challenge, parentsWidth: screenWidth)
                            .background(.white)
                            .cornerRadius(4)
                    }
                } else {
                    ChallengeEmptyView()
                        .background(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
    }
    
    //MARK: No MyChallenge Case
    private var noMyChallenges: some View {
        VStack {
            HStack {
                Image("waterdrop_reverse")
                Spacer()
                Image("waterdrop")
            }
            .padding(.horizontal, 60)
            
            Text("도전과제에 도전하여 물방울을 모아보세요!")
                .font(.appleSDGothicNeo(.regular, size: 16))
                .foregroundColor(Color(hex: "3B3B3B"))
            
            Text("도전하기")
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.white)
                .frame(width: 70, height: 28)
                .background(Color(red: 0.51, green: 0.87, blue: 1))
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
                .overlay(
                RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color(red: 0.51, green: 0.87, blue: 1), lineWidth: 1)
                )
                
        }
        .frame(maxWidth: .infinity, maxHeight: 144)
        .background(.white.opacity(0.8))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
    }
}

//MARK: Preview

//struct MyChallengeView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyChallengeView(isChallengeViewActive: .constant(false))
//    }
//}
