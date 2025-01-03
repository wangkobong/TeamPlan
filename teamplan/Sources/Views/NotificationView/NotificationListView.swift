//
//  NotificationListView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct NotificationListView: View {
    
    @EnvironmentObject private var notifyVM: NotificationViewModel
    
    var body: some View {
        ForEach(Array(notifyVM.filteredNotiList.enumerated()), id: \.element.id) { index, noti in
            NotificationRowView(notification: $notifyVM.filteredNotiList[index])
                .environmentObject(notifyVM)
            Divider()
        }
    }
}
