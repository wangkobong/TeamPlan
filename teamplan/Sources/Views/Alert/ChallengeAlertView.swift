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
    case didSelected
    case willChallenge
    case lock
    case quit
    case didChallenge
}

public struct ChallengeAlertView: View {
    
    @Binding public var isPresented: Bool
    @Binding var allChallenge: [ChallengeObject]
    @Binding var challenge: ChallengeObject
    
    public typealias Action = () -> ()
    
    let type: ChallengeAlertType
    let index: Int
    public var action: Action

    public init(isPresented: Binding<Bool>, allChallenge: Binding<[ChallengeObject]>, challenge: Binding<ChallengeObject>, type: ChallengeAlertType, index: Int, action: @escaping Action) {
        self._isPresented = isPresented
        self._allChallenge = allChallenge
        self._challenge = challenge
        self.type = type
        self.action = action
        self.index = index
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
                case .didSelected:
                    didSelectedAlert
                case .willChallenge:
                    willChallengeAlert
                case .lock:
                    lockAlert
                case .quit:
                    quitAlert
                case .didChallenge:
                    didChallengeAlert
                }
            }
            .frame(width: 296, height: 323)
            .background(.white)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
        }
        .onAppear {
            print("얼럿타입: \(self.type)")
            print("인덱스: \(self.index)")
        }
    }
}

//struct ChallengeAlertView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengeAlertView(isPresented: .constant(true), allChallenge: <#Binding<[ChallengeObject]>#>, type: .lock, index: 3, action: {})
//    }
//}

extension ChallengeAlertView {
    private var didCompleteAlert: some View {
        VStack {
            Text("\(allChallenge[self.index].finishedAt)")
                .font(.appleSDGothicNeo(.regular, size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.greyColor)
                .padding(.top, 16)
            
            Spacer()
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].type, isLock: self.allChallenge[index].lock, isComplete: self.allChallenge[index].status))
                .frame(width: 82, height: 82)
            
            Text("\(allChallenge[self.index].desc)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).title)\n이 배찌를 획득하였어요.")
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
    
    private var didSelectedAlert: some View {
        VStack {

            Spacer()
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].type, isLock: self.allChallenge[index].lock, isComplete: self.allChallenge[index].status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).title)\n연속 해결하기")
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
    
    private var willChallengeAlert: some View {
        VStack {

            Spacer()
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].type, isLock: self.allChallenge[index].lock, isComplete: self.allChallenge[index].status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).title)프로젝트 5개\n연속 해결하기")
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
    
    private var lockAlert: some View {
        VStack {

            Spacer()
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].type, isLock: self.allChallenge[index].lock, isComplete: self.allChallenge[index].status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("'\(getChallenge(index: self.index).title)'\n해결 후 잠금해제")
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
    
    private var quitAlert: some View {
        VStack {

            Spacer()
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].type, isLock: self.allChallenge[index].lock, isComplete: self.allChallenge[index].status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).title)프로젝트 5개\n연속 해결하기")
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
//                    .background(Color.theme.mainPurpleColor)
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
    
    private var didChallengeAlert: some View {
        ZStack {
            
            VStack {
                Spacer()
                    .frame(height: 30)
                HStack {
                    Image("alert_didChallenge_red")
                        .offset(y: -10)
                        .offset(x: -40)
                    Image("alert_didChallenge_x")
                        .offset(y: 5)
                    Image("alert_didChallenge_yellow1")
                        .offset(y: 35)
                        .offset(x: -80)
                    Image("alert_didChallenge_rectangle_blue")
                        .offset(y: -5)
                        .offset(x: 110)
                    Image("alert_didChallenge_yellow2")
                        .offset(y: 5)
                        .offset(x: 35)
                    Image("alert_didChallenge_rectangle_grey")
                        .offset(y: 65)
                        .offset(x: -120)
                    Image("alert_didChallenge_rectangle_plus")
                        .offset(y: 35)
                        .offset(x: 40)
                }
                Spacer()
            }
            
            VStack {

                Spacer()
                    .frame(height: 50)
                
                Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].type))
                    .frame(width: 82, height: 82)
                
                Spacer()
                    .frame(height: 9)
                
                Text("나의 도전과제로\n등록되었습니다.")
                    .font(.appleSDGothicNeo(.semiBold, size: 20))
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
    }
}


extension ChallengeAlertView {
    private func getChallenge(index: Int) -> ChallengeObject {
        return self.allChallenge[index]
    }
}
