//
//  ProjectExtendView.swift
//  teamplan
//
//  Created by sungyeon kim on 4/11/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ProjectExtendView: View {
    
    @Environment(\.dismiss) var dismiss
//    @ObservedObject var projectViewModel: ProjectViewModel
    @State private var numberOfDay = ""
    @State private var day = ""
    @State private var waterDrop = ""
    
    // 픽커
    @State var day1: String? = nil
    @State var days = ["1","2","3"]
    @State var selectionIndex = 0
    
    var body: some View {
        VStack {
            
            navigationArea
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 30)
            
            contents
 
            Spacer()
            
            bottomButtonArea
            
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    ProjectExtendView()
}


extension ProjectExtendView {
    private var navigationArea: some View {
        HStack {
            
            Image(systemName: "xmark")
                .onTapGesture {
                    dismiss.callAsFunction()
                }
            
            Spacer()

            Text("기한 연장")
                .font(.appleSDGothicNeo(.semiBold, size: 20))
                .foregroundColor(.theme.blackColor)
            
            Spacer()
            
            // 타이틀을 가운데 정렬하기 위한 이미지
            Image(systemName: "xmark")
                .onTapGesture {
                    dismiss.callAsFunction()
                }
                .hidden()
        }
        .frame(height: 60)
    }
    
    private var contents: some View {
        VStack {
            HStack {
                Text("목표 이름")
                    .foregroundColor(.black)
                    .font(.appleSDGothicNeo(.bold, size: 17))
                Spacer()
            }
            .padding(.bottom, 4)
            
            HStack {
                Text("⏱️ 현재 1570일동안 진행중인 목표에요")
                    .foregroundColor(Gen.Colors.darkGreyColor.swiftUIColor)
                    .font(.appleSDGothicNeo(.regular, size: 14))
                Spacer()
            }
            
            Spacer()
                .frame(height: 30)
            
            VStack {
                HStack {
                    Text("기한 연장")
                        .foregroundColor(.black)
                        .font(.appleSDGothicNeo(.bold, size: 17))
                    
                    Spacer()
                    
                    HStack {
                        Image(uiImage: Gen.Images.waterdrop.image)
                            .frame(width: 14, height: 18)
                        Text("10")
                            .foregroundColor(.black)
                            .font(.appleSDGothicNeo(.bold, size: 17))
                        Text("개")
                            .foregroundColor(.black)
                            .font(.appleSDGothicNeo(.regular, size: 12))
                    }
                }
                
                HStack {
                    Text("목표 마감일이 11월 04일이 맞나요?")
                        .foregroundColor(Gen.Colors.darkGreyColor.swiftUIColor)
                        .font(.appleSDGothicNeo(.regular, size: 12))
                        .background(
                            Gen.Colors.mainBlueColor.swiftUIColor
                                .frame(height: 1) // underline's height
                                .offset(y: 9) // underline's y pos
                        )
                    Spacer()
                }
                
                Spacer()
                    .frame(height: 16)
                
                ZStack {
//                    TextField("일 연장", text: $day) { editing in
//                        //                        self.isEditing = editing
//                    }
//                    .foregroundStyle(Gen.Colors.greyColor.swiftUIColor)
//                    .disableAutocorrection(true)
//                    .keyboardType(.phonePad)
//                    .padding(.horizontal, 16)
//                    .font(.appleSDGothicNeo(.bold, size: 17))
//                    .onSubmit {
//                        self.numberOfDay = day
//                        self.day = self.addUnitText(day: Int(day) ?? 0)
//                        self.waterDrop = self.addNumberText(day: Int(numberOfDay) ?? 0)
//                    }
                    TextFieldWithInputView(data: self.days, placeholder: "일 연장", textColor: .gray, placeholderColor: .gray, selectionIndex: self.$selectionIndex, selectedText: self.$day1)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .frame(maxWidth: .infinity)
                    
                    
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Gen.Colors.whiteGreyColor.swiftUIColor, lineWidth: 1)
                    
                }
                .frame(height: 38)
                .frame(maxWidth: .infinity)
                
                Spacer()
                    .frame(height: 18)
                
                HStack {
                    Spacer()
                    Image(uiImage: Gen.Images.projectExchange.image)
                        .foregroundStyle(Gen.Colors.mainPurpleColor.swiftUIColor)
                    Spacer()
                }
                
                ZStack {
//                    TextField("", text: $waterDrop) { editing in
//                        //                        self.isEditing = editing
//                    }
//                    .foregroundStyle(Gen.Colors.mainPurpleColor.swiftUIColor)
//                    .disableAutocorrection(true)
//                    .keyboardType(.phonePad)
//                    .padding(.horizontal, 16)
//                    .font(.appleSDGothicNeo(.bold, size: 17))
//                    .multilineTextAlignment(.center)
//                    .onSubmit {
//                        self.numberOfDay = day
//                        self.day = self.addUnitText(day: Int(numberOfDay) ?? 0)
//                        self.waterDrop = self.addNumberText(day: Int(waterDrop) ?? 0)
//                    }
                    
                    TextFieldWithInputView(data: self.days, placeholder: "0개", textColor: .purple, placeholderColor: .purple, selectionIndex: self.$selectionIndex, selectedText: self.$day1)
                        .foregroundStyle(Gen.Colors.mainPurpleColor.swiftUIColor)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .frame(maxWidth: .infinity)
                    
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Gen.Colors.mainPurpleColor.swiftUIColor, lineWidth: 1)
                    
                }
                .frame(height: 38)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var bottomButtonArea: some View {
        Text("변경 적용하기")
            .foregroundColor(Gen.Colors.greyColor.swiftUIColor)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
//            .background(isValidate ? Color.theme.mainPurpleColor : Color.theme.greyColor)
            .background(Gen.Colors.whiteGreyColor.swiftUIColor)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .onTapGesture {
//                if self.isValidate == true {
//                    projectViewModel.addNewProject()
//                    dismiss.callAsFunction()
                }
            }
}

extension ProjectExtendView {
    private func addUnitText(day: Int) -> String {
        return "\(day)일 연장"
    }
    
    private func addNumberText(day: Int) -> String {
        return "\(day)개"
    }
}
