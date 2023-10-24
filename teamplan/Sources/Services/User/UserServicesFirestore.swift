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

    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set User: SignUp
    //================================
    func setUserFirestore(reqUser: UserObject,
                          result: @escaping(Result<String, Error>) -> Void) {
        // Target Table
        let collectionRef = fs.collection("User")
        
        // Add User
        var docsRef: DocumentReference? = nil
        docsRef = collectionRef.addDocument(data: reqUser.toDictionary()){ error in
            
            // Exception Handling: Firestore
            if let error = error {
                result(.failure(error))
                
            // Return Firestore DocumnetID
            } else {
                result(.success(docsRef!.documentID))
            }
        }
    }
}


