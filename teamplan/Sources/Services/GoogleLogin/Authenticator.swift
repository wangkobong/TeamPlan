//
//  Authenticator.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/05/02.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import GoogleSignIn

final class Authenticator: ObservableObject{
    
    // ViewModel 객체
    private var authViewModel: GoogleAuthViewModel
    
    // 인증관리자 생성자
    init(authViewModel: GoogleAuthViewModel){
        self.authViewModel = authViewModel
    }
    
    // 로그인
    func signIn(){
        
        // rootViewController 존재여부 확인
        guard let rootViewController =
                UIApplication.shared.windows.first?.rootViewController else{
            // 없을 시 예외처리
            print("There is no root view controller!")
            return
        }
        
        // 로그인 로직파트
        // signInResult 에 로그인 결과를 담아 return
        // 에러가 담겨져 온 경우, 예외처리를 통해 콘솔에 예외출력 후 null값 return => 예외처리 개선 포인트
        // 로그인 유저가 있는경우 authViewModel 객체의 상태값 추가
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController){
            signInResult, error in
            guard let signInResult = signInResult else{
                print("Error! \(String(describing: error))")
                return
            }
            self.authViewModel.state = .signedIn(signInResult.user)
        }
    }
    
    // 로그아웃
    func signOut(){
        GIDSignIn.sharedInstance.signOut()
        authViewModel.state = .signedOut
    }
    
    
    // 사용자 연결끊김
    // 서비스 오류로 끊긴경우, 콘솔창에 에러메세지 출력 후, 로그아웃 처리
    func disconnect(){
        GIDSignIn.sharedInstance.disconnect{
            error in if let error = error {
                print("Encountered error disconnecting scope: \(error).")
            }
            self.signOut()
        }
    }
}
