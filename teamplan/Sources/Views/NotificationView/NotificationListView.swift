//
//  NotificationListView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct NotificationListView: View {
    
    @EnvironmentObject private var notificationViewModel: NotificationViewModel
    @Binding var notifications: [NotificationModel]
    
    var body: some View {
        ForEach(Array(notificationViewModel.filteredNotiList.enumerated()), id: \.element.id) { index, noti in
            NotificationRowView(notification: $notificationViewModel.filteredNotiList[index])
            Divider()
        }
    }
}

//struct NotificationListView_Previews: PreviewProvider {
//    static var previews: some View {
//        NotificationListView()
//    }
//}
