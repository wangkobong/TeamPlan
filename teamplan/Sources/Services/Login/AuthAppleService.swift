//
//  AuthAppleServices.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/13.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CryptoKit
import FirebaseAuth
import AuthenticationServices


// MARK: Apple Social Login
final class AuthAppleService {
    
    func login(loginResult: ASAuthorization, nonce: String) async throws -> AuthSocialLoginResDTO {
        
        // Authentication
        let idToken = try extractIdTokenString(loginResult: loginResult)
        let authResult = try await registFirebaseAuth(idToken: idToken, nonce: nonce)

        // Extract Additional Information
        return AuthSocialLoginResDTO(
            identifier: authResult.identifier,
            email: authResult.email,
            provider: .apple,
            idToken: idToken,
            accessToken: idToken,
            status: authResult.status
        )
    }
    
    private func extractIdTokenString(loginResult: ASAuthorization) throws -> String {
        guard let appleIdCredential = loginResult.credential as? ASAuthorizationAppleIDCredential,
              let appleIdToken = appleIdCredential.identityToken,
              let appleIdTokenString = String(data: appleIdToken, encoding: .utf8) else {
            throw AppleSocialLoginError.tokenCreationFailed(serviceName: .appleLogin)
        }
        return appleIdTokenString
    }
    
    private func registFirebaseAuth(idToken: String, nonce: String) async throws -> FirebaseAuthRegistResultDTO {
        
        let credential = OAuthProvider.credential(
            withProviderID: Providers.apple.rawValue,
            idToken: idToken,
            rawNonce: nonce
        )
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            guard let loginInfo = authResult.additionalUserInfo,
                  let userEmail = authResult.user.email else {
                throw AppleSocialLoginError.signInFailed(serviceName: .appleLogin)
            }
            let identifier = authResult.user.uid
            return FirebaseAuthRegistResultDTO(
                identifier: identifier,
                email: userEmail,
                status: loginInfo.isNewUser ? .new : .exist
            )
        } catch {
            print("Firebase Auth sign-in error: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: Nonce
extension AuthAppleService {
    
    func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
