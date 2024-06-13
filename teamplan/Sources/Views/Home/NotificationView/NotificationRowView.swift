//
//  NotificationRowView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct NotificationRowView: View {
    
    @Binding var notification: NotificationModel
    
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
            Spacer()
        }
        .frame(height: 89)
        .padding(.top, 10)
        
    }
}

extension NotificationRowView {
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

struct NotificationRowView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationRowView(notification: .constant(NotificationModel(title: "알림 제목", description: "알림 본문", type: .project, isSelected: false, date: Date())))
            .previewLayout(.sizeThatFits)
    }
}
