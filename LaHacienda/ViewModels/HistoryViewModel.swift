//
//  HistoryViewModel.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 24/07/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class HistoryViewModel {
    
    private let currentUserEmail = {
        guard let email = Auth.auth().currentUser?.displayName else { return "" }
        return email
    }()
    private let refOrderCollection = Firestore.firestore().collection(FSCollections.orders.rawValue)
    
    func fetchOrders(completion: @escaping (Result<[Order], Error>) -> Void) {
        refOrderCollection.whereField("userEmail", isEqualTo: currentUserEmail).getDocuments { snapshot, error in
            if let error { completion(.failure(error)) }
            guard let orders = snapshot?.documents.map({ try? $0.data(as: Order.self) }).compactMap({ $0 }).sorted(by: { $0.orderNumber < $1.orderNumber }) else { completion(.failure(OrderError.orderIsNil)); return }
            if orders.isEmpty {
                completion(.failure(OrderError.historyIsEmpty))
            } else {
                completion(.success(orders))
            }
        }
    }
}
