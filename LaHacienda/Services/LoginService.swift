//
//  LoginService.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import FirebaseAuth

protocol LoginService {
    
    func logIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signUp(userData: [String], completion: @escaping (Result<User, Error>) -> Void)
    func logOut(completion: @escaping (Result<User, Error>) -> Void)
}
