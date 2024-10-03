//
//  NotificationRowView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct NotificationRowView: View {
    
    @EnvironmentObject private var notifyVM: NotificationViewModel
    @Binding var notification: NotificationModel
    
    @State private var showUpdateAlert = false
    @State private var showCheckAlert = false
    
    var body: some View {
        HStack {
            
            imageSection
                .frame(width: 60)
            
            VStack(alignment: .leading) {

                Text(notification.title)
                    .font(.appleSDGothicNeo(.bold, size: 16))
                    .foregroundColor(.theme.mainPurpleColor)
                    .padding(.bottom, 2)
                
                Text(notification.description)
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.theme.darkGreyColor)
                Spacer()
                dateSection
                Spacer()
            }
            .onTapGesture {
                Task{
                    await handelTap()
                }
            }
            .alert(isPresented: $showUpdateAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Failed to update notifyData"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showCheckAlert) {
                Alert(
                    title: Text("이게 맞나요?"),
                    message: Text("이미 확인한 알림입니다."),
                    dismissButton: .default(Text("OK"))
                )
            }
            Spacer()
        }
        .frame(height: 89)
        .padding(.top, 10)
        .background(notification.isSelected ? Color.theme.whiteGreyColor : Color.white)
        .cornerRadius(8)
    }
}

extension NotificationRowView {
    
    private func handelTap() async {
        if notification.isSelected {
            showCheckAlert = true
        } else {
            if await !notifyVM.updateNotify(with: notification) {
                showUpdateAlert = true
            }
        }
    }
    
    private func switchView() -> some View {
        switch notification.type {
        case .project:
            return Image("paper_noti")
        case .challenge:
            return Image("power_noti")
        case .all:
            return Image("bomb_noti")
        }
    }
    
    private func setData(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy.MM.dd"
        return dateFormatter.string(from: date)
    }
    
    private var imageSection: some View {
        VStack {
            switchView()
                .frame(width: 25, height: 25)
            Spacer()
        }
    }

    private var dateSection: some View {
        HStack {
            Spacer()
            Text(self.setData(date: notification.date))
                .font(.appleSDGothicNeo(.regular, size: 12))
                .foregroundColor(.theme.darkGreyColor)
        }
        .frame(height: 20)
    }
}
