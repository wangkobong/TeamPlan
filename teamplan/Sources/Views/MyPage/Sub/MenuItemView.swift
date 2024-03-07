//
//  MenuItemView.swift
//  teamplan
//
//  Created by 송하민 on 2/29/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MenuItemView: View {
    let title: String
    let showArrow: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if showArrow {
                Image(systemName: "chevron.right")
            }
        }
    }
    
    init(title: String, showArrow: Bool) {
        self.title = title
        self.showArrow = showArrow
    }
}

#Preview {
    Group {
        MenuItemView(title: "TestTitle", showArrow: true)
        MenuItemView(title: "TestTitle", showArrow: false)
        MenuItemView(title: "TestTitle", showArrow: true)
    }
}
