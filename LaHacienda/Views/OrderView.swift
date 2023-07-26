//
//  OrderView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 19/07/23.
//

import Foundation
import UIKit
import FirebaseAuth
import Combine

class OrderView: NSObject, TabViewService, UIPickerViewDelegate, UIPickerViewDataSource {
    
    init(viewController: UIViewController, delegate: TabViewDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    }
    
    deinit {
        print("SE DESTRUYÓ ORDER VIEW")
    }
    
    unowned var viewController: UIViewController
    weak var delegate: TabViewDelegate?
    private let viewModel = OrderViewModel()
    private let currentUserEmail = {
        guard let email = Auth.auth().currentUser?.displayName else { return "" }
        return email
    }()
    private var orderNumberInt = 0
    private var numberOfRowsInComponent = 0
    private var dataForRows = [""]
    private var selectedNumberOfBottles = 0
    private var selectedPayment = 0
    private var commentLogArray = [""]
    private var phoneSubscriber: AnyCancellable?
    private var addressSubscriber: AnyCancellable?
    private var activeOrderSubscriber: AnyCancellable?
    private let scrollable = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    private let container = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    private let orderNumber = {
        let label = UILabel()
        label.text = "Orden #00"
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        return label
    }()
    private let status = {
        let label = UILabel()
        label.text = "Estado de la orden: Enviada"
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.backgroundColor = .systemGray6
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.isHidden = true
        return label
    }()
    private lazy var numberOfBottles = {
        let pickerButton = UIButton(type: .system)
        pickerButton.translatesAutoresizingMaskIntoConstraints = false
        pickerButton.tintColor = .white
        pickerButton.backgroundColor = .systemBlue
        pickerButton.setTitle("   Número de Garrafones: 1", for: .normal)
        pickerButton.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        pickerButton.layer.cornerRadius = 10
        pickerButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        pickerButton.widthAnchor.constraint(equalToConstant: 340).isActive = true
        pickerButton.addTarget(self, action: #selector(numberOfBottlesPopUpAction), for: .touchUpInside)
        return pickerButton
    }()
    private let totalAmount = {
        let label = UILabel()
        label.text = "Total: $\(bottlePrice)"
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        return label
    }()
    private lazy var payment = {
        let pickerButton = UIButton(type: .system)
        pickerButton.translatesAutoresizingMaskIntoConstraints = false
        pickerButton.tintColor = .white
        pickerButton.backgroundColor = .systemBlue
        pickerButton.setTitle("   Tipo de Pago: Efectivo", for: .normal)
        pickerButton.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        pickerButton.layer.cornerRadius = 10
        pickerButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        pickerButton.widthAnchor.constraint(equalToConstant: 340).isActive = true
        pickerButton.addTarget(self, action: #selector(paymentPopUpAction), for: .touchUpInside)
        return pickerButton
    }()
    private let paymentStatus = {
        let label = UILabel()
        label.text = "Pendiente de pago"
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.backgroundColor = .systemGray6
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        label.isHidden = true
        return label
    }()
    private let paymentInfo = {
        let label = UILabel()
        label.text = "Beneficiario: \(accountHolder)\nBanco: \(bank)\nCLABE: \(clabe)"
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        label.numberOfLines = 3
        label.isHidden = true
        return label
    }()
    private let commentLog = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.isHidden = true
        label.backgroundColor = .systemGray6
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 5
        return label
    }()
    private lazy var comments = {
        let text = UITextField()
        text.placeholder = "Agrega algún comentario sobre tu pedido..."
        text.font = .systemFont(ofSize: 17)
        text.backgroundColor = .systemGray6
        text.textAlignment = .left
        text.layer.cornerRadius = 10
        text.heightAnchor.constraint(equalToConstant: 60).isActive = true
        text.widthAnchor.constraint(equalToConstant: 340).isActive = true
        text.inputAccessoryView = keyboardToolBar
        return text
    }()
    private lazy var sendComment = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Enviar comentario", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.isHidden = true
        button.addTarget(self, action: #selector(sendCommentAction), for: .touchUpInside)
        return button
    }()
    private let phone = {
        let label = UILabel()
        label.text = "Teléfono de Contacto: "
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        return label
    }()
    private let address = {
        let label = UILabel()
        label.text = "Dirección de entrega: "
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private lazy var placeOrder = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.setTitle("Ordenar", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.addTarget(self, action: #selector(placeOrderAction), for: .touchUpInside)
        return button
    }()
    private lazy var cancelOrder = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = .systemRed
        button.setTitle("Cancelar", for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.widthAnchor.constraint(equalToConstant: 340).isActive = true
        button.isHidden = true
        button.addTarget(self, action: #selector(cancelOrderAction), for: .touchUpInside)
        return button
    }()
    private lazy var mainUIStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [orderNumber, status, numberOfBottles, totalAmount, payment, paymentStatus, paymentInfo, comments, sendComment, commentLog, phone, address, placeOrder, cancelOrder])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 15
        return stack
    }()
    private let busy = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.backgroundColor = UIColor(white: 1, alpha: 0.5)
        activityIndicator.layer.cornerRadius = 5
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
    private lazy var keyboardToolBar = {
        let toolBar = UIToolbar()
        let doneButton = UIBarButtonItem(title: "Listo", style: .plain, target: self, action: #selector(hideKeyboard))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.items = [flexSpace, flexSpace, doneButton]
        toolBar.sizeToFit()
        return toolBar
    }()
    private lazy var scrollableHeightConstraint = scrollable.frameLayoutGuide.heightAnchor.constraint(equalToConstant: UIScreen.main.fixedCoordinateSpace.bounds.size.height)
    
    func setup() {
        viewController.view.backgroundColor = .systemBackground
        viewController.view.addSubview(scrollable)
        scrollable.addSubview(container)
        container.addSubview(mainUIStack)
        container.addSubview(busy)
        NSLayoutConstraint.activate([
            scrollable.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
            scrollable.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor),
            scrollable.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor),
            scrollable.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            scrollableHeightConstraint,
            container.topAnchor.constraint(equalTo: scrollable.contentLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: scrollable.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollable.contentLayoutGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scrollable.contentLayoutGuide.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scrollable.frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(equalTo: scrollable.frameLayoutGuide.heightAnchor),
            mainUIStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            mainUIStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
            busy.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            busy.centerXAnchor.constraint(equalTo: container.centerXAnchor)])
    }
    
    func fetchData() {
        viewModel.fetchActiveOrder(userEmail: currentUserEmail) { [weak self] result in
            switch result {
            case .success(let order):
                self?.busy.startAnimating()
                self?.orderNumber.text = "Orden #\(order.orderNumber)"
                switch order.status {
                case 1: self?.status.text = "Estado de la orden: Enviada"; self?.cancelOrder.isEnabled = true
                case 2: self?.status.text = "Estado de la orden: Despachada"; self?.cancelOrder.isEnabled = false
                case 3: self?.status.text = "Estado de la orden: En ruta"; self?.cancelOrder.isEnabled = false
                default: break
                }
                self?.numberOfBottles.setTitle("   Número de Garrafones: \(order.numberOfBottles)", for: .normal)
                self?.totalAmount.text = "Total: $\(order.totalAmount)"
                self?.selectedPayment = order.payment - 1
                switch order.payment {
                case 1: self?.payment.setTitle("   Tipo de Pago: Efectivo", for: .normal)
                case 2: self?.payment.setTitle("   Tipo de Pago: Transferencia", for: .normal); self?.paymentInfo.isHidden = false
                default: break
                }
                switch order.paymentStatus {
                case 1: self?.paymentStatus.text = "Pendiente de pago"
                case 2: self?.paymentStatus.text = "Pagado"; self?.payment.isEnabled = false
                default: break
                }
                self?.commentLogArray = order.comments
                guard let localCommentLogArray = self?.commentLogArray else { return }
                self?.commentLog.text = localCommentLogArray.first
                if localCommentLogArray.count > 1 {
                    for i in stride(from: 1, to: localCommentLogArray.count, by: 1) {
                        self?.commentLog.text = "\(self?.commentLog.text ?? "")\n----------\n\(localCommentLogArray[i])"
                    }
                    self?.scrollableHeightConstraint.constant = UIScreen.main.fixedCoordinateSpace.bounds.size.height + (self?.commentLog.intrinsicContentSize.height ?? 0)
                }
                self?.phone.text = "Teléfono de Contacto: \(order.phone)"
                self?.address.text = "Dirección de entrega: \(order.address)"
                self?.status.isHidden = false
                self?.numberOfBottles.isEnabled = false
                self?.paymentStatus.isHidden = false
                self?.sendComment.isHidden = false
                self?.commentLog.isHidden = false
                self?.placeOrder.isHidden = true
                self?.cancelOrder.isHidden = false
                self?.subscribeToActiveOrder()
                self?.busy.stopAnimating()
            case .failure(_):
                guard let currentUserEmail = self?.currentUserEmail else { return }
                self?.viewModel.currentOrderNumber(userEmail: currentUserEmail) { [weak self] result in
                    switch result {
                    case .success(let currentOrderNumber):
                        self?.orderNumber.text = "Orden #\(currentOrderNumber)"
                        self?.orderNumberInt = currentOrderNumber
                    case .failure(let error):
                        print(error)
                        self?.orderNumber.text = "Orden #1"
                        self?.orderNumberInt = 1
                    }
                }
                self?.viewModel.fetchUser(userEmail: currentUserEmail, completion: { [weak self] result in
                    switch result {
                    case .success(_):
                        self?.phoneSubscriber = self?.viewModel.$userPhone.sink(receiveValue: { phone in
                            self?.phone.text = "Teléfono de Contacto: \(phone)"
                        })
                        self?.addressSubscriber = self?.viewModel.$userAddress.sink(receiveValue: { address in
                            self?.address.text = "Dirección de entrega: \(address)"
                        })
                    case .failure(let error):
                        print(error)
                    }
                })
            }
        }
    }
    
    @objc private func hideKeyboard() {
        viewController.view.endEditing(true)
    }
    
    @objc private func placeOrderAction() {
        placeOrder.isEnabled = false
        busy.startAnimating()
        let comment = comments.text ?? ""
        commentLogArray[0] = comment
        comments.text = ""
        let totalAmount = Double(selectedNumberOfBottles + 1) * bottlePrice
        let newOrder = Order(id: UUID(), orderNumber: orderNumberInt, userEmail: currentUserEmail, status: 1, numberOfBottles: selectedNumberOfBottles + 1, totalAmount: totalAmount, payment: selectedPayment + 1, paymentStatus: 1, comments: commentLogArray, phone: viewModel.userPhone, address: viewModel.userAddress)
        viewModel.placeOrder(newOrder) { [weak self] result in
            switch result {
            case .success(_):
                self?.viewModel.removeUserListener()
                self?.phoneSubscriber?.cancel()
                self?.addressSubscriber?.cancel()
                self?.status.isHidden = false
                self?.numberOfBottles.isEnabled = false
                self?.paymentStatus.isHidden = false
                self?.sendComment.isHidden = false
                self?.commentLog.isHidden = false
                self?.placeOrder.isHidden = true
                self?.cancelOrder.isHidden = false
                self?.subscribeToActiveOrder()
                self?.busy.stopAnimating()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    @objc private func sendCommentAction() {
        guard let newComment = comments.text else { return }
        guard !newComment.isEmpty else { return }
        if commentLogArray[0].isEmpty {
            commentLogArray[0] = newComment
        } else {
            commentLogArray.append(newComment)
        }
        comments.text = ""
        viewModel.updateActiveOrder(atField: .comments, with: commentLogArray)
    }
    
    @objc private func cancelOrderAction() {
        let alert = UIAlertController(title: "Cancelar Orden", message: "¿Está seguro que desea cancelar la orden actual?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "NO", style: .cancel))
        alert.addAction(UIAlertAction(title: "SÍ", style: .destructive, handler: { [weak self] _ in
            self?.viewModel.updateActiveOrder(atField: .status, with: 99)
        }))
        viewController.present(alert, animated: true)
    }
    
    private func subscribeToActiveOrder() {
        activeOrderSubscriber = viewModel.$activeOrder.sink(receiveValue: { [weak self] order in
            guard let order else { return }
            switch order.status {
            case 1: self?.status.text = "Estado de la orden: Enviada"; self?.cancelOrder.isEnabled = true
            case 2: self?.status.text = "Estado de la orden: Despachada"; self?.cancelOrder.isEnabled = false
            case 3: self?.status.text = "Estado de la orden: En ruta"; self?.cancelOrder.isEnabled = false
            case 98: self?.status.text = "Estado de la orden: Completada"; self?.notifyOrderCompletion()
            case 99: self?.status.text = "Estado de la orden: Cancelada"; self?.delegate?.completeOrder()
            default: break
            }
            switch order.payment {
            case 1: self?.payment.setTitle("   Tipo de Pago: Efectivo", for: .normal); self?.paymentInfo.isHidden = true
            case 2: self?.payment.setTitle("   Tipo de Pago: Transferencia", for: .normal); self?.paymentInfo.isHidden = false
            default: break
            }
            switch order.paymentStatus {
            case 1: self?.paymentStatus.text = "Pendiente de pago"; self?.payment.isEnabled = true
            case 2: self?.paymentStatus.text = "Pagado"; self?.payment.isEnabled = false
            default: break
            }
            self?.commentLogArray = order.comments
            guard let localCommentLogArray = self?.commentLogArray else { return }
            self?.commentLog.text = localCommentLogArray.first
            if localCommentLogArray.count > 1 {
                for i in stride(from: 1, to: localCommentLogArray.count, by: 1) {
                    self?.commentLog.text = "\(self?.commentLog.text ?? "")\n----------\n\(localCommentLogArray[i])"
                }
                self?.scrollableHeightConstraint.constant = UIScreen.main.fixedCoordinateSpace.bounds.size.height + (self?.commentLog.intrinsicContentSize.height ?? 0)
            }
        })
    }
    
    @objc private func numberOfBottlesPopUpAction() {
        numberOfRowsInComponent = 10
        dataForRows = ["1","2","3","4","5","6","7","8","9","10"]
        let vc = UIViewController()
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(selectedNumberOfBottles, inComponent: 0, animated: false)
        vc.view.addSubview(pickerView)
        pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        pickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
        let alert = UIAlertController(title: "Selecciona número de garrafones", message: "", preferredStyle: .actionSheet)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Seleccionar", style: .default, handler: { [weak self] _ in
            self?.selectedNumberOfBottles = pickerView.selectedRow(inComponent: 0)
            guard let numberOfBottles = self?.selectedNumberOfBottles else { return }
            self?.numberOfBottles.setTitle("   Número de Garrafones: \(numberOfBottles + 1)", for: .normal)
            self?.totalAmount.text = "Total: $\(Double((numberOfBottles + 1)) * bottlePrice)"
        }))
        viewController.present(alert, animated: true)
    }
    
    @objc private func paymentPopUpAction() {
        numberOfRowsInComponent = 2
        dataForRows = ["Efectivo", "Transferencia"]
        let vc = UIViewController()
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(selectedPayment, inComponent: 0, animated: false)
        vc.view.addSubview(pickerView)
        pickerView.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        pickerView.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor).isActive = true
        let alert = UIAlertController(title: "Selecciona tipo de pago", message: "", preferredStyle: .actionSheet)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Seleccionar", style: .default, handler: { [weak self] _ in
            self?.selectedPayment = pickerView.selectedRow(inComponent: 0)
            if pickerView.selectedRow(inComponent: 0) == 0 {
                self?.payment.setTitle("   Tipo de Pago: Efectivo", for: .normal)
                self?.paymentInfo.isHidden = true
            } else {
                self?.payment.setTitle("   Tipo de Pago: Transferencia", for: .normal)
                self?.paymentInfo.isHidden = false
            }
            if let _ = self?.viewModel.activeOrder { self?.viewModel.updateActiveOrder(atField: .payment, with: pickerView.selectedRow(inComponent: 0) + 1) }
        }))
        viewController.present(alert, animated: true)
    }
    
    private func notifyOrderCompletion() {
        let alert = UIAlertController(title: "¡\(orderNumber.text ?? "Orden") Completada!", message: "Tu orden ha sido completada con éxito.\n¡Que bien! Disfruta del agua más limpia y sabrosa del mercado.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        viewController.present(alert, animated: true) { [weak self] in
            self?.delegate?.completeOrder() }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = dataForRows[row]
        label.sizeToFit()
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        60
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        numberOfRowsInComponent
    }
    
}

