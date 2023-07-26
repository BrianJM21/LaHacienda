//
//  OrderViewModel.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 20/07/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class OrderViewModel {
    
    private let refOrderCollection = Firestore.firestore().collection(FSCollections.orders.rawValue)
    private let refUserCollection =
    Firestore.firestore().collection(FSCollections.laHaciendaUsers.rawValue)
    @Published var userPhone = ""
    @Published var userAddress = ""
    @Published var activeOrder: Order?
    private var userListener: ListenerRegistration?
    
    func fetchActiveOrder(userEmail: String, completion: @escaping (Result<Order, Error>) -> Void) {
        refOrderCollection.whereField("userEmail", isEqualTo: userEmail).whereField("status", isLessThan: 98).getDocuments(completion: { [weak self] snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let document = snapshot?.documents.first else { completion(.failure(OrderError.orderIsNil)); return }
            self?.refOrderCollection.document(document.documentID).addSnapshotListener { snapshot, error in
                if let error { completion(.failure(error)); return }
                guard let snapshot else { return }
                do {
                    let order = try snapshot.data(as: Order.self)
                    completion(.success(order))
                    self?.activeOrder = order
                } catch {
                    completion(.failure(error))
                }
            }
        })
    }
    
    func placeOrder(_ order: Order, completion: @escaping (Result<Order, Error>) -> Void) {
        do {
            try refOrderCollection.document(order.id.uuidString).setData(from: order) { [weak self] error in
                if let error {
                    completion(.failure(error))
                } else {
                    self?.refOrderCollection.document(order.id.uuidString).addSnapshotListener { snapshot, error in
                        if let error { completion(.failure(error)); return }
                        guard let snapshot else { return }
                        do {
                            let order = try snapshot.data(as: Order.self)
                            completion(.success(order))
                            self?.activeOrder = order
                        } catch {
                            completion(.failure(error))
                        }
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func currentOrderNumber(userEmail: String, completion: @escaping (Result<Int, Error>) -> Void) {
        refOrderCollection.whereField("userEmail", isEqualTo: userEmail).getDocuments { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let document = snapshot else { completion(.failure(OrderError.orderIsNil)); return }
            completion(.success(document.count + 1))
            
        }
    }
    
    func fetchUser(userEmail: String, completion: @escaping (Result<LaHaciendaUser, Error>) -> Void) {
        userListener = refUserCollection.document(userEmail).addSnapshotListener { [weak self] snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else { return }
            do {
                let user = try snapshot.data(as: LaHaciendaUser.self)
                completion(.success(user))
                if self?.userPhone != user.phone {
                    self?.userPhone = user.phone
                }
                if self?.userAddress != user.address {
                    self?.userAddress = user.address
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func removeUserListener() {
        userListener?.remove()
    }
    
    func updateActiveOrder(atField field: OrderField, with newValue: Any, completion: @escaping (Result<Order?, Error>) -> Void = {_ in}) {
        guard let order = activeOrder else { return }
        switch field {
        case .status:
            guard let status = newValue as? Int else { return }
            refOrderCollection.document(order.id.uuidString).updateData([OrderField.status.rawValue: status]) { [weak self] error in
                if let error { completion(.failure(error)); return }
                self?.activeOrder?.status = status
                completion(.success(self?.activeOrder))
            }
        case .payment:
            guard let payment = newValue as? Int else { return }
            refOrderCollection.document(order.id.uuidString).updateData([OrderField.payment.rawValue: payment]) { [weak self] error in
                if let error { completion(.failure(error)); return }
                self?.activeOrder?.payment = payment
                completion(.success(self?.activeOrder))
            }
        case .comments:
            guard let comments = newValue as? [String] else { return }
            refOrderCollection.document(order.id.uuidString).updateData([OrderField.comments.rawValue: comments]) { [weak self] error in
                if let error { completion(.failure(error)); return }
                self?.activeOrder?.comments = comments
                completion(.success(self?.activeOrder))
            }
        }
    }
}
