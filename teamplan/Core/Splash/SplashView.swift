//
//  SplashView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import Combine

struct SplashView: View {
    
    @State private var loadingText: [String] = "loading ...".map { String($0) }
    @State private var showLoadingText: Bool = false
    @State private var counter: Int = 0
    @State private var loops: Int = 0
    @State private var percent: CGFloat = 0
    
    @Binding var showOnboardingView: Bool
    
    let timerForLoadingText = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let timerForProgressBar = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    
    var body: some View {
        VStack {
            Spacer()
            Image("launchImage")
                .imageScale(.large)
                .frame(width: 343, height: 281, alignment: .center)
            
            VStack {
                CustomProgressView(percent: $percent)
                    .padding(.leading)
                    .padding(.trailing)
                
                if showLoadingText {
                    HStack(spacing: 0) {
                        ForEach(loadingText.indices, id: \.self) { index in
                            Text(loadingText[index])
                                .font(.appleSDGothicNeo(.semiBold, size: 15))
                                .padding(.bottom)
                                .offset(y: counter == index ? -5 : 0)
                        }
                    }
                    .transition(AnyTransition.scale.animation(.easeIn))
                }
            }
            Spacer()
        }
        .onAppear { showLoadingText.toggle() }
        .onReceive(timerForLoadingText, perform: { _ in
            withAnimation(.spring()) {
                
                let lastIndex = loadingText.count - 1
                if counter == lastIndex {
                    counter = 0
                    loops += 1
                    if loops >= 3 {
                        showOnboardingView = false
                    }
                } else {
                    counter += 1
                }
            }
        })
        .onReceive(timerForProgressBar, perform: { _ in
            withAnimation(.spring()) {
                if percent < 1.0 {
                    percent += 0.25
                }
            }
        })
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(showOnboardingView: .constant(true))
    }
}


struct CustomProgressView: View {
    
    @Binding var percent: CGFloat
    var body: some View {
        let width = UIScreen.main.bounds.width - 18 - 18
        ZStack(alignment: .leading) {
            
            ZStack(alignment: .trailing) {
                Capsule()
                    .fill(.black.opacity(0.08))
                    .frame(width: width, height: 10)
            }
            Capsule()
                .fill(
                    LinearGradient(gradient: Gradient(colors: [.theme.mainBlueColor, .theme.mainPurpleColor]), startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: calPercent(), height: 12)
        }
    }
    
    func calPercent() -> CGFloat {
        let width = UIScreen.main.bounds.width - 18 - 18
        return width * percent
    }
    
}
