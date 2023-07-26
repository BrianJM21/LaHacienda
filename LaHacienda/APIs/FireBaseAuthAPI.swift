//
//  FireBaseAuthAPI.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import FirebaseAuth

class EmailAuthAPI: LoginService {
    
    init() {
        authListener = auth.addStateDidChangeListener{ [weak self] _, user in
            self?.isAuthenticated = user != nil
        }
    }
    
    private let auth = Auth.auth()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var isAuthenticated = false {
        willSet(newValue) {
            print("USUARIO LOGUEADO: \(newValue) - \(auth.currentUser?.displayName ?? "NIL")")
        }
    }
    
    func logIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error {
                completion(.failure(error))
            } else if let authResult {
                completion(.success(authResult.user))
            } else {
                completion(.failure(AuthError.userIsNil))
            }
        }
    }
    
    func signUp(userData: [String], completion: @escaping (Result<User, Error>) -> Void) {
        auth.createUser(withEmail: userData[3], password: userData[4]) { authResult, error in
            if let error {
                completion(.failure(error))
            } else if let authResult {
                Task {
                    try await authResult.user.updateProfile(\.displayName, to: userData[3])
                }
                completion(.success(authResult.user))
            } else {
                completion(.failure(AuthError.userIsNil))
            }
        }
    }
    
    func logOut(completion: @escaping (Result<User, Error>) -> Void) {
        do {
            guard let user = auth.currentUser else { completion(.failure(AuthError.userIsNil)); return }
            try auth.signOut()
            completion(.success(user))
        } catch {
            completion(.failure(error))
        }
    }
    
}

private extension FirebaseAuth.User {
    
    func updateProfile<T>(_ keyPath: WritableKeyPath<UserProfileChangeRequest, T>, to newValue: T) async throws {
        var profileChangeRequest = createProfileChangeRequest()
        profileChangeRequest[keyPath: keyPath] = newValue
        try await profileChangeRequest.commitChanges()
    }
}
