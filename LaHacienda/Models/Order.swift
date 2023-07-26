//
//  Order.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 19/07/23.
//

import Foundation

struct Order: Codable {
    let id: UUID
    let orderNumber: Int
    let userEmail: String
    var status: Int
    let numberOfBottles: Int
    let totalAmount: Double
    var payment: Int
    var paymentStatus: Int
    var comments: [String]
    let phone: String
    let address: String
    let date: Date
    
    init(id: UUID, orderNumber: Int, userEmail: String, status: Int, numberOfBottles: Int, totalAmount: Double, payment: Int, paymentStatus: Int, comments: [String], phone: String, address: String) {
        self.id = id
        self.orderNumber = orderNumber
        self.userEmail = userEmail
        self.status = status
        self.numberOfBottles = numberOfBottles
        self.totalAmount = totalAmount
        self.payment = payment
        self.paymentStatus = paymentStatus
        self.comments = comments
        self.phone = phone
        self.address = address
        self.date = Date()
    }
}

// status codes
// 1 - Enviada
// 2 - Despachada
// 3 - En ruta
// 98 - Completada
// 99 - Cancelada

// payment codes
// 1 - Efectivo
// 2 - Transferencia

// paymentStatus codes
// 1 - pendiente
// 2 - pagado
