//
//  MainTapView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/10/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct MainTapView: View {
    
    @State private var selectedTab: Int = 1
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                ProjectView()
                .tabItem {
                  Image("document")
                  Text("프로젝트")                                                                                                                                                                                                                              
                }
                .tag(0)
                
                HomeView()
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                .tabItem {
                  Image(systemName: "house")
                  Text("홈")
                }
                .tag(1)
                
              Text("The Last Tab")
                .tabItem {
                  Image("account")
                  Text("마이페이지")
                }
                .tag(2)
            }
            .accentColor(.theme.mainPurpleColor)
        }
    }
}

struct MainTapView_Previews: PreviewProvider {
    static var previews: some View {
        MainTapView()
    }
}


