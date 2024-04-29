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
    @Published var wholeTermsButton: TermsModel? = nil
    @Published var isAgree: Bool = false

    private let termsDataService = TermsDataService()
    private var cancellables = Set<AnyCancellable>()
    
    private var requiredTermsCount = 2
    private var allAgreeCount = 3
    
    private var requiredTermsArray: [TermsModel] = []
    private var AgreeTermsArray: [TermsModel] = []
    
    private var isAllAgree = false
    
    init() {
        self.addSubscribers()
    }
    
    private func addSubscribers() {
        termsDataService.$termsList
            .sink { [weak self] termsList in
                self?.termsList = termsList
                termsList.forEach {
                    if $0.buttonState == .necessaryButton {
                        self?.requiredTermsCount += 1
                    }
                }
            }
            .store(in: &cancellables)
        
        termsDataService.$allAgreeButton
            .sink { [weak self] allAgree in
                self?.wholeTermsButton = allAgree
            }
            .store(in: &cancellables)
    }
    
    func didTapAllAgreeButton() {
        wholeTermsButton?.isSelected.toggle()
        if let isSelected = wholeTermsButton?.isSelected {
            termsList.indices.forEach { [weak self] index in
                self?.termsList[index].isSelected = isSelected
                self?.allAgreeCount = self?.termsList.count ?? 0
            }
        }
        
        self.isAgree = wholeTermsButton?.isSelected == true ? true : false
        self.requiredTermsCount = wholeTermsButton?.isSelected == true ? 2 : 0
    }
    
    func didTapOptionalTermsButton(terms: TermsModel) {
        guard let index = termsList.firstIndex(where: {$0.id == terms.id}) else { return }
        termsList[index].isSelected.toggle()
        
        if termsList[index].isSelected {
            wholeTermsButton?.isSelected = self.requiredTermsCount == 2 ? true : false
        } else {
            wholeTermsButton?.isSelected = false
        }
    }
    
    func didTapRequiredTermsButton(terms: TermsModel) {
        guard let index = termsList.firstIndex(where: {$0.id == terms.id}) else { return }
        termsList[index].isSelected.toggle()
        
        if termsList[index].isSelected == true {
            requiredTermsArray.append(termsList[index])
        } else {
            guard let requiredTermsArrayIndex = requiredTermsArray.firstIndex(where: {$0.id == terms.id}) else { return }
            requiredTermsArray.remove(at: requiredTermsArrayIndex)
        }
        
        isAgree = requiredTermsCount == requiredTermsArray.count ? true : false
    }
}
