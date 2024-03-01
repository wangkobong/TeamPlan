//
//  AccomplishmentView.swift
//  teamplan
//
//  Created by 송하민 on 2/29/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct Accomplishment: Identifiable {
    var id = UUID()
    let accomplishTitle: String
    let accomplishCount: Int
}

struct AccomplishmentView: View {
    
    // MARK: - properties
    
    var accomplishes: [Accomplishment] = []
    
    
    // MARK: - body
    
    var body: some View {
        
        HStack(spacing: 0) {
            ForEach(Array(accomplishes.enumerated()), id: \.element.id) { index, accomplish in
                if index > 0 {
                    Divider()
                        .background(.gray.opacity(0.5))
                        .padding(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                Color.white
                    .overlay {
                        HStack {
                            VStack(spacing: 12) {
                                Text(accomplish.accomplishTitle)
                                    .font(.appleSDGothicNeo(.bold, size: 12))
                                Text("\(accomplish.accomplishCount)")
                                    .font(.appleSDGothicNeo(.bold, size: 18))
                                    .foregroundStyle(.purple)
                            }
                            
                        }
                    }
                
            }
        }
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 4))
        .shadow(color: .black.opacity(0.1), radius: 14)
        
    }
    
    // MARK: - life cycle
    
    init(accomplishes: [Accomplishment]) {
        self.accomplishes = accomplishes
    }
}

#Preview {
    AccomplishmentView(accomplishes: [
        .init(accomplishTitle: "완료 도전과제", accomplishCount: 10),
        .init(accomplishTitle: "완료한 목표", accomplishCount: 12),
        .init(accomplishTitle: "완료한 할 일", accomplishCount: 12)
    ])
    .frame(width: .infinity, height: 100)
}
