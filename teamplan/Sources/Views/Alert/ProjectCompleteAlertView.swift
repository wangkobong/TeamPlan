//
//  ProjectCompleteAlertView.swift
//  teamplan
//
//  Created by sungyeon kim on 4/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

public struct ProjectCompleteAlertView: View {
    
    public typealias Action = () -> ()
    @Binding public var isPresented: Bool
    public var action: Action
    
    public init(isPresented: Binding<Bool>, action: @escaping Action) {
        self._isPresented = isPresented
        self.action = action
    }
    
    public var body: some View {
        ZStack {
            
            Color.gray
                .opacity(0.88)
                .ignoresSafeArea()
            ClearBackground()
            VStack {
                
                Image("bomb_complete_alert")
                    .frame(width: 82, height: 160)
                
                Spacer()
                
                Text("목표를 완료하였습니다!")
                    .font(.appleSDGothicNeo(.bold, size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.theme.mainPurpleColor)
                
                
                Text("목표가 완료되어 폭탄맨은 터지지 않았습니다!\n또다른 목표를 등록하여 갓생을 이어가세요!")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.theme.darkGreyColor)
                    .padding(.top, 12)
                    .padding(.horizontal, 40)
                
                HStack {
                    
                    Text("취소")
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
                    
                    Text("끝내기")
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
            .frame(width: 296, height: 333)
            .background(.white)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
        }
    }
    
}

#Preview {
    ProjectCompleteAlertView(isPresented: .constant(true), action: {
        print("테스트")
    })
}
