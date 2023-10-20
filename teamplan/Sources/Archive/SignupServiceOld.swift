//
//  SignupService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
/*
 
 import Foundation
 
 final class SignupService{
 
 let cd = UserServicesCoredata()
 let fs = UserServicesFirestore()
 
 //===============================
 // MARK: - Set Profile: Signup
 //===============================
 /// * Input:
 ///   * UserDTO/UserSignupLocalReqDTO
 /// * Success Output(String)
 ///   * "Successfully Set NewUser"
 /// * Failed Output(String)
 ///   * "Invalid Email Format!" or "An Unknown Error Occurred"
 func setUser(reqUser: UserSignupReqDTO) async -> String {
 
 var docsId: String = "nil"
 
 do{
 let newUser = try structNewUser(reqUser: reqUser)
 
 // Set Firestore
 fs.setUserFirestore(reqUser: newUser){ result in
 switch result {
 case .success(let addDocsId):
 docsId = addDocsId
 print("Successfully added user with document ID: \(docsId)")
 case .failure(let error):
 print("Failed to add user: \(error)")
 }
 }
 
 // Create UserObject
 let newUserObject = UserObject(newUser: newUser, docsId: docsId)
 
 // Set CoreData
 await cd.setUserCoredata(userObject: newUserObject)
 
 // Exception : Invalid Email Type
 } catch EmailError.invalidFormat {
 print("Invalid Email Format!")
 return "Invalid Email Format!"
 
 // Exception : Unknown
 } catch let error {
 print("An error occurred: \(error.localizedDescription)")
 return "An Unknown Error Occurred"
 }
 
 // Success
 return "Successfully Set NewUser"
 }
 
 func structNewUser(reqUser: UserSignupReqDTO) throws -> UserSignupServerReqDTO{
 
 let identifier = "\(reqUser.socialType)_\(try extractIdentifier(email: reqUser.email))"
 
 return UserSignupServerReqDTO(reqUser: reqUser, identifier: identifier)
 }
 
 func extractIdentifier(email: String) throws -> String {
 guard let atIndex = email.firstIndex(of: "@"),
 atIndex != email.startIndex else {
 throw EmailError.invalidFormat
 }
 return String(email.prefix(upTo: atIndex))
 }
 
 enum EmailError: Error {
 case invalidFormat
 }
 }
 
 */
