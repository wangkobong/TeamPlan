//
//  GoogleAuthViewModel.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/05/02.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI
import GoogleSignIn

final class GoogleAuthViewModel: ObservableObject{
    
    var state: State
    private var authenticator: Authenticator{
        return Authenticator(authViewModel: self)
    }
    
    // 사용자 상태값 설정
    var authorizedScopes: [String] {
      switch state {
      case .signedIn(let user):
        return user.grantedScopes ?? []
      case .signedOut:
        return []
      }
    }

    // ViewModel 생성자
    init() {
      if let user = GIDSignIn.sharedInstance.currentUser {
        self.state = .signedIn(user)
      } else {
        self.state = .signedOut
      }
    }

    // 로그인
    func signIn() {
      authenticator.signIn()
    }

    // 로그아웃
    func signOut() {
      authenticator.signOut()
    }

    // 연결끊김
    func disconnect() {
      authenticator.disconnect()
    }
}

// 사용자상태 Enum
extension GoogleAuthViewModel{
    enum State {
      case signedIn(GIDGoogleUser)
      case signedOut
    }
}
