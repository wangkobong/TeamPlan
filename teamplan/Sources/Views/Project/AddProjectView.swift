//
//  AddProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2024/02/18.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI
import Combine

enum StartDateSelection {
    case none
    case today
    case tomorrow
    
    func futureDate(from date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        switch self {
        case .none:
            break
        case .today:
            components.day = 0
        case .tomorrow:
            components.day = 1
        }
        
        return calendar.date(byAdding: components, to: date)!
    }
}

enum DurationSelection {
    case none
    case sevenDays
    case fourteenDays
    case twentyFirstDay
    case fourthWeeks
    case fifthWeeks
    case sixthWeeks
    case seventhWeeks
    case eighthWeeks
    
    func futureDate(from date: Date) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        
        switch self {
        case .none:
            break
        case .sevenDays:
            components.day = 7
        case .fourteenDays:
            components.day = 14
        case .twentyFirstDay:
            components.day = 21
        case .fourthWeeks:
            components.day = 28
        case .fifthWeeks:
            components.day = 35
        case .sixthWeeks:
            components.day = 42
        case .seventhWeeks:
            components.day = 49
        case .eighthWeeks:
            components.day = 56
        }
        
        return calendar.date(byAdding: components, to: date)!
    }
}

struct AddProjectView: View {
    
    @ObservedObject var projectViewModel: ProjectViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State var isValidate: Bool = false
    
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
    }
}

struct AddProjectView_Previews: PreviewProvider {
    static var previews: some View {
        AddProjectView(projectViewModel: ProjectViewModel())
    }
}

extension AddProjectView {
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
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
            }
            .frame(height: 42)
            .frame(maxWidth: .infinity)
            
        }
        .padding(.horizontal, 16)
    }
    
    private var startDateArea: some View {
        VStack {
            HStack {
                Text("목표 시작일은 언제인가요?")
                    .foregroundColor(.black)
                    .font(.appleSDGothicNeo(.bold, size: 17))

                Spacer()
            }
            
            HStack {
                ZStack {
                    Text("오늘")
                        .foregroundColor(projectViewModel.startDate == .today ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .background(projectViewModel.startDate == .today ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            projectViewModel.startDate = .today
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(projectViewModel.startDate == .today ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    Text("내일")
                        .foregroundColor(projectViewModel.startDate == .tomorrow ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .background(projectViewModel.startDate == .tomorrow ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            projectViewModel.startDate = .tomorrow
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(projectViewModel.startDate == .tomorrow ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
            }
            
        }
        .padding(.horizontal, 16)
    }
    
    private var durationArea: some View {
        VStack {
            HStack {
                Text("목표기간")
                    .foregroundColor(.black)
                    .font(.appleSDGothicNeo(.bold, size: 17))

                Spacer()
                    .frame(width: 90)
        
                
                ZStack {
                    Text("📍목표 마감일이 11월 04일이 맞나요?")
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
                ZStack {
                    Text("7일")
                        .foregroundColor(projectViewModel.duration == .sevenDays ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .background(projectViewModel.duration == .sevenDays ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            projectViewModel.duration = .sevenDays
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(projectViewModel.duration == .sevenDays ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    Text("14일")
                        .foregroundColor(projectViewModel.duration == .fourteenDays ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .background(projectViewModel.duration == .fourteenDays ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            projectViewModel.duration = .fourteenDays
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(projectViewModel.duration == .fourteenDays ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    Text("21일")
                        .foregroundColor(projectViewModel.duration == .twentyFirstDay ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .background(projectViewModel.duration == .twentyFirstDay ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            projectViewModel.duration = .twentyFirstDay
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(projectViewModel.duration == .twentyFirstDay ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    HStack {
                        Spacer()

                        Menu {
                            Button("4주", action: {
                                projectViewModel.duration = .fourthWeeks
                            })
                            Button("5주", action: {
                                projectViewModel.duration = .fifthWeeks
                            })
                            Button("6주", action: {
                                projectViewModel.duration = .sixthWeeks
                            })
                            Button("7주", action: {
                                projectViewModel.duration = .seventhWeeks
                            })
                            Button("8주", action: {
                                projectViewModel.duration = .eighthWeeks
                            })
                        } label: {
                            HStack {
                                Text("\(showSelectionButtonText())")
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
            
        }
        .padding(.horizontal, 16)
    }
    
    private var bottomButtonArea: some View {
        Text("프로젝트 시작하기")
            .foregroundColor(.white)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(isValidate ? Color.theme.mainPurpleColor : Color.theme.greyColor)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .onTapGesture {
                if self.isValidate == true {
                    projectViewModel.addNewProject()
                    dismiss.callAsFunction()
                }
            }
    }

}

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
}
