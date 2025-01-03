//
//  PreviewProvider.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import SwiftUI

extension PreviewProvider {
    static var dev: DeveloperPreview {
        return DeveloperPreview.instance
    }
}

final class DeveloperPreview {
    
    static let instance = DeveloperPreview()
    private init() { }
    
    let termsViewModel = TermsViewModel()
}
