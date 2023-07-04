//
//  TermsViewModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine

final class TermsViewModel: ObservableObject {
    
    @Published var termsList: [TermsModel] = []

    private let termsDataService = TermsDataService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.addSubscribers()
    }
    
    private func addSubscribers() {
        termsDataService.$termsList
            .sink { [weak self] termsList in
                self?.termsList = termsList
            }
            .store(in: &cancellables)
        
//        $isChecked
//            .sink { isClicked in
//                print(isClicked)
//            }
//            .store(in: &cancellables)
    }
    
    func test(index: Range<Array<String>.Index>.Element?) {
        guard let index = index else { return }
        print(termsList[index])
    }
}
