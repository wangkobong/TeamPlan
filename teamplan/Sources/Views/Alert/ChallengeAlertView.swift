//
//  ChallengeAlert.swift
//  teamplan
//
//  Created by sungyeon on 2023/12/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

enum ChallengeAlertType {
    case didComplete
    case willQuit
    case willChallenge
    case notice
}

struct ChallengeAlertView: View {
    
    let type: ChallengeAlertType = .notice
    
    var body: some View {
        ZStack {
            switch type {
            case .didComplete:
                didCompleteAlert
            case .willQuit:
                willQuitAlert
            case .willChallenge:
                willChallengeAlert
            case .notice:
                noticeAlert
            }
        }
        .frame(width: 296, height: 323)
        .background(.white)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
    }
}

struct ChallengeAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeAlertView()
    }
}

extension ChallengeAlertView {
    private var didCompleteAlert: some View {
        VStack {
            Text("획득일 23-09-19")
                .font(.appleSDGothicNeo(.regular, size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.greyColor)
                .padding(.top, 16)
            
            Spacer()
            
            Image("book_circle_blue")
                .frame(width: 82, height: 82)
            
            Text("신중한 챌린저")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("프로젝트 5개를 연속 해결하고 \n이 배찌를 획득하였어요.")
                .font(.appleSDGothicNeo(.regular, size: 17))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.theme.darkGreyColor)
                .padding(.top, 12)
                .padding(.horizontal, 40)
            
            Button {
                
            } label: {
                Text("닫기")
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.mainPurpleColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.theme.mainPurpleColor.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

        }
    }
    
    private var willQuitAlert: some View {
        VStack {

            Spacer()
            
            Image("book_circle_grey")
                .frame(width: 82, height: 82)
            
            Text("신중한 챌린저")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("프로젝트 5개\n연속 해결하기")
                .font(.appleSDGothicNeo(.regular, size: 17))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.theme.darkGreyColor)
                .padding(.top, 12)
                .padding(.horizontal, 40)
            
            HStack {
                Button {
                    
                } label: {
                    Text("닫기")
                        .font(.appleSDGothicNeo(.bold, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.theme.mainPurpleColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.theme.mainPurpleColor.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                    .frame(width: 16)
                
                Button {
                    
                } label: {
                    Text("포기하기")
                        .font(.appleSDGothicNeo(.bold, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.theme.mainPurpleColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.45, green: 0.28, blue: 0.88), lineWidth: 1)
                    
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    private var willChallengeAlert: some View {
        VStack {

            Spacer()
            
            Image("book_circle_grey")
                .frame(width: 82, height: 82)
            
            Text("꾸준한 챌린저")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("프로젝트 5개\n연속 해결하기")
                .font(.appleSDGothicNeo(.regular, size: 17))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.theme.darkGreyColor)
                .padding(.top, 12)
                .padding(.horizontal, 40)
            
            HStack {
                Button {
                    
                } label: {
                    Text("닫기")
                        .font(.appleSDGothicNeo(.bold, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.theme.mainPurpleColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.theme.mainPurpleColor.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                    .frame(width: 16)
                
                Button {
                    
                } label: {
                    Text("도전하기")
                        .font(.appleSDGothicNeo(.bold, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.theme.whiteColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.theme.mainPurpleColor)
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
    
    private var noticeAlert: some View {
        VStack {

            Spacer()
            
            Image("lock_icon")
                .frame(width: 82, height: 82)
            
            Text("꾸준한 챌린저")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("'노력파 챌린저 도전과제'\n해결 후 잠금해제")
                .font(.appleSDGothicNeo(.regular, size: 17))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.theme.darkGreyColor)
                .padding(.top, 12)
                .padding(.horizontal, 40)
            
            HStack {
                Button {
                    
                } label: {
                    Text("닫기")
                        .font(.appleSDGothicNeo(.bold, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.theme.mainPurpleColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.theme.mainPurpleColor.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
                    .frame(width: 16)
                
                Button {
                    
                } label: {
                    Text("도전하기")
                        .font(.appleSDGothicNeo(.bold, size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.theme.greyColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}
