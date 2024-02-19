//
//  ProjectDetailView.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/19.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ProjectDetailView: View {
    
    @Environment(\.dismiss) var dismiss
//    @EnvironmentObject var projectViewModel: ProjectViewModel
    let index: Int
    
    var body: some View {
        ScrollView {
            VStack {
                header
                
                Divider()
                    .padding(.horizontal, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("막걸리 브랜딩어쩌구")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button {
                    dismiss.callAsFunction()
                    
                } label: {
                    Image("left_arrow_home")
                }
            }
        }
//        .navigationTitle("\(projectViewModel.projects[index].name)")
//        .onAppear {
//            print("\(projectViewModel.projects[safe: index]?.toDos.count)")
//        }
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailView(index: 0)
    }
}

extension ProjectDetailView {
    private var header: some View {
        ZStack{
            VStack(alignment: .leading) {
                Text("D-14")
                    .foregroundColor(Color.theme.mainPurpleColor)
                    .font(.appleSDGothicNeo(.bold, size: 24))
                    .padding(.bottom, 5)
                
                HStack {
                    Text("23.08.12")
                    Text("~")
                    Text("23.08.26")
                }
                .foregroundColor(Color.theme.mainBlueColor)
                .font(.appleSDGothicNeo(.regular, size: 12))
     
                HStack {
                    Text("할 일을 추가해주세요!")
                        .font(.appleSDGothicNeo(.bold, size: 17))
                        .foregroundColor(.theme.darkGreyColor)
                        .background(
                            Color.init(hex: "7248E1").opacity(0.5)
                                .frame(height: 3) // underline's height
                                .offset(y: 7) // underline's y pos
                        )
                    Spacer()
                }
                .padding(.bottom, 1)
                
                Text("오늘, 추가할 수 있는 할 일은 10개 남았어요")
                    .font(.appleSDGothicNeo(.regular, size: 14))
                    .foregroundColor(.theme.darkGreyColor)
                
                Spacer()
                    .frame(height: 20)
            }
            
            HStack {
                Spacer()
                HStack() {
                    Image(systemName: "plus")
                        .foregroundColor(.theme.mainPurpleColor)
                        .imageScale(.small)
                    Text("할 일")
                        .font(.appleSDGothicNeo(.semiBold, size: 14))
                        .foregroundColor(.theme.mainPurpleColor)
                        .offset(x: -3)
                    
                }
                .frame(width: 72, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.theme.greyColor, lineWidth: 1)
                )
                .offset(x: 0)
                .onTapGesture {

                }
            }
        }
        .padding(.leading, 38)
        .padding(.trailing, 24)

    }
}
