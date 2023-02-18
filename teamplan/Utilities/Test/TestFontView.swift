//
//  TestFontView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI

struct TestFontView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("AppleSDGothicNeo Regular")
                .font(.appleSDGothicNeo(.regular, size: 20))
            Text("AppleSDGothicNeo Thin")
                .font(.appleSDGothicNeo(.thin, size: 20))
            Text("AppleSDGothicNeo UltraLight")
                .font(.appleSDGothicNeo(.ultraLight, size: 20))
            Text("AppleSDGothicNeo Light")
                .font(.appleSDGothicNeo(.light, size: 20))
            Text("AppleSDGothicNeo Medium")
                .font(.appleSDGothicNeo(.medium, size: 20))
            Text("AppleSDGothicNeo Semibold")
                .font(.appleSDGothicNeo(.semiBold, size: 20))
            Text("AppleSDGothicNeo Bold")
                .font(.appleSDGothicNeo(.bold, size: 20))
            Text("ArchivoBlack Regular")
                .font(.archivoBlack(.regular, size: 20))
        }
        .onAppear {
            let fonts = UIFont.familyNames
            
            for font in fonts {
                print("-----------")
                print("Font Family name -> [\(font)]")
                let names = UIFont.fontNames(forFamilyName: font)
                print("Font names --> [\(names)]")
            }
        }
    }
}

struct TestFontView_Previews: PreviewProvider {
    static var previews: some View {
        TestFontView()
    }
}
