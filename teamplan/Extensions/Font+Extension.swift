//
//  Font+Extension.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI

extension Font {

    enum AppleSDGothicNeoFont {
        case regular
        case thin
        case ultraLight
        case light
        case medium
        case semiBold
        case bold
        
        var value: String {
            switch self {
            case .regular: return "AppleSDGothicNeo-Regular"
            case .thin: return "AppleSDGothicNeo-Thin"
            case .ultraLight: return "AppleSDGothicNeo-UltraLight"
            case .light: return "AppleSDGothicNeo-Light"
            case .medium: return "AppleSDGothicNeo-Medium"
            case .semiBold: return "AppleSDGothicNeo-SemiBold"
            case .bold: return "AppleSDGothicNeo-Bold"
            }
        }
    }
    
    enum ArchivoBlack {
        case regular
        
        var value: String {
            switch self {
            case .regular: return "ArchivoBlack-Regular"
            }
        }
    }
    

    
    static func appleSDGothicNeo(_ type: AppleSDGothicNeoFont, size: CGFloat) -> Font {
        return .custom(type.value, size: size)
    }
    
    static func archivoBlack(_ type: ArchivoBlack, size: CGFloat) -> Font {
        return .custom(type.value, size: size)
    }
}

