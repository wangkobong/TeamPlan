//
//  Binding+Extension.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

extension Binding {
    func optionalBinding<T>() -> Binding<T>? where T? == Value {
        if let wrappedValue = wrappedValue {
            return Binding<T>(
                get: { wrappedValue },
                set: { self.wrappedValue = $0 }
            )
        } else {
            return nil
        }
    }
}
