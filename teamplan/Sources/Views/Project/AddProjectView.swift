//
//  AddProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2024/02/18.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

enum StartDateSelection {
    case none
    case today
    case tomorrow
}

enum DurationSelection {
    case none
    case one
    case two
    case three
    case fourth
    case fifth
    case sixth
    case seventh
    case eighth
}

struct AddProjectView: View {
    
    @ObservedObject var projectViewModel: ProjectViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State var projectName: String = ""
    @State var startDate: StartDateSelection = .none
    @State var duration: DurationSelection = .none
    
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
                TextField("목표 이름을 설정해주세요", text: $projectName)
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
                        .foregroundColor(startDate == .today ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .background(startDate == .today ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            self.startDate = .today
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(startDate == .today ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    Text("내일")
                        .foregroundColor(startDate == .tomorrow ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .background(startDate == .tomorrow ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            self.startDate = .tomorrow
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(startDate == .tomorrow ? 0 : 1)
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
                .opacity(duration == .none ? 0 : 1)
            }
            
            HStack {
                ZStack {
                    Text("7일")
                        .foregroundColor(duration == .one ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .background(duration == .one ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            self.duration = .one
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(duration == .one ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    Text("14일")
                        .foregroundColor(duration == .two ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .background(duration == .two ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            self.duration = .two
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(duration == .two ? 0 : 1)
                }
                .cornerRadius(24)
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                ZStack {
                    Text("21일")
                        .foregroundColor(duration == .three ? .white : Color(hex: "B3B3B3"))
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .background(duration == .three ? Color.theme.mainPurpleColor : .white)
                        .onTapGesture {
                            self.duration = .three
                        }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                        .opacity(duration == .three ? 0 : 1)
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
                                self.duration = .fourth
                            })
                            Button("5주", action: {
                                self.duration = .fifth
                            })
                            Button("6주", action: {
                                self.duration = .sixth
                            })
                            Button("7주", action: {
                                self.duration = .seventh
                            })
                            Button("8주", action: {
                                self.duration = .eighth
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
            .background(Color.theme.greyColor)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .onTapGesture {
                print("프로젝트 시작하기")
            }
    }

}

extension AddProjectView {
    func showSelectionButtonText() -> String {
        switch duration {
        case .none, .one, .two, .three:
            return "선택"
        case .fourth:
            return "4주"
        case .fifth:
            return "5주"
        case .sixth:
            return "6주"
        case .seventh:
            return "7주"
        case .eighth:
            return "8주"

        }
    }
    
    func isSelected4Weeks() -> Bool {
        switch duration {
        case .none, .one, .two, .three:
            return false
        default:
            return true
        }
    }
}
