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

final class AuthAppleService {

    // MARK: - Login
//
//    func login(
//        appleCredential: ASAuthorizationAppleIDCredential,
//        completion: @escaping(Result<AuthSocialLoginResDTO, Error>) -> Void
//    ) async {
//        guard let appleIDToken = appleCredential.identityToken else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
//            return
//        }
//        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])))
//            return
//        }
//        let credential = OAuthProvider.credential(
//            withProviderID: "apple.com",
//            idToken: idTokenString,
//            rawNonce: randomNonceString()
//        )
//        
//        do {
//            let authResult = try await Auth.auth().signIn(with: credential)
//            let userType = authResult.additionalUserInfo?.isNewUser == true ? UserType.new : UserType.exist
//            
//            completion(.success(AuthSocialLoginResDTO(loginResult: authResult.user, idToken: idTokenString, userType: userType)))
//        } catch {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
//        }
//    }
    
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
        return self.sha256(result)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
