//
//  HomeView.swift
//  LaHacienda
//
//  Created by Brian Jiménez Moedano on 25/07/23.
//

import Foundation
import UIKit
import Combine

class HomeView: TabViewService {
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    deinit {
        print("SE DESTRUYÓ HOME VIEW")
        viewModel.removeActiveOrderListener()
        activeOrderSubscriber?.cancel()
        viewModel.removeCurrentUserListener()
        userSubscriber?.cancel()
    }
    
    unowned var viewController: UIViewController
    private let viewModel = HomeViewModel()
    private var activeOrderSubscriber: AnyCancellable?
    private var userSubscriber: AnyCancellable?
    private let scrollable = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    private let mainContainer = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    private let saludo = HeaderUILabel()
    private let activeOrderContainer = InfoContainer()
    private let lastOrderContainer = InfoContainer()
    private let userInfoContainer = InfoContainer()
    private let laHaciendaInfoContainer = {
        let infoContainer = InfoContainer()
        infoContainer.header.text = "Contacto:"
        infoContainer.body1.text = "\ncorreo: laHacienda@gmail.com"
        infoContainer.body2.text = "teléfono: 5512345678"
        infoContainer.body3.text = "Facebook: www.facebook.com/laHacienda"
        return infoContainer
    }()
    private lazy var subContainersStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [saludo, activeOrderContainer, lastOrderContainer, userInfoContainer, laHaciendaInfoContainer])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 30
        return stack
    }()
    private lazy var scrollableHeight = scrollable.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 1200)
    private lazy var scrollableWidth = scrollable.frameLayoutGuide.widthAnchor.constraint(equalToConstant: 1600)
    
    func setup() {
        viewController.view.backgroundColor = .systemBackground
        viewController.view.addSubview(scrollable)
        scrollable.addSubview(mainContainer)
        mainContainer.addSubview(subContainersStack)
        NSLayoutConstraint.activate([
            scrollable.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
            scrollable.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor),
            scrollable.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor),
            scrollable.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
            scrollableHeight,
            scrollableWidth,
            mainContainer.topAnchor.constraint(equalTo: scrollable.contentLayoutGuide.topAnchor),
            mainContainer.leadingAnchor.constraint(equalTo: scrollable.contentLayoutGuide.leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: scrollable.contentLayoutGuide.trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: scrollable.contentLayoutGuide.bottomAnchor),
            mainContainer.widthAnchor.constraint(equalTo: scrollable.frameLayoutGuide.widthAnchor),
            mainContainer.heightAnchor.constraint(equalTo: scrollable.frameLayoutGuide.heightAnchor),
            subContainersStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor, constant: 45),
            subContainersStack.topAnchor.constraint(equalTo: mainContainer.topAnchor, constant: 30)])
    }
    
    func fetchData() {
        if userSubscriber == nil {
            userInfoContainer.busy.startAnimating()
            viewModel.fetchUser { [weak self] result in
                self?.userInfoContainer.busy.stopAnimating()
                switch result {
                case .success(_):
                    self?.subscribeToUser()
                case .failure(let error):
                    print(error)
                }
            }
        }
        if activeOrderSubscriber == nil {
            activeOrderContainer.busy.startAnimating()
            viewModel.fetchActiveOrder { [weak self] result in
                self?.activeOrderContainer.busy.stopAnimating()
                switch result {
                case .success(_):
                    self?.subscribeToActiveOrder()
                case .failure(let error):
                    print(error)
                    self?.displayMessageInContainer(self?.activeOrderContainer ?? InfoContainer(), message: "\nSin orden activa")
                }
            }
        }
        lastOrderContainer.busy.startAnimating()
        viewModel.fetchLastOrder { [weak self] result in
            self?.lastOrderContainer.busy.stopAnimating()
            switch result {
            case .success(let order):
                self?.displayOrderInContainer(self?.lastOrderContainer ?? InfoContainer(), order: order)
            case .failure(let error):
                print(error)
                self?.displayMessageInContainer(self?.lastOrderContainer ?? InfoContainer(), message: "\nSin historial")
            }
        }
    }
    
    func reArrangeSubViews() {
        scrollableHeight.constant = .zero
        scrollableWidth.constant = .zero
        switch UIDevice.current.orientation {
        case .landscapeLeft: subContainersStack.axis = .horizontal
            scrollableWidth.constant = 1600
        case .landscapeRight: subContainersStack.axis = .horizontal
            scrollableWidth.constant = 1600
        default: subContainersStack.axis = .vertical
            scrollableHeight.constant = 1200
        }
    }
    
    private func subscribeToActiveOrder() {
        activeOrderSubscriber = viewModel.$activeOrder.sink(receiveValue: { [weak self] order in
            guard let order else { return }
            if order.status >= 98 {
                self?.viewModel.removeActiveOrderListener()
                self?.activeOrderSubscriber = nil
                self?.fetchData()
            } else {
                self?.displayOrderInContainer(self?.activeOrderContainer ?? InfoContainer(), order: order)
            }
        })
    }
    
    private func displayOrderInContainer(_ container: InfoContainer, order: Order) {
        container.header.text = "Orden #\(order.orderNumber)"
        container.body1.textAlignment = .center
        container.body1.layer.cornerRadius = 10
        container.body1.clipsToBounds = true
        switch order.status {
        case 1: container.body1.text = "Enviada 📩"
            container.body1.backgroundColor = .systemGray4
        case 2: container.body1.text = "Despachada 🚰"
            container.body1.backgroundColor = .systemYellow
        case 3: container.body1.text = "En ruta 🚚"
            container.body1.backgroundColor = .systemYellow
        case 98: container.body1.text = "Completada ✅"
            container.body1.backgroundColor = .systemGreen
        case 99: container.body1.text = "Cancelada ⛔️"
            container.body1.backgroundColor = .systemRed
        default: container.body1.text = "No disponible 😶‍🌫️"
        }
        container.body2.text = "\nGarrafones pedidos: \(order.numberOfBottles)     $\(order.totalAmount)\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        switch order.payment {
        case 1: container.body3.text = "Pago: Efectivo 💵 (\(dateFormatter.string(from: order.date)))"
        case 2: container.body3.text = "Pago: Transferencia 📲 (\(dateFormatter.string(from: order.date)))"
        default: container.body3.text = "No disponible 😶‍🌫️ (\(dateFormatter.string(from: order.date)))"
        }
    }
    
    private func displayMessageInContainer(_ container: InfoContainer, message: String) {
        container.header.text = message
        container.body1.text = ""
        container.body2.text = ""
        container.body3.text = ""
    }
    
    private func subscribeToUser() {
        userSubscriber = viewModel.$currentUser.sink(receiveValue: { [weak self] user in
            guard let user else { return }
            self?.userInfoContainer.header.text = "Tus preferencias:"
            self?.userInfoContainer.body1.text = "\nTeléfono: \(user.phone)"
            self?.userInfoContainer.body2.text = "Dirección: \(user.address)"
            self?.saludo.text = "¡Hola \(user.name)!"
        })
    }
}
