//
//  GuideView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/09/21.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct GuideView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                    .frame(height: 18)
                
                topArea
                
                firstImage

                secondImage

                thirdImage
                
                fourthImage
                
                fifthImage
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("가이드북")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button {
                    dismiss.callAsFunction()
                    
                } label: {
                    Image("left_arrow_home")
                }
            }
        }
    }
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView()
    }
}

extension GuideView {
    private var topArea: some View {
        VStack {
            HStack {
                Text("투두팡")
                    .font(.appleSDGothicNeo(.bold, size: 18))
                    .foregroundColor(.theme.mainPurpleColor)
                Spacer()
            }
            .padding(.leading, 16)
            
            Spacer()
                .frame(height: 25)
            
            ZStack {
                HStack {
                    Text("투두팡 사용법이 궁금해?\n나만 믿고 따라와!")
                        .font(.appleSDGothicNeo(.bold, size: 24))
                        .foregroundColor(Color(hex: "3B3B3B"))
                    Spacer()
                }
                .padding(.leading, 16)
                
                Image("bomb_smile")
                .frame(width: 28, height: 30)
                .padding(.leading, 120)
                .padding(.top, 30)
            }
            .padding(.bottom, 9)
        }
    }
    
    private var firstImage: some View {
        VStack {
            Spacer()
                .frame(height: 80)
            
            Image("guide_image1")
                .frame(height: 284)
        }
    }
    
    private var secondImage: some View {
        VStack {
            Spacer()
                .frame(height: 20)
            
            Image("guide_image2")
                .frame(height: 306)

        }
    }
    
    private var thirdImage: some View {
        VStack {
            Spacer()
                .frame(height: 20)
            
            Image("guide_image3")
                .frame(height: 284)
        }
    }
    
    private var fourthImage: some View {
        VStack {
            Spacer()
                .frame(height: 20)
            
            Image("guide_image4")
                .frame(height: 284)
        }
    }
    
    private var fifthImage: some View {
        VStack {
            Spacer()
                .frame(height: 40)
            
            Image("guide_image5")
                .frame(height: 91)
        }
    }
    
    
}
