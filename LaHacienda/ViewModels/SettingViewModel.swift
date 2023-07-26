//
//  SettingViewModel.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

class SettingViewModel {
    
    private let refCollection = Firestore.firestore().collection(FSCollections.laHaciendaUsers.rawValue)
    let userDocumentPublisher = PassthroughSubject<LaHaciendaUser, Error>()
    
    func fetchUser(userEmail: String, completion: @escaping (Result<LaHaciendaUser, Error>) -> Void) {
        refCollection.document(userEmail).getDocument { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else { completion(.failure(AuthError.userIsNil)); return }
            do {
                try completion(.success(snapshot.data(as: LaHaciendaUser.self)))
                snapshot.reference.addSnapshotListener { [weak self] document, error in
                    if let error { print(error); return }
                    guard let document else { return }
                    self?.reloadUser(document.documentID, completion: { [weak self] result in
                        switch result {
                        case .success(let user):
                            self?.userDocumentPublisher.send(user)
                        case .failure(let error):
                            self?.userDocumentPublisher.send(completion: .failure(error))
                        }
                    })
                }
            } catch {
                completion(.failure(AuthError.userIsNil))
            }
        }
    }
    
    func reloadUser(_ userID: String, completion: @escaping (Result<LaHaciendaUser, Error>) -> Void) {
        refCollection.document(userID).getDocument { snapshot, error in
            if let error { completion(.failure(error)) }
            guard let snapshot else { completion(.failure(AuthError.userIsNil)); return }
            do {
                try completion(.success(snapshot.data(as: LaHaciendaUser.self)))
            } catch {
                completion(.failure(AuthError.userIsNil))
            }
        }
    }
    
    func updateUser(_ user: LaHaciendaUser, newValue: String, atField field: String) {
        refCollection.document(user.email).updateData([field: newValue])
    }
    
    func updateUser(_ user: LaHaciendaUser) {
        refCollection.document(user.email).updateData([
            "name": user.name,
            "phone": user.phone,
            "address": user.address])
    }
}
