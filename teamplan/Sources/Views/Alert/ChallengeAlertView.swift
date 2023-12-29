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
}

public struct ChallengeAlertView: View {
    
    @Binding public var isPresented: Bool
    @Binding var allChallenge: [ChallengeObject]
    
    public typealias Action = () -> ()
    
    let type: ChallengeAlertType
    let index: Int
    public var action: Action
    lazy var challenge = allChallenge[self.index]
    
    public init(isPresented: Binding<Bool>, allChallenge: Binding<[ChallengeObject]>,type: ChallengeAlertType, index: Int, action: @escaping Action) {
        self._isPresented = isPresented
        self._allChallenge = allChallenge
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
            Text("\(allChallenge[self.index].chlg_finished_at)")
                .font(.appleSDGothicNeo(.regular, size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.greyColor)
                .padding(.top, 16)
            
            Spacer()
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].chlg_type, isLock: self.allChallenge[index].chlg_lock, isComplete: self.allChallenge[index].chlg_status))
                .frame(width: 82, height: 82)
            
            Text("\(allChallenge[self.index].chlg_desc)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).chlg_title)\n이 배찌를 획득하였어요.")
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
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].chlg_type, isLock: self.allChallenge[index].chlg_lock, isComplete: self.allChallenge[index].chlg_status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).chlg_title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).chlg_title)\n연속 해결하기")
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
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].chlg_type, isLock: self.allChallenge[index].chlg_lock, isComplete: self.allChallenge[index].chlg_status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).chlg_title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("\(getChallenge(index: self.index).chlg_title)프로젝트 5개\n연속 해결하기")
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
            
            Image(ChallengeIconHelper.setIcon(type: self.allChallenge[index].chlg_type, isLock: self.allChallenge[index].chlg_lock, isComplete: self.allChallenge[index].chlg_status))
                .frame(width: 82, height: 82)
            
            Text("\(getChallenge(index: self.index).chlg_title)")
                .font(.appleSDGothicNeo(.bold, size: 24))
                .multilineTextAlignment(.center)
                .foregroundColor(.theme.mainPurpleColor)
    
            
            Text("'\(getChallenge(index: self.index).chlg_title)'\n해결 후 잠금해제")
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
}


extension ChallengeAlertView {
    private func getChallenge(index: Int) -> ChallengeObject {
        return self.allChallenge[index]
    }
}
