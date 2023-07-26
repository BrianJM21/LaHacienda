//
//  HomeViewModel.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 25/07/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class HomeViewModel {
    
    private let currentUserEmail = {
        guard let email = Auth.auth().currentUser?.displayName else { return "" }
        return email
    }()
    private let refOrderCollection = Firestore.firestore().collection(FSCollections.orders.rawValue)
    private let refUserCollection = Firestore.firestore().collection(FSCollections.laHaciendaUsers.rawValue)
    private var currentUserListener: ListenerRegistration?
    private var activeOrderListener: ListenerRegistration?
    @Published var activeOrder: Order?
    @Published var currentUser: LaHaciendaUser?
    
    func fetchActiveOrder(completion: @escaping (Result<Order, Error>) -> Void) {
        refOrderCollection.whereField("userEmail", isEqualTo: currentUserEmail).whereField("status", isLessThan: 98).getDocuments(completion: { [weak self] snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let document = snapshot?.documents.first else { completion(.failure(OrderError.orderIsNil)); return }
            do {
                let order = try document.data(as: Order.self)
                completion(.success(order))
                self?.activeOrder = order
            } catch {
                completion(.failure(error))
            }
            self?.activeOrderListener = self?.refOrderCollection.document(document.documentID).addSnapshotListener { snapshot, error in
                if error == nil { self?.activeOrder = try? snapshot?.data(as: Order.self) }
            }
        })
    }
    
    func removeActiveOrderListener() {
        activeOrderListener?.remove()
    }
    
    func fetchLastOrder(completion: @escaping (Result<Order, Error>) -> Void) {
        refOrderCollection.whereField("userEmail", isEqualTo: currentUserEmail).whereField("status", isGreaterThanOrEqualTo: 98).getDocuments { snapshot, error in
            if let error { completion(.failure(error)) }
            guard let order = snapshot?.documents.map({ try? $0.data(as: Order.self) }).compactMap({ $0 }).sorted(by: { $0.orderNumber < $1.orderNumber }) else { completion(.failure(OrderError.orderIsNil)); return }
            if let lastOrder = order.last {
                completion(.success(lastOrder))
            } else {
                completion(.failure(OrderError.historyIsEmpty))
            }
        }
    }
    
    func fetchUser(completion: @escaping (Result<LaHaciendaUser, Error>) -> Void) {
        refUserCollection.document(currentUserEmail).getDocument(completion: { [weak self] document, error in
            if let error { completion(.failure(error)); return }
            guard let user = try? document?.data(as: LaHaciendaUser.self) else { completion(.failure(AuthError.userIsNil)); return }
            completion(.success(user))
            self?.currentUserListener = self?.refUserCollection.document(user.email).addSnapshotListener { [weak self] snapshot, error in
                if error == nil { self?.currentUser = try? snapshot?.data(as: LaHaciendaUser.self) }
            }
        })
    }
    
    func removeCurrentUserListener() {
        currentUserListener?.remove()
    }
}
