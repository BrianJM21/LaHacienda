//
//  AppTools.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 17/07/23.
//

import Foundation
import UIKit

let bottlePrice = 20.0
let accountHolder = "La Hacienda Purificadora"
let bank = "Banco Ficticio"
let clabe = "123456789123456789"

enum AuthError: Error {
    case userIsNil
}

enum OrderError: Error {
    case orderIsNil
    case historyIsEmpty
}

enum FSCollections: String {
    case laHaciendaUsers = "laHaciendaUsers"
    case orders = "orders"
}

enum OrderField: String {
    case payment = "payment"
    case comments = "comments"
    case status = "status"
}

class CustomSettingUITextField: UITextField {
    func setOnTextChangeListener(onTextChanged :@escaping () -> Void) {
        self.addAction(UIAction(handler: { action in
            onTextChanged()
        }), for: .editingDidEnd)
    }
}

class HeaderUILabel: UILabel {
    init() {
        super.init(frame: .zero)
        font = .systemFont(ofSize: 30)
        textAlignment = .center
        numberOfLines = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BodyUILabel: UILabel {
    init() {
        super.init(frame: .zero)
        font = .systemFont(ofSize: 17)
        textAlignment = .left
        numberOfLines = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HistoryCollectionViewCell: UICollectionViewCell {
    private let header = HeaderUILabel()
    private let body1 = BodyUILabel()
    private let body2 = BodyUILabel()
    private let body3 = BodyUILabel()
    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [header, body1, body2, body3])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()
    private let container: UIView = {
        let view = UIView(frame: .init(x: 0, y: 0, width: 300, height: 200))
        view.backgroundColor = .systemGray6
        view.layer.shadowOpacity = 1
        view.layer.cornerRadius = 10
        return view
    }()
    
    
    func configUICell(header: String, body: String) {
        addSubview(container)
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor)])
        self.header.text = header
        body1.text = body
    }
    
    func configUICell(orderToDisplay order: Order) {
        addSubview(container)
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor)])
        self.header.text = "Orden #\(order.orderNumber)"
        body1.textAlignment = .center
        body1.layer.cornerRadius = 10
        body1.clipsToBounds = true
        switch order.status {
        case 1: body1.text = "Enviada 📩"; body1.backgroundColor = .systemGray4
        case 2: body1.text = "Despachada 🚰"; body1.backgroundColor = .systemYellow
        case 3: body1.text = "En ruta 🚚"; body1.backgroundColor = .systemYellow
        case 98: body1.text = "Completada ✅"; body1.backgroundColor = .systemGreen
        case 99: body1.text = "Cancelada ⛔️"; body1.backgroundColor = .systemRed
        default: body1.text = "No disponible 😶‍🌫️"
        }
        body2.text = "\nGarrafones pedidos: \(order.numberOfBottles)     $\(order.totalAmount)\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        switch order.payment {
        case 1: body3.text = "Pago: Efectivo 💵 (\(dateFormatter.string(from: order.date)))"
        case 2: body3.text = "Pago: Transferencia 📲 (\(dateFormatter.string(from: order.date)))"
        default: body3.text = "No disponible 😶‍🌫️ (\(dateFormatter.string(from: order.date)))"
        }
    }
}
    
class InfoContainer: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemGray6
        layer.shadowOpacity = 1
        layer.cornerRadius = 10
        widthAnchor.constraint(equalToConstant: 300).isActive = true
        heightAnchor.constraint(equalToConstant: 200).isActive = true
        let stack = UIStackView(arrangedSubviews: [header, body1, body2, body3])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        addSubview(stack)
        addSubview(busy)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stack.topAnchor.constraint(equalTo: self.topAnchor),
            stack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            busy.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            busy.centerYAnchor.constraint(equalTo: self.centerYAnchor)])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let header = HeaderUILabel()
    let body1 = BodyUILabel()
    let body2 = BodyUILabel()
    let body3 = BodyUILabel()
    let busy = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.backgroundColor = UIColor(white: 1, alpha: 0.5)
        activityIndicator.layer.cornerRadius = 5
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
}
