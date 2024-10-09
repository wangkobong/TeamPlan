//
//  AddProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2024/02/18.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI
import Combine

//MARK: Date Calculation

enum StartDateSelection: Int {
    case none = -1
    case today = 0
    case tomorrow = 1
    
    func futureDate(from date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        if self != .none {
            components.day = self.rawValue
        }
        
        return calendar.date(byAdding: components, to: date) ?? date
    }
}

enum DurationSelection: Int {
    case none = -1
    case sevenDays = 7
    case fourteenDays = 14
    case twentyFirstDay = 21
    case fourthWeeks = 28
    case fifthWeeks = 35
    case sixthWeeks  = 42
    case seventhWeeks = 49
    case eighthWeeks = 56
    
    func futureDate(from date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        if self != .none {
            components.day = self.rawValue
        }
        
        return calendar.date(byAdding: components, to: date) ?? date
    }
}

//MARK: Main Area

struct AddProjectView: View {
    
    @State private var deadlineDate: Date = Date()
    @ObservedObject var projectViewModel: ProjectViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State var isValidate: Bool = false
    @State private var showTitleLengthAlert: Bool = false
    @State private var showProcessAlert: Bool = false
    
    var body: some View {
        VStack {
            
            navigationArea
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 25)
            
            nameArea
            
            Spacer()
                .frame(height: 25)
            
            startDateArea
            
            Spacer()
                .frame(height: 25)
            
            durationArea
            
            Spacer()
            
            bottomButtonArea

        }
        .onReceive(Publishers.CombineLatest3(projectViewModel.$projectName, projectViewModel.$startDate, projectViewModel.$duration)) { _ in
             checkValidationAddButton()
         }
        .onReceive(Publishers.CombineLatest(projectViewModel.$startDate, projectViewModel.$duration)) { _ in
            updateDeadlineDate()
        }
        .onDisappear {
            projectViewModel.initAddingProjectProperty()
        }
        .alert(isPresented: $showTitleLengthAlert) {
            Alert(
                title: Text("글자 수 초과"),
                message: Text("공백을 포함한 글자 수는 최대 20자입니다."),
                dismissButton: .default(Text("확인"))
            )
        }
        .alert(isPresented: $showProcessAlert) {
            Alert(
                title: Text("목표생성 실패"),
                message: Text("목표를 생성하는 데 실패했습니다. 다시 시도해주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

extension AddProjectView {
    
    //MARK: Navigation Area
    
    private var navigationArea: some View {
        HStack {
            
            Image(systemName: "xmark")
                .onTapGesture {
                    dismiss.callAsFunction()
                }
            
            Spacer()

            Text("목표추가")
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
        .padding(.horizontal, 16)

    }
    
    //MARK: Title Area
    
    private var nameArea: some View {
        VStack {
            HStack {
                Text("목표 이름")
                    .foregroundColor(.black)
                    .font(.appleSDGothicNeo(.bold, size: 17))

                Spacer()
            }
            
            ZStack {
                TextField("목표 이름을 설정해주세요", text: $projectViewModel.projectName)
                    .frame(height: 42)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 20)
                    .onChange(of: projectViewModel.projectName) { newValue in
                        if newValue.count > 20 {
                            showTitleLengthAlert = true
                            projectViewModel.projectName = String(newValue.prefix(20))
                        }
                    }
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: StartDate Area
    
    private var startDateArea: some View {
        VStack {
            HStack {
                Text("목표 시작일은 언제인가요?")
                    .foregroundColor(.black)
                    .font(.appleSDGothicNeo(.bold, size: 17))

                Spacer()
            }
            
            HStack {
                dateSelectionButton(text: "오늘", selection: .today)
                Spacer()
                dateSelectionButton(text: "내일", selection: .tomorrow)
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
            }
            
        }
        .padding(.horizontal, 16)
    }
    
    private func dateSelectionButton(text: String, selection: StartDateSelection) -> some View {
        ZStack {
            Text(text)
                .foregroundColor(projectViewModel.startDate == selection ? .white : Color(hex: "B3B3B3"))
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .background( projectViewModel.startDate == selection ? Color.theme.mainPurpleColor : .white )
                .onTapGesture { projectViewModel.startDate = selection }
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                .opacity(projectViewModel.startDate == selection ? 0 : 1)
        }
        .cornerRadius(24)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
    }
    
    //MARK: duration Area
    
    private var durationArea: some View {
        VStack {
            HStack {
                Text("목표기간")
                    .foregroundColor(.black)
                    .font(.appleSDGothicNeo(.bold, size: 17))
                Spacer().frame(width: 90)
                
                ZStack {
                    Text(showDurationInfo())
                        .foregroundColor(Color.theme.darkGreyColor)
                        .font(.appleSDGothicNeo(.regular, size: 12))
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.theme.mainBlueColor)
                        .offset(y: 10)
                }
                .opacity(projectViewModel.duration == .none ? 0 : 1)
            }
            
            HStack {
                durationSelectionButton(text: "7일", selection: .sevenDays)
                Spacer()
                durationSelectionButton(text: "14일", selection: .fourteenDays)
                Spacer()
                durationSelectionButton(text: "21일", selection: .twentyFirstDay)
                Spacer()
                durationMenuButton()
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func durationSelectionButton(text: String, selection: DurationSelection) -> some View {
        ZStack {
            Text(text)
                .foregroundColor(projectViewModel.duration == selection ? .white : Color(hex: "B3B3B3"))
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .background(projectViewModel.duration == selection ? Color.theme.mainPurpleColor : .white)
                .onTapGesture {
                    projectViewModel.duration = selection
                }
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                .opacity(projectViewModel.duration == selection ? 0 : 1)
        }
        .cornerRadius(24)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
    }
    
    private func durationMenuButton() -> some View {
        ZStack {
            HStack {
                Spacer()
                Menu {
                    Button("4주", action: { projectViewModel.duration = .fourthWeeks })
                    Button("5주", action: { projectViewModel.duration = .fifthWeeks })
                    Button("6주", action: { projectViewModel.duration = .sixthWeeks })
                    Button("7주", action: { projectViewModel.duration = .seventhWeeks })
                    Button("8주", action: { projectViewModel.duration = .eighthWeeks })
                } label: {
                    HStack {
                        Text(showSelectionButtonText())
                            .foregroundColor(isSelected4Weeks() ? .white : Color(hex: "B3B3B3"))
                        Image(systemName: "chevron.down")
                            .foregroundColor(isSelected4Weeks() ? .white : Color(hex: "B3B3B3"))
                            .imageScale(.small)
                    }
                    .frame(height: 42)
                    .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                .opacity(isSelected4Weeks() ? 0 : 1)
        }
        .cornerRadius(24)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .background(isSelected4Weeks() ? Color.theme.mainPurpleColor : .white)
        .cornerRadius(24)
    }
    
    //MARK: Bottom Button Area
    
    private var bottomButtonArea: some View {
        Text("목표를 등록하기")
            .foregroundColor(.white)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(isValidate ? Color.theme.mainPurpleColor : Color.theme.greyColor)
            .cornerRadius(8)
            .padding(.horizontal, 16)
        
            .onTapGesture {
                if self.isValidate {
                    if projectViewModel.addNewProject() {
                        dismiss()
                    } else {
                        self.showProcessAlert = true
                    }
                }
            }
    }
}

//MARK: Util

extension AddProjectView {
    
    private func showSelectionButtonText() -> String {
        switch projectViewModel.duration {
        case .none, .sevenDays, .fourteenDays, .twentyFirstDay:
            return "선택"
        case .fourthWeeks:
            return "4주"
        case .fifthWeeks:
            return "5주"
        case .sixthWeeks:
            return "6주"
        case .seventhWeeks:
            return "7주"
        case .eighthWeeks:
            return "8주"
        }
    }
    
    private func isSelected4Weeks() -> Bool {
        switch projectViewModel.duration {
        case .none, .sevenDays, .fourteenDays, .twentyFirstDay:
            return false
        default:
            return true
        }
    }
    
    private func checkValidationAddButton() {
        isValidate = !projectViewModel.projectName.isEmpty && projectViewModel.startDate != .none && projectViewModel.duration != .none
    }
    
    private func updateDeadlineDate() {
        deadlineDate = projectViewModel.duration.futureDate(from: projectViewModel.startDate.futureDate(from: Date()))
    }

    private func showDurationInfo() -> String {
        let deadlineDate = projectViewModel.duration.futureDate(from: projectViewModel.startDate.futureDate(from: Date()))
        return "📍목표 마감일이 \(deadlineDate.monthDayNoLeadingZeros)이 맞나요?"
    }
}

struct AddProjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddProjectView(projectViewModel: ProjectViewModel())
    }
}
