//
//  TermsDetailView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

enum ButtonState {
    case wholeButton
    case necessaryButton
    case optionalButton
}

struct TermsDetailView: View {
    
    @EnvironmentObject private var viewModel: TermsViewModel
    @State var buttonState: ButtonState
    @State var isChecked: Bool = false
    @State var isCheckedWholeButton: Bool
    var terms: TermsModel

    
    var body: some View {
        VStack {
            HStack {
                Button {
//                    isChecked.toggle()
//                    if buttonState == .wholeButton {
//                        print("전체동의버튼 클릭")
//                        viewModel.termsList.forEach {
//                            $0.isSelected.toggle()
//                        }
//                    }
                    
//                    test()
//                    print(terms.id)
//                    var index: Range<Array<String>.Index>.Element? = nil
//                    ForEach(viewModel.termsList.indices, id: \.self) { index2 in
//                        index = index2
//                    }
//                    viewModel.test(index: index)
                } label: {
                    Image(systemName: isChecked ? "heart.fill" : "heart")
                }
                Text(terms.title)
                    .foregroundColor(Color(hex: "4B4B4B"))
                    .font(.appleSDGothicNeo(.regular, size: 18))
                
                switch buttonState {
                case .wholeButton:
                    Text(" ")
                        .opacity(0.0)
                        .font(.appleSDGothicNeo(.bold, size: 16))
                case .necessaryButton:
                    Text("(필수)")
                        .foregroundColor(.theme.mainBlueColor)
                        .font(.appleSDGothicNeo(.bold, size: 16))
                case .optionalButton:
                    Text("(선택)")
                        .foregroundColor( Color(hex: "4B4B4B"))
                        .font(.appleSDGothicNeo(.bold, size: 16))
                }
                
                Spacer()
            }
            .padding(.horizontal, 26)
            
        }
    }
    
    func test() {
//        ForEach(viewModel.termsList.indices, id: \.self) { index in
//            print("index: \(index)")
//        }
        guard let index = viewModel.termsList.firstIndex(where: {$0.id == terms.id}) else { return }
        print(terms.id)
        print("index: \(index)")
    }
}

struct TermsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        
        TermsDetailView(buttonState: .necessaryButton, isCheckedWholeButton: false, terms: TermsModel(title: "서비스 이용약관 동의", isSelected: false, buttonState: .optionalButton))
        //.previewLayout(.sizeThatFits)
    }
}


