//
//  ChallengeAlert.swift
//  teamplan
//
//  Created by sungyeon on 2023/12/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

public enum ChallengeAlertType {
    case didComplete
    case willQuit
    case willChallenge
    case notice
}

public struct ChallengeAlertView: View {
    
    @Binding public var isPresented: Bool
    public typealias Action = () -> ()
    
    let type: ChallengeAlertType
    public var action: Action
    
    public init(isPresented: Binding<Bool>, type: ChallengeAlertType, action: @escaping Action) {
        self._isPresented = isPresented
        self.type = type
        self.action = action
    }
    
    public var body: some View {
        ZStack {
            
            Color.gray
                .opacity(0.88)
                .ignoresSafeArea()
            ClearBackground()
            VStack {
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
}

struct ChallengeAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeAlertView(isPresented: .constant(true), type: .notice, action: {})
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
            
            Text("닫기")
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .font(.appleSDGothicNeo(.bold, size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
                .background(Color.theme.mainPurpleColor.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .onTapGesture {
                    self.isPresented = false
                }
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

                Text("닫기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.mainPurpleColor)
                    .background(Color.theme.mainPurpleColor.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        self.isPresented = false
                    }
                
                Spacer()
                    .frame(width: 16)
                
                Text("포기하기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.mainPurpleColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .inset(by: 0.5)
                            .stroke(Color(red: 0.45, green: 0.28, blue: 0.88), lineWidth: 1)
                    )
                    .onTapGesture {
                        self.isPresented = false
                        action()
                    }

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
                
                Text("닫기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.mainPurpleColor)
                    .background(Color.theme.mainPurpleColor.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        self.isPresented = false
                    }
                
                Spacer()
                    .frame(width: 16)
                
                Text("도전하기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.whiteColor)
                    .background(Color.theme.mainPurpleColor)
                    .cornerRadius(8)
                    .onTapGesture {
                        self.isPresented = false
                        action()
                    }
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
                
                Text("닫기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.mainPurpleColor)
                    .background(Color.theme.mainPurpleColor.opacity(0.2))
                    .cornerRadius(8)
                    .onTapGesture {
                        self.isPresented = false
                    }
                
                Spacer()
                    .frame(width: 16)
                
                Text("도전하기")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .font(.appleSDGothicNeo(.bold, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.greyColor)
                    .background(Color(red: 0.9, green: 0.9, blue: 0.9))
                    .cornerRadius(8)
                    .onTapGesture {
                        
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}
