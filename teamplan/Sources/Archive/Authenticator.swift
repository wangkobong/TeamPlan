//
//  Authenticator.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/05/02.
//  Copyright © 2023 team1os. All rights reserved.
//
/*
import Foundation
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

final class Authenticator: NSObject, ObservableObject {
    
    // ViewModel 객체
    private var authViewModel: GoogleAuthViewModel
    
    // 인증관리자 생성자
    init(authViewModel: GoogleAuthViewModel){
        // 인증 ViewModel 생성
        self.authViewModel = authViewModel
        super.init()
        
        // FB 클라이언트ID 생성
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        //FB 클라이언트 값으로 GID설정
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    
    // 로그인
    func signIn(){
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController){
            signInResult, error in
            guard let signInResult = signInResult else{
                print("Error! \(String(describing: error))")
                return
            }
            // 토큰추출 파트
            guard let idToken = signInResult.user.idToken?.tokenString else{
                print("No ID token found")
                return
            }
            
            // Access Token과 비교
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: signInResult.user.accessToken.tokenString)
            
            // FB 사용자 인증
            Auth.auth().signIn(with: credential){ authResult, error in
                guard authResult != nil else{
                    print("Error! \(String(describing: error))")
                    return
                }
                
                if let authUser = authResult?.user {
                    self.authViewModel.user = GoogleUser(authUser: authUser)
                }
                self.authViewModel.state = .signedIn(signInResult.user)
            }
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
*/
