//
//  TestColorView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/15.
//

import SwiftUI

struct TestColorView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.title)
                .bold()
                .foregroundColor(.theme.blackColor)
            Text("Hello, World!")
                .font(.title)
                .bold()
                .foregroundColor(.theme.darkGreyColor)
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.title)
                .bold()
                .foregroundColor(.theme.greyColor)
            Text("Hello, World!")
                .font(.title)
                .bold()
                .foregroundColor(.theme.mainBlueColor)
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.title)
                .bold()
                .foregroundColor(.theme.mainPurpleColor)
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.title)
                .bold()
                .foregroundColor(.theme.whiteColor)
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.title)
                .bold()
                .foregroundColor(.theme.whiteGreyColor)
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .font(.title)
                .bold()
                .foregroundColor(.theme.warningRedColor)
        }
    }
}

struct TestColorView_Previews: PreviewProvider {
    static var previews: some View {
        TestColorView()
    }
}
