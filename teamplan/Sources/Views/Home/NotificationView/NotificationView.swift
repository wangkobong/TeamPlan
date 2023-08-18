//
//  NotificationView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/11.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI
import WrappingHStack

struct NotificationView: View {
    
    @EnvironmentObject private var notificationViewModel: NotificationViewModel

    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            
            section
                .frame(height: 61)
            
            ScrollView {
                NotificationListView(notifications: $notificationViewModel.filteredNotiList)
            }
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("알림")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button {
                    dismiss.callAsFunction()
                    
                } label: {
                    Image("left_arrow_home")
                }
            }
        }
        .onAppear {
            notificationViewModel.filterNotifications(type: .all)
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}

extension NotificationView {
    private var section: some View {
        WrappingHStack(notificationViewModel.notiSections, id: \.self) { section in
            VStack {
                Text(section.title)
                    .foregroundColor(section.isSelected ? .theme.whiteColor : Color(hex: "3B3B3B"))
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(section.isSelected ? Color.theme.mainPurpleColor : Color.theme.whiteColor)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .inset(by: 0.5)
                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                    )
                
                Spacer()
                    .frame(height: 10)
            }
            .onTapGesture {
                withAnimation(.easeInOut) {
                    self.filterNotification(type: section.type)
                    self.filterSection(title: section.title)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func filterSection(title: String) {
        notificationViewModel.notiSections = notificationViewModel.notiSections.map { section in
            var updatedSection = section
            updatedSection.isSelected = section.title == title ? true : false
            return updatedSection
        }
    }
    
    private func filterNotification(type: NotificationType) {
        notificationViewModel.filterNotifications(type: type)
    }
}
