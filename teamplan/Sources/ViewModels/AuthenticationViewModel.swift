//
//  AuthenticationViewModel.swift
//  teamplan
//
//  Created by 송하민 on 3/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import KeychainSwift
import AuthenticationServices
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

final class AuthenticationViewModel: ObservableObject {

    enum State {
        case signedIn
        case signedOut
    }

    enum SignupError: Error {
        case invalidUser
        case invalidAccountInfo
        case signupFailed
    }
    
    enum loginAction: Equatable {
        case loginGoogle
        case loginApple
    }
    
    // MARK: - properties
    
    // published
    @Published var isReSignupNeeded: Bool = false
    
    // private
    private let signupService = SignupService()
    private let voltManager = VoltManager.shared
    
    //MARK: - Signup
    
    func classifyFunction() -> Bool {
        if let userId = voltManager.getUserId(),
           let userName = voltManager.getUserName() {
            return true
        } else {
            return false
        }
    }
    
    //MARK: - Signup
    
    func trySignup(userName: String) async -> Bool {

        // set: new user data at Local & volt
        guard signupService.executor(with: userName) else {
            print("[AuthViewModel] Failed to proceed signup process")
            await changeStatus()
            return false
        }
        print("[AuthViewModel] Successfully proceed signup")
        return true
    }
    
    // MARK: - Login
    
    func tryLogin(userId: String) async -> Bool {
        
        // check: userId
        guard let userId = voltManager.getUserId() else {
            print("[AuthViewModel] Failed to get userData from volt")
            await changeStatus()
            return false
        }
        let loginService = LoginService.initService(with: userId)
        
        if await loginService.executor() {
            print("[AuthViewModel] Login Process Success")
            return true
        } else {
            print("[AuthViewModel] Login Process Failed")
            await changeStatus()
            return false
        }
    }
    
    func tryGoogleLogin() async throws {
        // 1. Google Sign In 설정
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController
        else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID not found"])
        }
        
        // 2. GIDSignIn 설정
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        print("Configuration set successfully") // 디버깅용 로그

        // 3. 로그인 시도
        return try await withCheckedThrowingContinuation { continuation in
            print("Attempting sign in") // 디버깅용 로그
            
            DispatchQueue.main.async {
                  GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                      print("Sign in callback received")
                      
                      if let error = error {
                          continuation.resume(throwing: error)
                      }
                      
                      guard let result = result,
                            let idToken = result.user.idToken?.tokenString else {
                          continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"]))
                          return
                      }
                      
                      let credential = GoogleAuthProvider.credential(
                          withIDToken: idToken,
                          accessToken: result.user.accessToken.tokenString
                      )
                                                
                      Task {
                          do {
                              let authResult = try await Auth.auth().signIn(with: credential)
                              let user = authResult.user
 
                              continuation.resume(returning: ())
                          } catch {
                              continuation.resume(throwing: error)
                          }
                      }
                  }
              }
        }
    }
    
    func tryAppleLogin() async throws {
         let nonce = String.randomNonceString()
         let appleIDProvider = ASAuthorizationAppleIDProvider()
         let request = appleIDProvider.createRequest()
         request.requestedScopes = [.fullName, .email]
         request.nonce = nonce.sha256()
         
         return try await withCheckedThrowingContinuation { continuation in
             DispatchQueue.main.async {
                 let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                 let delegate = SignInWithAppleDelegate { result, error in
                     if let error = error {
                         continuation.resume(throwing: error)
                         return
                     }
                     
                     guard let result = result,
                           let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                           let appleIDToken = appleIDCredential.identityToken,
                           let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                         continuation.resume(throwing: NSError(domain: "", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
                         return
                     }
                     
                     let credential = OAuthProvider.credential(
                         providerID: AuthProviderID.apple,
                         idToken: idTokenString,
                         rawNonce: nonce,
                         accessToken: nil // 선택적 파라미터
                     )
                     
                     Task {
                         do {
                             try await Auth.auth().signIn(with: credential)
                             
                             let authResult = try await Auth.auth().signIn(with: credential)
                             let user = authResult.user

                             continuation.resume(returning: ())
                         } catch let signInError as NSError {
                             print("Firebase sign in error: \(signInError.localizedDescription)")
                             continuation.resume(throwing: signInError)
                         } catch {
                             print("Unexpected error: \(error.localizedDescription)")
                             continuation.resume(throwing: error)
                         }
                     }
                 }
                 
                 authorizationController.delegate = delegate
                 authorizationController.presentationContextProvider = delegate
                 objc_setAssociatedObject(authorizationController, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
                 
                 authorizationController.performRequests()
             }
         }
    }
    
    @MainActor
    private func changeStatus() {
        isReSignupNeeded = true
    }
    
    private class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        private let completion: (ASAuthorization?, Error?) -> Void
        
        init(completion: @escaping (ASAuthorization?, Error?) -> Void) {
            self.completion = completion
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                fatalError("No window found")
            }
            return window
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            completion(authorization, nil)
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            completion(nil, error)
        }
    }
}
