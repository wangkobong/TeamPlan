//
//  TermsDataService.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine

final class TermsDataService {
    
    @Published var allAgreeButton = TermsModel(title: "전체 동의", isSelected: false, buttonState: .wholeButton)
    @Published var termsList: [TermsModel] = []
    var terms: AnyCancellable?
    
    init() {
        getTerms()
    }
    
    func getTerms() {
        // 나중에 이곳에서 fetch terms
        
        let termsDataFromServer: [TermsModel] = [
            TermsModel(title: "서비스 이용약관 동의", isSelected: false, buttonState: .necessaryButton),
            TermsModel(title: "개인정보 수집 및 이용 동의", isSelected: false, buttonState: .necessaryButton),
            TermsModel(title: "마케팅 활용/광고성 정보 수신 동의", isSelected: false, buttonState: .optionalButton),
        ]
        self.termsList = termsDataFromServer
    }
}

