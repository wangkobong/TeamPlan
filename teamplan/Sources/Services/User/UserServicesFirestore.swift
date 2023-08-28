//
//  UserServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class UserServicesFirestore{
    
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set User: SignUp
    //================================
    func setUserFirestore(reqUser: UserSignupServerReqDTO, result: @escaping(Result<String, Error>) -> Void){
        
        let collectionRef = fs.collection("User")
        var docsRef: DocumentReference? = nil
        
        docsRef = collectionRef.addDocument(data: reqUser.toDictionary()){
            error in if let error = error {
                print("Adding document failed: \(error)")
                result(.failure(error))
            } else {
                print("Added DocumentID: \(docsRef!.documentID)")
                result(.success(docsRef!.documentID))
            }
        }
    }
}


